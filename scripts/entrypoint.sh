#!/bin/bash
set -e

# Set default values
PUID=${PUID:-1000}
PGID=${PGID:-1000}
USERNAME=${USERNAME:-developer}
WORKSPACE_DIR=${WORKSPACE_DIR:-/workspace}
VSCODE_DEFAULT_FOLDER=${VSCODE_DEFAULT_FOLDER:-/workspace}
EXTRA_PACKAGES=${EXTRA_PACKAGES:-""}
AUTO_UPDATE=${AUTO_UPDATE:-false}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

setup_user() {
    log "Setting up user permissions..."
    EXISTING_USER=$(getent passwd "$PUID" | cut -d: -f1)

    if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "$USERNAME" ]; then
        log "Renaming user '$EXISTING_USER' to '$USERNAME'"
        usermod -l "$USERNAME" "$EXISTING_USER"
        getent group "$EXISTING_USER" >/dev/null 2>&1 && groupmod -n "$USERNAME" "$EXISTING_USER"
        usermod -d "/home/$USERNAME" -m "$USERNAME" 2>/dev/null || true
        usermod -aG wheel "$USERNAME" 2>/dev/null || true
        grep -q "^$USERNAME ALL=(ALL) NOPASSWD: ALL" /etc/sudoers 2>/dev/null || \
            echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    elif ! id -u "$USERNAME" >/dev/null 2>&1; then
        log "Creating user: $USERNAME"
        getent group "$PGID" >/dev/null 2>&1 || groupadd -g "$PGID" "$USERNAME"
        useradd -m -s /bin/bash -u "$PUID" -g "$PGID" -G wheel "$USERNAME"
        echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    else
        CURRENT_UID=$(id -u "$USERNAME")
        CURRENT_GID=$(id -g "$USERNAME")
        if [ "$PUID" != "$CURRENT_UID" ] || [ "$PGID" != "$CURRENT_GID" ]; then
            log "Adjusting UID/GID to $PUID:$PGID"
            getent group "$PGID" >/dev/null 2>&1 || groupadd -g "$PGID" "${USERNAME}_group"
            usermod -u "$PUID" -g "$PGID" "$USERNAME"
        fi
    fi

    chown -R "$PUID:$PGID" "/home/$USERNAME" /workspace /config 2>/dev/null || true
}

install_extra_packages() {
    [ -z "$EXTRA_PACKAGES" ] && return
    log "Installing packages: $EXTRA_PACKAGES"
    for pkg in $EXTRA_PACKAGES; do
        sudo pacman -S --noconfirm "$pkg" 2>/dev/null || \
            yay -S --noconfirm "$pkg" 2>/dev/null || \
            log "Warning: Failed to install $pkg"
    done
}

setup_auto_update() {
    [ "$AUTO_UPDATE" != "true" ] && return
    log "Enabling auto-update..."
    pgrep -x "crond" >/dev/null || sudo /usr/bin/crond 2>/dev/null
    echo "0 2 * * * /usr/local/bin/auto-update.sh >> /var/log/auto-update.log 2>&1" | sudo crontab -u "$USERNAME" -
}

setup_ssh_agent() {
    [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ] && return
    eval "$(ssh-agent -s)" >/dev/null && log "SSH agent started"
}

setup_vscode_config() {
    mkdir -p "$VSCODE_USER_DATA_DIR"
    cat > "$VSCODE_USER_DATA_DIR/argv.json" << 'EOF'
{
    "password-store": "basic",
    "enable-crash-reporter": false
}
EOF
}

start_vscode() {
    log "Starting VS Code..."
    setup_vscode_config

    export VSCODE_CLI_DATA_DIR="${VSCODE_CLI_DATA_DIR:-/config/cli-data}"
    export VSCODE_EXTENSIONS="${VSCODE_EXTENSIONS_DIR:-/config/extensions}"

    cd "$VSCODE_DEFAULT_FOLDER"

    VSCODE_ARGS="serve-web --host ${VSCODE_HOST:-0.0.0.0} --port ${VSCODE_PORT:-8080}"
    [ -n "$VSCODE_CONNECTION_TOKEN" ] && VSCODE_ARGS="$VSCODE_ARGS --connection-token $VSCODE_CONNECTION_TOKEN" || VSCODE_ARGS="$VSCODE_ARGS --without-connection-token"
    [ -n "$VSCODE_SOCKET_PATH" ] && VSCODE_ARGS="$VSCODE_ARGS --socket-path $VSCODE_SOCKET_PATH"
    [ "${VSCODE_ACCEPT_LICENSE:-true}" = "true" ] && VSCODE_ARGS="$VSCODE_ARGS --accept-server-license-terms"
    VSCODE_ARGS="$VSCODE_ARGS --server-data-dir ${VSCODE_SERVER_DATA_DIR:-/config/server-data}"
    [ "${VSCODE_VERBOSE:-false}" = "true" ] && VSCODE_ARGS="$VSCODE_ARGS --verbose"
    VSCODE_ARGS="$VSCODE_ARGS --log ${VSCODE_LOG_LEVEL:-info}"

    log "Executing: code $VSCODE_ARGS"
    exec code $VSCODE_ARGS
}

shutdown() {
    log "Shutting down..."
    pkill -f "code" 2>/dev/null || true
    exit 0
}

trap shutdown SIGTERM SIGINT

main() {
    log "Starting container..."

    if [ "$(id -u)" -eq 0 ]; then
        setup_user
        exec sudo -u "$USERNAME" -E -H /usr/local/bin/entrypoint.sh "$@"
    fi

    cd "$WORKSPACE_DIR" 2>/dev/null || true
    install_extra_packages
    setup_auto_update
    setup_ssh_agent
    start_vscode
}

main "$@"