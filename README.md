# Arch Linux VS Code Docker Container

A Docker container that provides an Arch Linux development environment with VS Code, accessible via web browser using VS Code's serve-web functionality.

## Features

- **Base**: Official Arch Linux (`archlinux/archlinux:latest`)
- **VS Code**: Microsoft VS Code direct download from official servers
- **Web Access**: VS Code serve-web for direct localhost browser access
- **Platform**: AMD64 architecture only
- **Volume Mapping**: Mount your project directory for persistent development
- **User Permissions**: Configurable PUID/PGID for proper file permissions

## Quick Start

### Using Pre-built Images (Recommended)

```bash
# Pull from Docker Hub
docker pull jjgroenendijk/arch-vscode:latest

# Or pull from GitHub Container Registry
docker pull ghcr.io/jjgroenendijk/arch-vscode:latest

# Run with your project directory mounted
docker run -it --rm -v $(pwd):/workspace -p 8080:8080 jjgroenendijk/arch-vscode:latest
```

### Using Docker Compose

Create a `docker-compose.yml` file in your project directory:

```yaml
services:
  arch-vscode:
    image: ghcr.io/jjgroenendijk/arch-vscode:latest
    container_name: arch-vscode-dev
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - WORKSPACE_DIR=/workspace
      - VSCODE_USER_DATA_DIR=/config/user-data
      - VSCODE_EXTENSIONS_DIR=/config/extensions
      - VSCODE_SERVER_DATA_DIR=/config/server-data
      - VSCODE_HOST=0.0.0.0
      - VSCODE_PORT=8080
      - VSCODE_CONNECTION_TOKEN=""
      - VSCODE_ACCEPT_LICENSE=true
      - AUTO_UPDATE=${AUTO_UPDATE:-false}
      - TZ=${TZ:-UTC}
    volumes:
      - ./:/workspace
      - vscode-config:/config
    ports:
      - "8080:8080"
    restart: unless-stopped
    stdin_open: true
    tty: true
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/", "||", "exit", "1"]
      interval: 30s
      timeout: 10s
      start_period: 60s
      retries: 3

volumes:
  vscode-config:
    driver: local

```

Then run:

```bash
# Run in background
docker-compose up -d

# Stop and remove
docker-compose down
```


## Configuration

### Environment Variables

#### Core Configuration
- `PUID=1000` - User ID for file permissions
- `PGID=1000` - Group ID for file permissions  
- `WORKSPACE_DIR=/workspace` - Workspace directory path

#### VS Code Configuration
- `VSCODE_USER_DATA_DIR=/config/user-data` - VS Code user data directory
- `VSCODE_EXTENSIONS_DIR=/config/extensions` - VS Code extensions directory
- `VSCODE_SERVER_DATA_DIR=/config/server-data` - VS Code server data directory

#### VS Code Server Configuration
- `VSCODE_HOST=0.0.0.0` - Host to listen on for VS Code web interface
- `VSCODE_PORT=8080` - Port to listen on for VS Code web interface
- `VSCODE_CONNECTION_TOKEN=""` - Connection token for authentication (empty = no auth)
- `VSCODE_SOCKET_PATH=""` - Socket path for VS Code server (empty = use host/port)
- `VSCODE_ACCEPT_LICENSE=true` - Automatically accept VS Code server license terms
- `VSCODE_CLI_DATA_DIR=/config/cli-data` - VS Code CLI data directory
- `VSCODE_VERBOSE=false` - Enable verbose logging for VS Code server
- `VSCODE_LOG_LEVEL=info` - Log level (trace, debug, info, warn, error, critical, off)

#### System Configuration
- `EXTRA_PACKAGES=""` - Additional packages to install via yay (space-separated)
- `AUTO_UPDATE=false` - Enable automatic system updates every 24 hours
- `TZ=UTC` - Timezone setting

#### SSL/TLS Configuration
- `SSL_CERT_DIR=/etc/ssl/certs` - SSL certificates directory
- `SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt` - SSL certificate file
- `CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt` - Curl CA bundle path

#### XDG Configuration
- `XDG_CONFIG_HOME=/config` - XDG config directory
- `XDG_DATA_HOME=/config` - XDG data directory

### Volume Mapping

Mount your project directory to `/workspace` in the container:

```bash
docker run -v /path/to/your/project:/workspace jjgroenendijk/arch-vscode:latest
```

## Available Images

### Pre-built Images
- `jjgroenendijk/arch-vscode:latest` - Docker Hub (latest stable release)
- `ghcr.io/jjgroenendijk/arch-vscode:latest` - GitHub Container Registry

### Local Development
- `arch-vscode` - Built locally from source

## VS Code Access

### Direct Browser Access
```bash
# Run with port mapping
docker run -p 8080:8080 jjgroenendijk/arch-vscode:latest

# Access at http://localhost:8080 (no authentication required)
```

### Custom VS Code Server Configuration

#### Using Different Port
```bash
# Run on port 3000 instead of default 8080
docker run -p 3000:3000 -e VSCODE_PORT=3000 jjgroenendijk/arch-vscode:latest
```

#### With Authentication
```bash
# Run with connection token for authentication
docker run -p 8080:8080 -e VSCODE_CONNECTION_TOKEN="mysecrettoken" jjgroenendijk/arch-vscode:latest

# Access at http://localhost:8080/?tkn=mysecrettoken
```

#### Host on Specific Interface
```bash
# Listen only on localhost (more secure)
docker run -p 127.0.0.1:8080:8080 -e VSCODE_HOST=127.0.0.1 jjgroenendijk/arch-vscode:latest
```

#### Enable Debug Logging
```bash
# Enable verbose logging and set log level to debug
docker run -p 8080:8080 -e VSCODE_VERBOSE=true -e VSCODE_LOG_LEVEL=debug jjgroenendijk/arch-vscode:latest
```

## Development Workflow

1. **Start Container**:
   ```bash
   docker-compose up -d
   ```

2. **Access VS Code**:
   - Open http://localhost:8080 in your browser
   - No authentication required

3. **Mount Project**:
   ```bash
   # Your project files are available at /workspace
   cd /workspace
   ```

4. **Install Extensions**:
   - Use VS Code extension marketplace
   - Extensions are persisted in volume

## Data Persistence

VS Code data is automatically persisted in the `/config` directory, providing complete persistence across container restarts:

### Directory Structure
```
/config/
├── user-data/          # User settings, preferences, and workspace state
├── extensions/         # Installed VS Code extensions
├── server-data/        # VS Code server runtime data
└── cli-data/           # VS Code CLI metadata and configuration
```

### What's Persisted
- **Extensions**: All installed extensions remain after container restart
- **User Settings**: Preferences, themes, and configurations
- **Workspace State**: Recently opened files and workspace-specific settings
- **Extension Data**: Extension-specific storage and state

### Volume Configuration
The current `docker-compose.yml` automatically handles persistence:

```yaml
volumes:
  - vscode-config:/config    # Single volume for all VS Code data
```

### Benefits
- **Complete Persistence**: No data loss on container recreation
- **User-Independent**: Data location doesn't depend on username
- **Clean Separation**: VS Code data separate from workspace files
- **Easy Backup**: Single directory contains all persistence data

## Architecture


### Container Structure
```
/
├── workspace/          # Your project files (mounted volume)
├── home/developer/     # User home directory
│   ├── .vscode/       # VS Code settings (persistent)
│   └── .vscode-server/ # VS Code server data (persistent)
└── usr/local/bin/
    └── entrypoint.sh  # Container startup script
```


## Troubleshooting

### Common Issues

**Container exits immediately**:
- Check container logs: `docker logs <container-name>`
- Verify tunnel authentication
- Try interactive mode: `docker run -it jjgroenendijk/arch-vscode:latest /bin/bash`

**Permission issues**:
- Set correct PUID/PGID: `docker run -e PUID=$(id -u) -e PGID=$(id -g) jjgroenendijk/arch-vscode:latest`
- Check volume mount permissions

**VS Code web interface not accessible**:
- Ensure port 8080 is not blocked
- Check container logs for errors: `docker logs <container-name>`
- Verify VS Code is running: `docker run jjgroenendijk/arch-vscode:latest code --version`


### Debug Commands

```bash
# Check container status
docker ps -a

# View container logs
docker logs <container-name>

# Access container shell
docker exec -it <container-name> /bin/bash

# Test VS Code installation
docker run jjgroenendijk/arch-vscode:latest code --version

# Check available packages
docker run jjgroenendijk/arch-vscode:latest pacman -Q | grep code
```

## License

MIT License - see LICENSE file for details