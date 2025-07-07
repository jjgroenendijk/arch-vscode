# Consolidated Dockerfile for Arch Linux + VS Code
FROM archlinux/archlinux:latest

# Build arguments for flexibility
ARG ENTRYPOINT_SCRIPT=entrypoint.sh

# Set environment for non-interactive installation
ENV LANG=C.UTF-8

# Update system and install base packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        base-devel \
        git \
        curl \
        wget \
        sudo \
        && \
    pacman -Scc --noconfirm

# Create non-root user
RUN useradd -m -s /bin/bash -G wheel developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install AUR helper and Microsoft VS Code
USER developer
WORKDIR /home/developer
RUN git clone https://aur.archlinux.org/yay.git && \
    cd yay && \
    makepkg -si --noconfirm && \
    cd .. && \
    rm -rf yay && \
    yay -S --noconfirm visual-studio-code-bin

# Switch back to root for system configuration
USER root

# Create workspace directory
RUN mkdir -p /workspace && \
    chown developer:developer /workspace

# Set up environment variables
ENV PUID=1000 \
    PGID=1000 \
    WORKSPACE_DIR=/workspace \
    EXTRA_PACKAGES=""

# Copy entrypoint script
COPY scripts/${ENTRYPOINT_SCRIPT} /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Add OCI labels for container metadata
LABEL org.opencontainers.image.title="Arch Linux VS Code Container" \
      org.opencontainers.image.description="Arch Linux container with VS Code accessible via web interface" \
      org.opencontainers.image.source="https://github.com/user/arch-vscode" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="Custom Build"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Expose port for VS Code serve-web
EXPOSE 8080

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER developer

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["code", "serve-web", "--host", "0.0.0.0", "--port", "8080", "--without-connection-token"]