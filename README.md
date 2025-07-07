# Arch Linux VS Code Docker Container

A Docker container that provides an Arch Linux development environment with VS Code, accessible via web browser using the official VS Code tunnel functionality.

## Features

- **Base**: Official Arch Linux (`archlinux/archlinux:latest`)
- **VS Code**: Code OSS from official Arch repositories
- **Web Access**: VS Code tunnel for browser-based development
- **Multi-Platform**: Supports both AMD64 and ARM64 architectures
- **Volume Mapping**: Mount your project directory for persistent development
- **User Permissions**: Configurable PUID/PGID for proper file permissions

## Quick Start

### Build and Run Locally

```bash
# Clone the repository
git clone <repository-url>
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
- `VSCODE_TUNNEL_NAME=arch-vscode-tunnel` - Custom tunnel name
- `WORKSPACE_DIR=/workspace` - Workspace directory path

### Volume Mapping

Mount your project directory to `/workspace` in the container:

```bash
docker run -v /path/to/your/project:/workspace arch-vscode
```

## Available Images

### Local Development
- `arch-vscode` - Full development environment with build tools
- `arch-vscode-simple` - Minimal VS Code environment  
- `arch-vscode-debug` - Debug version for testing

### Published Images (Coming Soon)
- `username/arch-vscode:latest` - Latest stable release
- `ghcr.io/username/arch-vscode:latest` - GitHub Container Registry

## VS Code Access

### Method 1: VS Code Tunnel (Recommended)
1. Start the container
2. Check container logs for tunnel URL: `docker logs <container-name>`
3. Follow authentication prompts
4. Access VS Code via the provided tunnel URL

### Method 2: Local Port Forwarding
```bash
# Run with port mapping
docker run -p 8080:8080 arch-vscode

# Access at http://localhost:8080 (if tunnel supports local access)
```

## Development Workflow

1. **Start Container**:
   ```bash
   docker-compose up -d
   ```

2. **Access VS Code**:
   - Check logs for tunnel URL
   - Authenticate with Microsoft/GitHub account
   - Open in browser

3. **Mount Project**:
   ```bash
   # Your project files are available at /workspace
   cd /workspace
   ```

4. **Install Extensions**:
   - Use VS Code extension marketplace
   - Extensions are persisted in volume

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
# Simple version (minimal packages)
docker build -f Dockerfile.simple -t arch-vscode-simple .

# Debug version (for testing)
docker build -f Dockerfile.debug -t arch-vscode-debug .
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

**VS Code tunnel not working**:
- Ensure internet connectivity
- Check Microsoft/GitHub account authentication
- Verify tunnel binary exists: `docker run arch-vscode code --version`

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
- **Code OSS**: Official Arch Linux repositories (`pacman -S code`)
- **Dependencies**: Base development tools, Git, build essentials
- **Container**: Official Arch Linux image

### Known Limitations
- Code OSS may have limited tunnel functionality compared to Microsoft VS Code
- Some proprietary Microsoft features may not be available
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