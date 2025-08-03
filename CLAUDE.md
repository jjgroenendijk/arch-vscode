# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains a Docker container that provides an Arch Linux development environment with VS Code accessible via web browser. The container uses the official Arch Linux image and installs Microsoft VS Code directly from official Microsoft servers.

## Coding Guidelines

- Never use emojis anywhere. If we encounter emojis anywhere in the code, we will add to the to do that we will clean up emojis

## Container Architecture

- **Base Image**: `archlinux:latest` (official Arch Linux image)
- **VS Code Installation**: Microsoft VS Code direct binary download from official servers
- **Web Interface**: VS Code serve-web mode for direct localhost access
- **Port**: Access VS Code web interface directly at localhost:8080 (no authentication required)
- **Volume**: Project files mounted to `/workspace` in container
- **Data Persistence**: VS Code data stored in `/config` directory for persistence across container restarts
- **Multi-Platform**: Supports AMD64, ARM64, and ARM32 architectures
- **User Management**: Container starts as root, entrypoint switches to developer user (UID/GID configurable via PUID/PGID env vars)
- **AUR Support**: Includes yay AUR helper for additional package installation

## Build Process

- **Package Installation**: Verbose output redirected to log files to keep CI logs clean
- **Build Logs Location**: 
  - `/var/log/pacman-update.log` - System update logs
  - `/var/log/pacman-install.log` - Package installation logs  
  - `/var/log/pacman-cleanup.log` - Package cache cleanup logs
  - `/var/log/yay-clone.log` - Yay AUR helper clone logs
  - `/var/log/yay-build.log` - Yay build and installation logs

## Known Issues & Fixes

- **Container Startup**: Fixed issue where container would exit immediately due to USER directive conflicts
- **Cron Services**: Uses direct cron daemon instead of systemd services for container compatibility
- **User Permissions**: Entrypoint properly handles user switching and permission setup

## Testing

- GitHub Actions workflow includes container startup test to verify functionality
- Test runs container for 30 seconds and validates it remains running
- Health check endpoint available at `http://localhost:8080/` for monitoring

## Development Guidelines

- **Dockerfile Changes**: When modifying package installations, ensure output is redirected to appropriate log files
- **Entrypoint Modifications**: Test user switching logic thoroughly as it's critical for container startup
- **CI/CD**: Always test container startup after significant changes to avoid build failures
- **Logging**: Prefer logging to files over complete silence for debugging purposes

## Troubleshooting

- **Container Exits Immediately**: Check entrypoint logs, likely user permission or switching issue
- **Build Failures**: Check log files in `/var/log/` within container for detailed error messages
- **Permission Issues**: Verify PUID/PGID environment variables are set correctly
- **VS Code Not Starting**: Check that port 8080 is available and health check endpoint responds