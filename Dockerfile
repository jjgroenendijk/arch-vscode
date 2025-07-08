# Consolidated Dockerfile for Arch Linux + VS Code
FROM archlinux/archlinux:latest

# Build arguments for flexibility
ARG ENTRYPOINT_SCRIPT=entrypoint.sh
ARG TARGETARCH=amd64

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
        cronie \
        nss \
        gtk3 \
        alsa-lib \
        xorg-server-xvfb \
        libxrandr \
        libxss \
        libdrm \
        libxcomposite \
        libxdamage \
        libxfixes \
        ca-certificates \
        ca-certificates-mozilla \
        openssl \
        && \
    pacman -Scc --noconfirm

# Create non-root user
RUN useradd -m -s /bin/bash -G wheel developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Download and install VS Code directly from Microsoft
USER developer
WORKDIR /home/developer
RUN case ${TARGETARCH} in \
        amd64) ARCH=x64 ;; \
        arm64) ARCH=arm64 ;; \
        arm) ARCH=arm ;; \
        *) ARCH=x64 ;; \
    esac && \
    mkdir -p /tmp/vscode && \
    curl -L -o /tmp/vscode/vscode.tar.gz "https://update.code.visualstudio.com/latest/linux-${ARCH}/stable" && \
    sudo mkdir -p /opt/vscode && \
    sudo tar -xzf /tmp/vscode/vscode.tar.gz -C /opt/vscode --strip-components=1 && \
    sudo ln -s /opt/vscode/bin/code /usr/local/bin/code && \
    rm -rf /tmp/vscode

# Switch back to root for system configuration
USER root

# Create workspace and config directories with subdirectories
RUN mkdir -p /workspace /config/user-data /config/extensions /config/server-data && \
    chown -R developer:developer /workspace /config

# Set up environment variables
ENV PUID=1000 \
    PGID=1000 \
    WORKSPACE_DIR=/workspace \
    VSCODE_USER_DATA_DIR=/config/user-data \
    VSCODE_EXTENSIONS_DIR=/config/extensions \
    VSCODE_SERVER_DATA_DIR=/config/server-data \
    EXTRA_PACKAGES="" \
    AUTO_UPDATE=false \
    TZ=UTC \
    SSL_CERT_DIR=/etc/ssl/certs \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    XDG_CONFIG_HOME=/config \
    XDG_DATA_HOME=/config

# Copy entrypoint script and auto-update script
COPY scripts/${ENTRYPOINT_SCRIPT} /usr/local/bin/entrypoint.sh
COPY scripts/auto-update.sh /usr/local/bin/auto-update.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/auto-update.sh

# Add OCI labels for container metadata
LABEL org.opencontainers.image.title="Arch Linux VS Code Container" \
      org.opencontainers.image.description="Arch Linux container with VS Code accessible via web interface" \
      org.opencontainers.image.source="https://github.com/jjgroenendijk/arch-vscode" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="jjgroenendijk"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Expose port for VS Code serve-web
EXPOSE 8080

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER developer

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]