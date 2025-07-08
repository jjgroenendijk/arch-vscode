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

### Build Locally (Optional)

If you prefer to build the image yourself:

```bash
# Clone the repository
git clone https://github.com/jjgroenendijk/arch-vscode.git
cd arch-vscode

# Build the image
docker build -t arch-vscode .

# Run with your project directory mounted
docker run -it --rm -v $(pwd):/workspace -p 8080:8080 arch-vscode
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
└── server-data/        # VS Code server runtime data
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

## Building

### Local Build
```bash
# Standard build
docker build -t arch-vscode .

docker build -t arch-vscode .
```

### Development Builds
```bash
docker build -t arch-vscode .
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

## Development Notes

### Package Sources
- **Microsoft VS Code**: Direct download from official Microsoft servers
- **Dependencies**: Essential VS Code libraries (libsecret, libxkbfile, ripgrep) plus base development tools
- **Container**: Official Arch Linux image


### Future Enhancements
- CI/CD pipeline for automated builds
- Multi-registry publishing (Docker Hub + GitHub Container Registry)
- Additional development language support
- Custom VS Code extensions pre-installed

## Contributing

1. Fork the repository
2. Create your feature branch
3. Test your changes locally
4. Submit a pull request

## License

MIT License - see LICENSE file for details