#!/bin/bash

# VS Code start script with custom data directories
# Use environment variables to specify custom data directories

# Set VS Code environment variables for custom data directories
export VSCODE_EXTENSIONS_DIR="/config/extensions"
export XDG_CONFIG_HOME="/config"
export XDG_DATA_HOME="/config"

# Start VS Code serve-web
exec code serve-web \
    --host 0.0.0.0 \
    --port 8080 \
    --without-connection-token \
    --server-data-dir /config/server-data