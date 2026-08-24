# Arch Linux VS Code Docker Container

Arch Linux development environment running VS Code (`code serve-web`) in the browser.

## Quick Start

```bash
mkdir -p ./home
docker run -d \
  -v $(pwd):/workspace \
  -v $(pwd)/home:/home/developer \
  -p 8080:8080 \
  ghcr.io/jjgroenendijk/arch-vscode:latest
```

Open <http://localhost:8080>.

## Docker Compose

```yaml
services:
  arch-vscode:
    image: ghcr.io/jjgroenendijk/arch-vscode:latest
    environment:
      - PUID=1000
      - PGID=1000
      - EXTRA_PACKAGES=
      - NPM_PACKAGES=
    volumes:
      - ./:/workspace
      - ./home:/home/developer
    ports:
      - "8080:8080"
    restart: unless-stopped
```

## Configuration

Copy `.env.example` to `.env` and edit. Key variables:

| Variable | Default | Purpose |
|---|---|---|
| `PUID` / `PGID` | `1000` | Match host user to avoid permission issues |
| `USERNAME` | `developer` | Container user |
| `WORKSPACE_DIR` | `/workspace` | Workspace path inside container |
| `VSCODE_HOST` | `0.0.0.0` | Bind address |
| `VSCODE_PORT` | `8080` | Listen port |
| `VSCODE_CONNECTION_TOKEN` | _(empty)_ | Auth token (empty = no auth) |
| `EXTRA_PACKAGES` | _(empty)_ | Space-separated pacman packages |
| `NPM_PACKAGES` | _(empty)_ | Space-separated global npm packages |
| `AUTO_UPDATE` | `false` | Daily system update at 02:00 |
| `TZ` | `UTC` | Timezone |

See `.env.example` for the complete list.

## Persistence

When `./home` is mounted to `/home/developer`, settings, extensions and shell config persist across restarts. Project files belong in the path mounted to `/workspace`.

## Notes

- VS Code tracks the latest stable release from Microsoft. Override it at build time with `--build-arg VSCODE_VERSION=1.130.0` if you need a specific release.
- The container user has passwordless `sudo`.
- The package database is synced on each start, so `EXTRA_PACKAGES` works even with an old image.

## License

MIT
