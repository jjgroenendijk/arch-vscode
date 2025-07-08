#!/bin/bash

# Auto-update script for Arch Linux container
# This script updates the system packages using pacman

set -e

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] AUTO-UPDATE: $1"
}

# Function to perform system update
update_system() {
    log "Starting system update..."
    
    # Update package databases and upgrade system
    if sudo pacman -Syu --noconfirm --quiet; then
        log "System update completed successfully"
        
        # Clean package cache to save space
        sudo pacman -Scc --noconfirm --quiet
        log "Package cache cleaned"
        
        # Update AUR packages if yay is available
        if command -v yay &> /dev/null; then
            log "Updating AUR packages..."
            if yay -Syu --noconfirm --quiet; then
                log "AUR packages updated successfully"
            else
                log "Warning: AUR package update failed"
            fi
        fi
    else
        log "Error: System update failed"
        exit 1
    fi
}

# Function to check if auto-update is enabled
check_auto_update_enabled() {
    if [ "${AUTO_UPDATE:-false}" = "true" ]; then
        return 0
    else
        log "Auto-update is disabled (AUTO_UPDATE=${AUTO_UPDATE:-false})"
        return 1
    fi
}

# Main execution
main() {
    log "Auto-update script started"
    
    # Check if auto-update is enabled
    if ! check_auto_update_enabled; then
        log "Auto-update is disabled, exiting"
        exit 0
    fi
    
    # Perform system update
    update_system
    
    log "Auto-update script completed"
}

# Run main function
main "$@"