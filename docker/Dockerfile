# ==============================================================================
# Deskbox Desktop Environment - Multi-Stage Dockerfile
# ==============================================================================
# Based on Debian 12 (Bookworm) with XFCE4 Desktop + XRDP Server
# Build optimized in 3 stages for better cache utilization
# ==============================================================================

# ==============================================================================
# Stage 1: Base System - Essential packages and global configurations
# ==============================================================================
FROM docker.io/library/debian:bookworm AS base

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Cuiaba \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Copy build scripts for usage in all stages
COPY docker/install-deps.sh /usr/local/bin/install-deps.sh
RUN chmod +x /usr/local/bin/install-deps.sh

# Install base packages
COPY docker/packages-base.txt /tmp/packages-base.txt
RUN /usr/local/bin/install-deps.sh /tmp/packages-base.txt

# Configure system timezone and locale
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

# ==============================================================================
# Stage 2: Desktop Environment - XRDP + XFCE4 Desktop
# ==============================================================================
FROM base AS desktop

# Install desktop packages
COPY docker/packages-desktop.txt /tmp/packages-desktop.txt
RUN /usr/local/bin/install-deps.sh /tmp/packages-desktop.txt

# Install Chromium (separate step as it might not be in the list)
RUN apt-get update && \
    apt-get install -y --no-install-recommends chromium && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Stage 3: Final Configuration - User and runtime scripts
# ==============================================================================
FROM desktop AS final

ARG USER_NAME=deskbox
ARG USER_UID=1000

ENV USER_NAME=${USER_NAME} \
    USER_UID=${USER_UID}

# Copy configuration scripts
COPY docker/configure-system.sh /usr/local/bin/configure-system.sh
COPY docker/configure-desktop.sh /usr/local/bin/configure-desktop.sh
COPY docker/xfce4-first-run.sh /usr/local/bin/xfce4-first-run.sh

RUN chmod +x /usr/local/bin/configure-system.sh \
    /usr/local/bin/configure-desktop.sh \
    /usr/local/bin/xfce4-first-run.sh

# Run Configuration Scripts
# 1. System Setup (User, SSH, Profile)
RUN /usr/local/bin/configure-system.sh "${USER_NAME}" "${USER_UID}"

# 2. Desktop Setup (Chromium wrapper, XRDP config, Keyrings, Autostart)
RUN /usr/local/bin/configure-desktop.sh "${USER_NAME}"

# Copy Runtime Scripts
COPY docker/start-xrdp.sh /usr/local/bin/start-xrdp.sh
COPY docker/setup-desktop.sh /usr/local/bin/setup-desktop.sh
COPY docker/log-rotation.sh /usr/local/bin/log-rotation.sh

RUN chmod +x /usr/local/bin/start-xrdp.sh \
    /usr/local/bin/setup-desktop.sh \
    /usr/local/bin/log-rotation.sh

# Expose Ports
EXPOSE 3389 2222

# Entrypoint
CMD ["/usr/local/bin/start-xrdp.sh"]

