#!/bin/bash

# Entrypoint script for Arch Linux VS Code container
set -e

# Set default values
PUID=${PUID:-1000}
PGID=${PGID:-1000}
WORKSPACE_DIR=${WORKSPACE_DIR:-/workspace}
EXTRA_PACKAGES=${EXTRA_PACKAGES:-""}
AUTO_UPDATE=${AUTO_UPDATE:-false}

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to setup user permissions
setup_user() {
    log "Setting up user permissions..."
    
    # Get current user info
    CURRENT_UID=$(id -u developer 2>/dev/null || echo "1000")
    CURRENT_GID=$(id -g developer 2>/dev/null || echo "1000")
    
    # If PUID/PGID are different from current, we need to adjust
    if [ "$PUID" != "$CURRENT_UID" ] || [ "$PGID" != "$CURRENT_GID" ]; then
        log "Adjusting user permissions: PUID=$PUID, PGID=$PGID"
        
        # Create group if it doesn't exist
        if ! getent group "$PGID" >/dev/null 2>&1; then
            groupadd -g "$PGID" devgroup || log "Warning: Could not create group with GID $PGID"
        fi
        
        # Modify user
        usermod -u "$PUID" -g "$PGID" developer || log "Warning: Could not modify user developer"
        
        # Fix ownership of home directory and directories
        chown -R "$PUID:$PGID" /home/developer /workspace /config 2>/dev/null || log "Warning: Could not change ownership of some directories"
    else
        # Ensure correct ownership even if UIDs match
        chown -R "$PUID:$PGID" /workspace /config 2>/dev/null || log "Warning: Could not change ownership of some directories"
    fi
    
    log "User permissions configured successfully"
}

# Function to install extra packages
install_extra_packages() {
    if [ -n "$EXTRA_PACKAGES" ]; then
        log "Installing extra packages: $EXTRA_PACKAGES"
        
        # Split packages by space and install each one
        for package in $EXTRA_PACKAGES; do
            log "Installing package: $package"
            if ! sudo pacman -S --noconfirm "$package" 2>/dev/null; then
                # Try with yay if pacman fails
                if command -v yay >/dev/null 2>&1; then
                    if ! yay -S --noconfirm "$package"; then
                        log "Warning: Failed to install package: $package"
                    fi
                else
                    log "Warning: Failed to install package: $package (yay not available)"
                fi
            fi
        done
        
        log "Extra packages installation completed"
    else
        log "No extra packages to install"
    fi
}

# Function to setup auto-update
setup_auto_update() {
    log "Configuring auto-update..."
    
    if [ "$AUTO_UPDATE" = "true" ]; then
        log "Auto-update is enabled, setting up cron job..."
        
        # Start cron daemon (works better in containers than systemd service)
        if ! pgrep -x "crond" > /dev/null; then
            log "Starting cron daemon..."
            sudo /usr/bin/crond 2>/dev/null || log "Warning: Could not start cron daemon"
        fi
        
        # Create cron job to run auto-update every 24 hours at 2 AM
        echo "0 2 * * * /usr/local/bin/auto-update.sh >> /var/log/auto-update.log 2>&1" | sudo crontab -u developer -
        
        log "Auto-update cron job configured (runs daily at 2 AM)"
    else
        log "Auto-update is disabled"
    fi
}

# Function to start VS Code serve-web
start_vscode() {
    log "Starting VS Code serve-web..."
    
    # Change to workspace directory
    cd "$WORKSPACE_DIR"
    
    # Check if VS Code binary exists and is executable
    if [ ! -x "/opt/vscode/bin/code" ]; then
        log "ERROR: VS Code binary not found or not executable at /opt/vscode/bin/code"
        exit 1
    fi
    
    # Check if port 8080 is available
    if netstat -ln 2>/dev/null | grep -q ":8080 "; then
        log "WARNING: Port 8080 appears to be in use"
    fi
    
    log "Current user: $(whoami), UID: $(id -u), GID: $(id -g)"
    log "Current directory: $(pwd)"
    log "VS Code binary: $(which code || echo 'not found in PATH')"
    
    # Start VS Code serve-web with custom data directories
    log "Executing: code serve-web --host 0.0.0.0 --port 8080 --without-connection-token --server-data-dir /config/server-data"
    exec code serve-web \
        --host 0.0.0.0 \
        --port 8080 \
        --without-connection-token \
        --server-data-dir /config/server-data
}

# Function to handle shutdown
shutdown() {
    log "Shutting down VS Code..."
    # Kill any remaining processes
    pkill -f "code" || true
    exit 0
}

# Set up signal handlers
trap shutdown SIGTERM SIGINT

# Main execution
main() {
    log "Starting Arch Linux VS Code container..."
    
    # Check if running as root (for initial setup)
    if [ "$(id -u)" -eq 0 ]; then
        log "Running initial setup as root..."
        setup_user
        
        # Switch to developer user and re-run script
        log "Switching to developer user..."
        exec sudo -u developer -E -H /usr/local/bin/entrypoint.sh "$@"
    fi
    
    # Now running as developer user
    log "Running as user: $(whoami) (UID: $(id -u), GID: $(id -g))"
    log "Working directory: $(pwd)"
    log "Workspace directory: $WORKSPACE_DIR"
    log "Home directory: $HOME"
    
    # Ensure we're in the right directory
    cd "$WORKSPACE_DIR" || {
        log "Warning: Could not change to workspace directory $WORKSPACE_DIR, using current directory"
    }
    
    # Install extra packages if specified
    install_extra_packages
    
    # Setup auto-update if enabled
    setup_auto_update
    
    # Start VS Code
    start_vscode
}

# Run main function
main "$@"