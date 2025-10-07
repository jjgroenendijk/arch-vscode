# Consolidated Dockerfile for Arch Linux + VS Code
# hadolint ignore=DL3007
FROM archlinux/archlinux:latest

# Build arguments for flexibility
ARG ENTRYPOINT_SCRIPT=entrypoint.sh

# Set environment for non-interactive installation
ENV LANG=C.UTF-8

# Enable parallel downloads for faster package installation
RUN echo "ParallelDownloads = 5" >> /etc/pacman.conf

# Update system and install base packages (logs in /var/log/pacman-*.log)
RUN pacman -Syu --noconfirm --quiet > /var/log/pacman-update.log 2>&1 && \
    pacman -S --noconfirm --quiet \
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
        libx11 \
        libsecret \
        libxkbfile \
        ripgrep \
        ca-certificates \
        ca-certificates-mozilla \
        openssl \
        openssh \
        net-tools \
        > /var/log/pacman-install.log 2>&1 && \
    pacman -Scc --noconfirm --quiet > /var/log/pacman-cleanup.log 2>&1

# Create non-root user
RUN useradd -m -s /bin/bash -G wheel developer && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install yay (AUR helper) as developer user (logs in home directory)
USER developer
RUN bash -lc '\
    log=/tmp/yay-install.log; \
    : > "$log"; \
    tmpdir=$(mktemp -d); \
    if git clone https://aur.archlinux.org/yay.git "$tmpdir" >> "$log" 2>&1; then \
        cd "$tmpdir"; \
        if makepkg -si --noconfirm >> "$log" 2>&1; then \
            echo "yay installed successfully" >> "$log"; \
        else \
            echo "Warning: makepkg failed; continuing without yay" >&2; \
        fi; \
    else \
        echo "Warning: Unable to clone yay; continuing without yay" >&2; \
    fi; \
    rm -rf "$tmpdir" || true; \
    true'

# Download and install VS Code directly from Microsoft
USER root
WORKDIR /tmp
RUN mkdir -p /tmp/vscode && \
    curl -L -o /tmp/vscode/vscode.tar.gz "https://update.code.visualstudio.com/latest/linux-x64/stable" && \
    mkdir -p /opt/vscode && \
    tar -xzf /tmp/vscode/vscode.tar.gz -C /opt/vscode --strip-components=1 && \
    ln -sf /opt/vscode/bin/code /usr/local/bin/code && \
    rm -rf /tmp/vscode

# Switch back to root for system configuration
USER root

# Create workspace and prepare default developer config directories
RUN mkdir -p /workspace /home/developer/.config /home/developer/.local/share && \
    chown -R developer:developer /workspace /home/developer/.config /home/developer/.local/share

# Set up environment variables
ENV PUID=1000 \
    PGID=1000 \
    WORKSPACE_DIR=/workspace \
    VSCODE_DEFAULT_FOLDER=/workspace \
    VSCODE_HOST=0.0.0.0 \
    VSCODE_PORT=8080 \
    VSCODE_CONNECTION_TOKEN="" \
    VSCODE_SOCKET_PATH="" \
    VSCODE_ACCEPT_LICENSE=true \
    VSCODE_VERBOSE=false \
    VSCODE_LOG_LEVEL=info \
    EXTRA_PACKAGES="" \
    AUTO_UPDATE=false \
    TZ=UTC \
    SSL_CERT_DIR=/etc/ssl/certs \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    XDG_CONFIG_HOME=/home/developer/.config \
    XDG_DATA_HOME=/home/developer/.local/share

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

# Default to non-root user; entrypoint will escalate as needed for setup
USER developer

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
