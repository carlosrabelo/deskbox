# ==============================================================================
# Deskbox Desktop Environment - Multi-Stage Dockerfile
# ==============================================================================
# Based on Debian 13 (Trixie) with XFCE4 Desktop + XRDP Server
# Build optimized in 3 stages for better cache utilization
# ==============================================================================

# ==============================================================================
# Stage 1: Base System - Essential packages and global configurations
# ==============================================================================
# This layer rarely changes, providing long-lasting cache
# Using debian:trixie with explicit registry for better connectivity
FROM docker.io/library/debian:trixie AS base

# Environment settings for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Cuiaba \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Installs base operating system packages
# --no-install-recommends: installs only essential dependencies
COPY docker/packages-base.txt /tmp/packages-base.txt
RUN apt-get update && \
    grep -v '^#' /tmp/packages-base.txt | grep -v '^$' > /tmp/packages-clean.txt && \
    for pkg in $(cat /tmp/packages-clean.txt); do \
        if apt-cache show "$pkg" >/dev/null 2>&1; then \
            echo "$pkg" >> /tmp/packages-valid.txt; \
        else \
            echo "Warning: Package $pkg not found, skipping..."; \
        fi; \
    done && \
    if [ -f /tmp/packages-valid.txt ]; then \
        xargs -a /tmp/packages-valid.txt apt-get install -y --no-install-recommends; \
    fi && \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configures system timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Generates UTF-8 locales for international support
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

# ==============================================================================
# Stage 2: Desktop Environment - XRDP + XFCE4 Desktop
# ==============================================================================
# Layer with large desktop packages, changes occasionally
FROM base AS desktop

# Installs XRDP (Remote Desktop Protocol) and XFCE4 (Desktop Environment)
# xrdp: RDP server compatible with Microsoft Remote Desktop
# xfce4: Lightweight and efficient desktop
# xorgxrdp: Xorg driver for XRDP (better performance)
COPY docker/packages-desktop.txt /tmp/packages-desktop.txt
RUN apt-get update && \
    grep -v '^#' /tmp/packages-desktop.txt | grep -v '^$' > /tmp/packages-clean.txt && \
    for pkg in $(cat /tmp/packages-clean.txt); do \
        if apt-cache show "$pkg" >/dev/null 2>&1; then \
            echo "$pkg" >> /tmp/packages-valid.txt; \
        else \
            echo "Warning: Package $pkg not found, skipping..."; \
        fi; \
    done && \
    if [ -f /tmp/packages-valid.txt ]; then \
        xargs -a /tmp/packages-valid.txt apt-get install -y --no-install-recommends; \
    fi && \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Installs Chromium web browser
RUN apt-get update && \
    apt-get install -y --no-install-recommends chromium && \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



# Create Chromium wrapper for container environment
# Uses --no-sandbox because containers don't support user namespaces properly
RUN mv /usr/bin/chromium /usr/bin/chromium-bin && \
    cat << 'EOF' > /usr/bin/chromium && \
    chmod +x /usr/bin/chromium
#!/bin/bash
exec /usr/bin/chromium-bin --no-sandbox "$@"
EOF

# Configures XRDP startup script
# This script is executed when user logs in via RDP
RUN cat << 'EOF' > /etc/xrdp/startwm.sh
#!/bin/sh
if [ -r /etc/profile ]; then
  . /etc/profile
fi
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

# Executes user's .xsession if it exists, otherwise starts XFCE4
if [ -r "$HOME/.xsession" ]; then
  exec sh "$HOME/.xsession"
else
  exec startxfce4
fi
EOF

RUN chmod +x /etc/xrdp/startwm.sh

# ==============================================================================
# Stage 3: Final Configuration - User and runtime scripts
# ==============================================================================
# Final layer with specific configurations, changes frequently
FROM desktop AS final

# Build arguments allow customization at build time
ARG USER_NAME=deskbox
ARG USER_UID=1000

# Converts ARGs to ENVs for runtime usage
ENV USER_NAME=${USER_NAME} \
    USER_UID=${USER_UID}

# Creates non-root user with sudo privileges
# 1. Creates new user with specific UID
# 2. Adds to sudo group
# 3. Configures sudo with password requirement (security improvement)
RUN useradd -m -u $USER_UID -s /bin/bash "$USER_NAME" && \
    usermod -aG sudo "$USER_NAME" && \
    echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers

# Configures .xsession to automatically start XFCE4 on RDP login
RUN echo "startxfce4" > /home/$USER_NAME/.xsession && \
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/.xsession

# Adjusts home directory permissions
RUN chown -R $USER_NAME:$USER_NAME /home/$USER_NAME

# ==============================================================================
# SSH Server Configuration
# ==============================================================================
# Creates SSH directory and configures for security
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "AllowUsers $USER_NAME" >> /etc/ssh/sshd_config

# ==============================================================================
# Docker Secrets Support
# ==============================================================================
# Creates directory for Docker secrets and sets permissions
RUN mkdir -p /run/secrets && \
    chmod 700 /run/secrets

# ==============================================================================
# XFCE4 First Run Configuration
# ==============================================================================
# Copies first-run script and sets up autostart
COPY docker/xfce4-first-run.sh /usr/local/bin/xfce4-first-run.sh
RUN chmod +x /usr/local/bin/xfce4-first-run.sh

# Creates autostart entry in /etc/skel (template for new users)
RUN mkdir -p /etc/skel/.config/autostart && \
    cat << 'EOF' > /etc/skel/.config/autostart/deskbox-first-run.desktop
[Desktop Entry]
Type=Application
Name=Deskbox First Run Configuration
Exec=/usr/local/bin/xfce4-first-run.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# Copies autostart to existing user
RUN mkdir -p /home/$USER_NAME/.config/autostart && \
    cp /etc/skel/.config/autostart/deskbox-first-run.desktop /home/$USER_NAME/.config/autostart/ && \
    chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config

# ==============================================================================
# Custom Profile Configuration
# ==============================================================================
# Creates system-wide profile with useful aliases and settings
RUN cat << 'EOF' > /etc/profile.d/deskbox.sh
# Deskbox Desktop Environment - Custom Profile
# Loaded automatically for all users

# Useful aliases
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias gs='git status'
alias gp='git pull'
alias gc='git commit'
alias gd='git diff'
alias update='sudo apt update && sudo apt upgrade -y'
alias ports='netstat -tulanp'

# Editor preferences
export EDITOR=nano
export VISUAL=nano

# Colorful prompt
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups

# Enable colors for ls, grep, etc
export CLICOLOR=1
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

echo "Welcome to Deskbox Desktop Environment!"
echo "Type 'll' for detailed file listing, 'htop' for system monitor"
EOF

RUN chmod +x /etc/profile.d/deskbox.sh

# ==============================================================================
# Keyring Configuration (No Password Prompts)
# ==============================================================================
# Creates empty keyring configuration to prevent password prompts
RUN mkdir -p /etc/skel/.local/share/keyrings && \
    cat > /etc/skel/.local/share/keyrings/default << 'EOF'
[keyring]
display-name=Default
lock-on-idle=false
lock-timeout=0
EOF

# Chromium wrapper will be created at runtime in start-xrdp.sh

# Copies setup scripts into the container
COPY docker/start-xrdp.sh /usr/local/bin/start-xrdp.sh
COPY docker/setup-desktop.sh /usr/local/bin/setup-desktop.sh
COPY scripts/log-rotation.sh /usr/local/bin/log-rotation.sh

RUN chmod +x /usr/local/bin/start-xrdp.sh /usr/local/bin/setup-desktop.sh /usr/local/bin/log-rotation.sh

# Exposes RDP (Remote Desktop Protocol) port and SSH port
EXPOSE 3389 22

# Command executed when container starts
# exec: allows script to receive signals (SIGTERM, etc)
CMD ["/usr/local/bin/start-xrdp.sh"]
