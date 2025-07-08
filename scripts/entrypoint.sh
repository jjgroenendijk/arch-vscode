#!/bin/bash

# Entrypoint script for Arch Linux VS Code container
set -e

# Set default values
PUID=${PUID:-1000}
PGID=${PGID:-1000}
WORKSPACE_DIR=${WORKSPACE_DIR:-/workspace}
VSCODE_USER_DATA_DIR=${VSCODE_USER_DATA_DIR:-/config/user-data}
VSCODE_EXTENSIONS_DIR=${VSCODE_EXTENSIONS_DIR:-/config/extensions}
VSCODE_SERVER_DATA_DIR=${VSCODE_SERVER_DATA_DIR:-/config/server-data}
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
    CURRENT_UID=$(id -u developer)
    CURRENT_GID=$(id -g developer)
    
    # If PUID/PGID are different from current, we need to adjust
    if [ "$PUID" != "$CURRENT_UID" ] || [ "$PGID" != "$CURRENT_GID" ]; then
        log "Adjusting user permissions: PUID=$PUID, PGID=$PGID"
        
        # Create group if it doesn't exist
        if ! getent group "$PGID" >/dev/null; then
            sudo groupadd -g "$PGID" devgroup
        fi
        
        # Modify user
        sudo usermod -u "$PUID" -g "$PGID" developer
        
        # Fix ownership of home directory
        sudo chown -R "$PUID:$PGID" /home/developer
    fi
    
    # Ensure workspace directory exists and has correct permissions
    if [ ! -d "$WORKSPACE_DIR" ]; then
        sudo mkdir -p "$WORKSPACE_DIR"
    fi
    sudo chown -R "$PUID:$PGID" "$WORKSPACE_DIR"
    
    # Ensure config directory exists and has correct permissions
    if [ ! -d "/config" ]; then
        sudo mkdir -p "/config"
    fi
    sudo chown -R "$PUID:$PGID" "/config"
    
    log "User permissions configured successfully"
}

# Function to install extra packages
install_extra_packages() {
    if [ -n "$EXTRA_PACKAGES" ]; then
        log "Installing extra packages: $EXTRA_PACKAGES"
        
        # Split packages by space and install each one
        for package in $EXTRA_PACKAGES; do
            log "Installing package: $package"
            if ! yay -S --noconfirm "$package"; then
                log "Warning: Failed to install package: $package"
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
        
        # Start cron daemon
        sudo service cronie start
        
        # Create cron job to run auto-update every 24 hours at 2 AM
        echo "0 2 * * * /usr/local/bin/auto-update.sh >> /var/log/auto-update.log 2>&1" | sudo crontab -u developer -
        
        log "Auto-update cron job configured (runs daily at 2 AM)"
    else
        log "Auto-update is disabled"
    fi
}

# Function to initialize VS Code
init_vscode() {
    log "Initializing VS Code..."
    
    # Create VS Code directories in /config
    mkdir -p "$VSCODE_USER_DATA_DIR"
    mkdir -p "$VSCODE_EXTENSIONS_DIR"
    mkdir -p "$VSCODE_SERVER_DATA_DIR"
    
    log "VS Code directories created:"
    log "  User data: $VSCODE_USER_DATA_DIR"
    log "  Extensions: $VSCODE_EXTENSIONS_DIR"
    log "  Server data: $VSCODE_SERVER_DATA_DIR"
    log "VS Code initialized successfully"
}

# Function to start VS Code serve-web
start_vscode() {
    log "Starting VS Code serve-web..."
    
    # Change to workspace directory
    cd "$WORKSPACE_DIR"
    
    # Execute the passed command or start serve-web
    exec "$@"
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
        exec sudo -u developer -E "$0" "$@"
    fi
    
    # Now running as developer user
    log "Running as user: $(whoami)"
    log "Working directory: $(pwd)"
    log "Workspace directory: $WORKSPACE_DIR"
    
    # Install extra packages if specified
    install_extra_packages
    
    # Setup auto-update if enabled
    setup_auto_update
    
    # Initialize VS Code
    init_vscode
    
    # Execute passed command
    log "Executing command: $*"
    start_vscode "$@"
}

# Run main function
main "$@"