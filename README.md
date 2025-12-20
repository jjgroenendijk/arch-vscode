# Arch Linux VS Code Docker Container

Arch Linux development environment with VS Code accessible via web browser (serve-web).

## Features

- VS Code in your browser (no desktop app needed)
- Based on Arch Linux with full package access
- Install packages automatically on startup
- All your settings and extensions persist
- AUR support via yay
- SSH agent for git operations
- Optional auto-updates
- Configurable user permissions (no file ownership issues)

## Quick Start

**Option 1: Quick test (doesn't save anything):**
```bash
docker run -it --rm -v $(pwd):/workspace -p 8080:8080 jjgroenendijk/arch-vscode:latest
```

**Option 2: With persistence (recommended):**
```bash
mkdir -p ./home
docker run -d \
  -v $(pwd):/workspace \
  -v $(pwd)/home:/home/developer \
  -p 8080:8080 \
  jjgroenendijk/arch-vscode:latest
```

Then open http://localhost:8080 in your browser.

**Alternative registry:** `ghcr.io/jjgroenendijk/arch-vscode:latest`

## Docker Compose (Recommended)

Create a `docker-compose.yml`:
```yaml
services:
  arch-vscode:
    image: ghcr.io/jjgroenendijk/arch-vscode:latest
    environment:
      - PUID=1000                    # Your user ID (run: id -u)
      - PGID=1000                    # Your group ID (run: id -g)
      - USERNAME=developer           # Username in container
      - EXTRA_PACKAGES=              # e.g., "python git vim"
      - NPM_PACKAGES=                # e.g., "typescript eslint"
    volumes:
      - ./:/workspace                # Your project files
      - ./home:/home/developer       # Persistent VS Code data
    ports:
      - "8080:8080"
    restart: unless-stopped
```

Then run:
```bash
mkdir -p ./home
docker compose up -d
```

Access VS Code at <http://localhost:8080>

To stop: `docker compose down`

## Configuration

Copy `.env.example` to `.env` and customize any values you need. Below is a complete list of all available environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| **User Settings** | | |
| `PUID` | `1000` | User ID (match your host user to avoid permission issues) |
| `PGID` | `1000` | Group ID (match your host group to avoid permission issues) |
| `USERNAME` | `developer` | Username inside the container |
| **Workspace** | | |
| `WORKSPACE_DIR` | `/workspace` | Workspace directory inside the container |
| `VSCODE_DEFAULT_FOLDER` | `/workspace` | Folder VS Code opens on startup |
| **VS Code Server** | | |
| `VSCODE_HOST` | `0.0.0.0` | Bind address (use `127.0.0.1` for localhost-only) |
| `VSCODE_PORT` | `8080` | Port VS Code listens on |
| `VSCODE_CONNECTION_TOKEN` | _(empty)_ | Authentication token (empty = no auth required) |
| `VSCODE_SOCKET_PATH` | _(empty)_ | UNIX socket path (if set, uses socket instead of TCP) |
| `VSCODE_ACCEPT_LICENSE` | `true` | Auto-accept VS Code server license |
| `VSCODE_VERBOSE` | `false` | Enable verbose logging |
| `VSCODE_LOG_LEVEL` | `info` | Log level: `trace`, `debug`, `info`, `warn`, `error`, `critical`, `off` |
| **VS Code Data Directories** | | |
| `VSCODE_CONFIG_ROOT` | `$HOME/.config/arch-vscode` | Root directory for all VS Code data |
| `VSCODE_USER_DATA_DIR` | `$VSCODE_CONFIG_ROOT/user-data` | Settings and preferences |
| `VSCODE_EXTENSIONS_DIR` | `$VSCODE_CONFIG_ROOT/extensions` | Installed extensions |
| `VSCODE_SERVER_DATA_DIR` | `$VSCODE_CONFIG_ROOT/server-data` | Server runtime data |
| `VSCODE_CLI_DATA_DIR` | `$VSCODE_CONFIG_ROOT/cli-data` | CLI metadata |
| `XDG_CONFIG_HOME` | `$HOME/.config` | XDG config directory |
| `XDG_DATA_HOME` | `$HOME/.local/share` | XDG data directory |
| **Package Installation** | | |
| `EXTRA_PACKAGES` | _(empty)_ | Space-separated Arch packages to install (e.g., `python git vim`) |
| `NPM_PACKAGES` | _(empty)_ | Space-separated npm packages to install (e.g., `typescript eslint`) |
| **System** | | |
| `AUTO_UPDATE` | `false` | Enable automatic system updates (runs daily at 2 AM) |
| `TZ` | `UTC` | Timezone (e.g., `America/New_York`, `Europe/London`) |

**Notes:**
- The package database is automatically synced before installing packages
- If `NPM_PACKAGES` is set and npm isn't installed, nodejs/npm will be installed automatically
- Packages are installed fresh on each container start (not persisted in the image)

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

## Installing Extra Packages

You can automatically install packages when the container starts:

**Arch Linux packages (via pacman/yay):**
```bash
docker run -p 8080:8080 -e EXTRA_PACKAGES="python rust go vim" jjgroenendijk/arch-vscode:latest
```

**npm packages (nodejs/npm installed automatically if needed):**
```bash
docker run -p 8080:8080 -e NPM_PACKAGES="typescript eslint prettier" jjgroenendijk/arch-vscode:latest
```

**Both together:**
```bash
docker run -p 8080:8080 \
  -e EXTRA_PACKAGES="python git" \
  -e NPM_PACKAGES="@anthropic-ai/claude-code" \
  jjgroenendijk/arch-vscode:latest
```

**In docker-compose.yml:**
```yaml
services:
  arch-vscode:
    image: ghcr.io/jjgroenendijk/arch-vscode:latest
    environment:
      - EXTRA_PACKAGES=python rust go
      - NPM_PACKAGES=typescript eslint
    volumes:
      - ./:/workspace
      - ./home:/home/developer
    ports:
      - "8080:8080"
```

**Important:** Packages are installed fresh each time the container starts. For permanent packages, build your own image that extends this one.

## How to Use

1. **Start the container:**
   ```bash
   docker compose up -d
   ```

2. **Open VS Code in your browser:**
   - Go to <http://localhost:8080>
   - No password needed (unless you set `VSCODE_CONNECTION_TOKEN`)

3. **Your files are available:**
   - Whatever you mounted to `/workspace` is accessible in VS Code
   - Install extensions from the VS Code marketplace
   - Everything persists in the `./home` directory

## Where Your Data is Stored

When you mount `./home` to `/home/developer` (or your custom username), everything persists across container restarts:

```text
./home/developer/
├── .config/arch-vscode/    # VS Code settings, extensions, and data
├── .bashrc                 # Shell configuration
├── .ssh/                   # SSH keys
└── ...                     # Anything else you create
```

Your project files go in `/workspace` (mount your project directory there).

## Additional Features

**SSH Agent:** Automatically started for git operations with SSH keys.

**File Permissions:** Set `PUID` and `PGID` to match your host user ID to avoid permission problems with mounted files.

**Auto-Updates:** Set `AUTO_UPDATE=true` to enable daily system updates (runs at 2 AM).

**Sudo Access:** The container user has full sudo privileges (no password required).

**Package Database:** Automatically synced before installing packages, even if the Docker image is outdated.

## Troubleshooting

**View auto-update logs** (when `AUTO_UPDATE=true`):
```bash
docker exec -it <container-name> cat /var/log/auto-update.log
```

**Check VS Code server status:**
```bash
docker logs <container-name>
```

**Permission issues with files:**
- Make sure `PUID` and `PGID` match your host user (`id -u` and `id -g`)
- The home directory should be owned by your user

## License

MIT License
