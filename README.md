# Arch Linux VS Code Docker Container

Arch Linux development environment with VS Code accessible via web browser (serve-web).

## Features

- Official Arch Linux base (`archlinux:latest`)
- Microsoft VS Code direct download
- Web interface at localhost:8080
- Configurable PUID/PGID for file permissions
- AUR support via yay
- Persistent VS Code data stored under the user home directory

## Quick Start

Pull and run:
```bash
docker pull jjgroenendijk/arch-vscode:latest
docker run -it --rm -v $(pwd):/workspace -p 8080:8080 jjgroenendijk/arch-vscode:latest
```

Alternative registry: `ghcr.io/jjgroenendijk/arch-vscode:latest`

Access VS Code at http://localhost:8080 (no auth required).

## Docker Compose

Minimal `docker-compose.yml`:
```yaml
services:
  arch-vscode:
    image: ghcr.io/jjgroenendijk/arch-vscode:latest
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
    volumes:
      - ./:/workspace
      - ./config:/home/${USERNAME:-developer}/.config/arch-vscode
    ports:
      - "8080:8080"
    restart: unless-stopped
```

Commands: `docker-compose up -d` / `docker-compose down`

## Configuration

Copy `.env.example` to `.env` and customize. Key variables:

**Core:**
- `PUID=1000` - User ID
- `PGID=1000` - Group ID
- `USERNAME=developer` - Container username
- `WORKSPACE_DIR=/workspace` - Workspace path
- `VSCODE_DEFAULT_FOLDER=/workspace` - VS Code default folder

**VS Code Server:**
- `VSCODE_HOST=0.0.0.0` - Bind address
- `VSCODE_PORT=8080` - Listen port
- `VSCODE_CONNECTION_TOKEN=""` - Auth token (empty=no auth)
- `VSCODE_VERBOSE=false` - Verbose logging
- `VSCODE_LOG_LEVEL=info` - Log level (trace|debug|info|warn|error|critical|off)

**System:**
- `EXTRA_PACKAGES=""` - Space-separated packages to install
- `AUTO_UPDATE=false` - Enable auto-updates
- `TZ=UTC` - Timezone

**Directories:**
- `VSCODE_CONFIG_ROOT=$HOME/.config/arch-vscode`
- `VSCODE_USER_DATA_DIR=$VSCODE_CONFIG_ROOT/user-data`
- `VSCODE_EXTENSIONS_DIR=$VSCODE_CONFIG_ROOT/extensions`
- `VSCODE_SERVER_DATA_DIR=$VSCODE_CONFIG_ROOT/server-data`
- `VSCODE_CLI_DATA_DIR=$VSCODE_CONFIG_ROOT/cli-data`

## Usage Examples

**Custom port:**
```bash
docker run -p 3000:3000 -e VSCODE_PORT=3000 jjgroenendijk/arch-vscode:latest
```

**With authentication:**
```bash
docker run -p 8080:8080 -e VSCODE_CONNECTION_TOKEN="token" jjgroenendijk/arch-vscode:latest
# Access: http://localhost:8080/?tkn=token
```

**Localhost only:**
```bash
docker run -p 127.0.0.1:8080:8080 -e VSCODE_HOST=127.0.0.1 jjgroenendijk/arch-vscode:latest
```

**Debug logging:**
```bash
docker run -p 8080:8080 -e VSCODE_VERBOSE=true -e VSCODE_LOG_LEVEL=debug jjgroenendijk/arch-vscode:latest
```

## Persistence

### Directory Structure
```
$HOME/.config/arch-vscode/
├── user-data/      # Settings, preferences, workspace state
├── extensions/     # Installed extensions
├── server-data/    # VS Code server runtime
└── cli-data/       # CLI metadata

/home/
└── {username}/     # Shell history, configs, SSH keys, installed packages
```

Bind-mount `./config` (or a directory of your choice) to `/home/${USERNAME}/.config/arch-vscode` to persist extensions, settings, and server state across container rebuilds.

## Container Architecture

```
/
├── workspace/          # Project files (mount your directory here)
├── home/{username}/    # User home (+ VS Code data under .config/arch-vscode)
└── usr/local/bin/
    └── entrypoint.sh   # Startup script
```

Container starts as root, entrypoint switches to configured user. UID/GID mappings via PUID/PGID prevent permission issues.

## Features Detail

**SSH Agent:** Automatically started on boot. SSH_AUTH_SOCK available for git operations.

**Package Installation:** Use pacman/yay as normal. Packages persist in home volume. EXTRA_PACKAGES auto-installs on start.

**Custom Username:** Set USERNAME env var. Default is "developer". Home persists regardless of username.

## Troubleshooting

**Container exits:** Check logs `docker logs <name>`. Try `docker run -it jjgroenendijk/arch-vscode:latest /bin/bash`.

**Permission issues:** Set `PUID=$(id -u)` and `PGID=$(id -g)`.

**VS Code not accessible:** Verify port 8080 free, check logs for errors.

**SSH agent:** Verify with `echo $SSH_AUTH_SOCK` inside container.

**Packages not persisting:** Ensure home volume mounted and writable.

### Debug Commands
```bash
docker ps -a                                         # Container status
docker logs <name>                                   # View logs
docker exec -it <name> /bin/bash                     # Shell access
docker run jjgroenendijk/arch-vscode:latest code --version  # Test VS Code
```

## Build Logs

Package installation logs stored in `/var/log/`:
- `pacman-update.log` - System updates
- `pacman-install.log` - Package installs
- `pacman-cleanup.log` - Cache cleanup

## License

MIT License
