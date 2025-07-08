# Arch Linux VS Code Docker Container

A Docker container that provides an Arch Linux development environment with VS Code, accessible via web browser using VS Code's serve-web functionality.

## Features

- **Base**: Official Arch Linux (`archlinux/archlinux:latest`)
- **VS Code**: Microsoft VS Code from AUR
- **Web Access**: VS Code serve-web for direct localhost browser access
- **Multi-Platform**: Supports both AMD64 and ARM64 architectures
- **Volume Mapping**: Mount your project directory for persistent development
- **User Permissions**: Configurable PUID/PGID for proper file permissions

## Quick Start

### Build and Run Locally

```bash
# Clone the repository
git clone https://github.com/jjgroenendijk/arch-vscode.git
cd arch-vscode

# Build the image
docker build -t arch-vscode .

# Run with your project directory mounted
docker run -it --rm -v $(pwd):/workspace -p 8080:8080 arch-vscode
```

### Using Docker Compose

```bash
# Start the development environment
docker-compose up

# Run in background
docker-compose up -d

# Stop and remove
docker-compose down
```

## Configuration

### Environment Variables

- `PUID=1000` - User ID for file permissions
- `PGID=1000` - Group ID for file permissions  
- `WORKSPACE_DIR=/workspace` - Workspace directory path

### Volume Mapping

Mount your project directory to `/workspace` in the container:

```bash
docker run -v /path/to/your/project:/workspace arch-vscode
```

## Available Images

### Local Development
- `arch-vscode` - Full development environment with build tools

### Published Images (Coming Soon)
- `jjgroenendijk/arch-vscode:latest` - Latest stable release
- `ghcr.io/jjgroenendijk/arch-vscode:latest` - GitHub Container Registry

## VS Code Access

### Direct Browser Access
```bash
# Run with port mapping
docker run -p 8080:8080 arch-vscode

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

### Multi-Platform Support
- **AMD64**: Intel/AMD processors
- **ARM64**: Apple Silicon, ARM servers
- Built using Docker Buildx with QEMU emulation

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

# Multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 -t arch-vscode .
```

### Development Builds
```bash
# Standard build (only variant currently available)
docker build -t arch-vscode .
```

## Troubleshooting

### Common Issues

**Container exits immediately**:
- Check container logs: `docker logs <container-name>`
- Verify tunnel authentication
- Try interactive mode: `docker run -it arch-vscode /bin/bash`

**Permission issues**:
- Set correct PUID/PGID: `docker run -e PUID=$(id -u) -e PGID=$(id -g) arch-vscode`
- Check volume mount permissions

**VS Code web interface not accessible**:
- Ensure port 8080 is not blocked
- Check container logs for errors: `docker logs <container-name>`
- Verify VS Code is running: `docker run arch-vscode code --version`

**Platform warnings**:
- Use `--platform` flag: `docker run --platform linux/amd64 arch-vscode`
- Or build for your platform: `docker buildx build --platform linux/$(arch)`

### Debug Commands

```bash
# Check container status
docker ps -a

# View container logs
docker logs <container-name>

# Access container shell
docker exec -it <container-name> /bin/bash

# Test VS Code installation
docker run arch-vscode code --version

# Check available packages
docker run arch-vscode pacman -Q | grep code
```

## Development Notes

### Package Sources
- **Microsoft VS Code**: AUR package (`visual-studio-code-bin`)
- **Dependencies**: Base development tools, Git, build essentials
- **Container**: Official Arch Linux image

### Known Limitations
- Microsoft VS Code installed from AUR (not official Microsoft build)
- ARM64 images run via emulation on x86_64 hosts

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