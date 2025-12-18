#!/bin/bash
# ==============================================================================
# Deskbox XRDP Startup Script
# ==============================================================================
# Initializes and configures XRDP (Remote Desktop) server in container
# Executed automatically as CMD in Dockerfile
# ==============================================================================

set -e  # Stop execution on error

# ==============================================================================
# Logging Configuration
# ==============================================================================
LOG_DIR="/var/log/deskbox"
LOG_FILE="$LOG_DIR/startup.log"
XRDP_LOG_LEVEL="${XRDP_LOG_LEVEL:-INFO}"

# Create log directory
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

log "INFO" "==================================================================="
log "INFO" "Deskbox Desktop Environment - Startup Process"
log "INFO" "==================================================================="

# ==============================================================================
# Self-Healing & Initialization Logic
# ==============================================================================
# Ensures the environment is correct regardless of volume state (empty, wrong permissions, etc)
# This allows "on-the-fly" usage without external preparation steps like 'make init'

ensure_home_structure() {
    local user_home="/home/$USER_NAME"
    
    log "INFO" "Verifying home directory structure for $USER_NAME..."

    # If .bashrc is missing, it's a strong indicator that the home dir is empty or uninitialized
    if [ ! -f "$user_home/.bashrc" ]; then
        log "WARN" "Home directory appears incomplete. Populating from /etc/skel..."
        cp -r /etc/skel/. "$user_home/" 2>/dev/null || true
        log "INFO" "Populated $user_home from /etc/skel"
    fi

    # Create standard XDG directories if they don't exist
    for dir in Desktop Documents Downloads Music Pictures Public Templates Videos; do
        if [ ! -d "$user_home/$dir" ]; then
            log "INFO" "Creating missing directory: $user_home/$dir"
            mkdir -p "$user_home/$dir"
        fi
    done

    # Ensure .local/share/keyrings exists (for the keyring config later)
    mkdir -p "$user_home/.local/share/keyrings"
}

fix_permissions() {
    local user_home="/home/$USER_NAME"
    
    log "INFO" "Fixing permissions..."
    
    # Fix Home Directory Permissions
    # Recursive chown can be slow on huge volumes, but it's necessary for self-healing
    # We only run it if the owner of the home root is not correct
    if [ "$(stat -c '%u:%g' "$user_home")" != "$USER_UID:$USER_UID" ]; then
         log "WARN" "Home directory ownership incorrect. Fixing recursively..."
         chown -R "$USER_UID:$USER_UID" "$user_home"
         log "INFO" "Home directory permissions fixed."
    fi
    
    # Also ensure the user can write to their own home (sometimes mounts are read-only or root-owned)
    # This is a focused fix for top-level files
    chown "$USER_UID:$USER_UID" "$user_home" 2>/dev/null || true
    chown "$USER_UID:$USER_UID" "$user_home"/* 2>/dev/null || true
    chown "$USER_UID:$USER_UID" "$user_home"/.[!.]* 2>/dev/null || true
    chown -R "$USER_UID:$USER_UID" "$user_home/.config" 2>/dev/null || true
    chown -R "$USER_UID:$USER_UID" "$user_home/.local" 2>/dev/null || true

    # Fix Log Directory Permissions
    # Docker volumes usage might result in root-owned log dirs
    mkdir -p "$LOG_DIR"
    chown -R "$USER_UID:$USER_UID" "$LOG_DIR"
    chmod 755 "$LOG_DIR"
    
    log "INFO" "Permissions fixed."
}

# Run initialization steps
ensure_home_structure
fix_permissions

# ==============================================================================
# Configuration of user password via Docker secrets or environment variable
# ==============================================================================
# Priority: Docker secrets > Environment variable > Default
if [ -f "/run/secrets/user_password" ]; then
    log "INFO" "Setting password from Docker secret..."
    USER_PASSWORD=$(cat /run/secrets/user_password)
    echo "$USER_NAME:$USER_PASSWORD" | chpasswd
    log "INFO" "Password set successfully from Docker secret"
elif [ -n "$USER_PASSWORD" ]; then
    log "INFO" "Setting password from environment variable..."
    echo "$USER_NAME:$USER_PASSWORD" | chpasswd
    log "INFO" "Password set successfully from environment variable"
else
    log "WARN" "USER_PASSWORD not set and no Docker secret found"
    log "WARN" "Using default password 'deskbox' - CHANGE THIS IN PRODUCTION!"
    echo "$USER_NAME:deskbox" | chpasswd
fi

# Configure sudo password if separate secret exists
if [ -f "/run/secrets/sudo_password" ]; then
    log "INFO" "Separate sudo password detected - not implemented in this version"
    log "INFO" "User password will be used for sudo access"
fi

# ==============================================================================
# Setup desktop environment for all users
# ==============================================================================
log "INFO" "Setting up desktop environment..."
if [ -f "/usr/local/bin/setup-desktop.sh" ]; then
     # Run setup-desktop as the target user to ensure files created are owned by them
    sudo -u "$USER_NAME" /usr/local/bin/setup-desktop.sh
else
    log "WARN" "setup-desktop.sh not found, skipping specific desktop setup"
fi

# ==============================================================================
# Runtime Configuration Checks
# ==============================================================================
log "INFO" "Verifying home directory structure for $USER_NAME..."
ensure_home_structure

log "INFO" "Fixing permissions..."
fix_permissions
log "INFO" "Permissions fixed."

# Fix localhost resolution (Force IPv4 for XRDP -> Socat -> Sesman chain)
# Docker adds "::1 localhost" which confuses XRDP/Socat routing. We remove it.
if grep -q "::1" /etc/hosts; then
    log "INFO" "Forcing IPv4 localhost resolution..."
    cp /etc/hosts /tmp/hosts
    sed -i '/::1/d' /tmp/hosts
    cat /tmp/hosts > /etc/hosts
fi

# ==============================================================================
# Configure Keyring for User
# ==============================================================================
log "INFO" "Configuring keyring for user $USER_NAME..."

# Create keyring configuration directory and file
mkdir -p "/home/$USER_NAME/.local/share/keyrings"
cat > "/home/$USER_NAME/.local/share/keyrings/default" << 'EOF'
[keyring]
display-name=Default
lock-on-idle=false
lock-timeout=0
EOF

# Set proper ownership and permissions
chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME/.local/share/keyrings"
chmod 700 "/home/$USER_NAME/.local/share/keyrings"
chmod 600 "/home/$USER_NAME/.local/share/keyrings/default"

log "INFO" "Keyring configuration completed"

# ==============================================================================
# Creates runtime directories required for XRDP, D-Bus, and SSH
# ==============================================================================
log "INFO" "Creating runtime directories..."
mkdir -p /var/run/dbus
mkdir -p /var/run/xrdp
mkdir -p /var/run/sshd

# Create XDG_RUNTIME_DIR for the user (fixes dbus and xfce session issues)
if [ ! -d "/run/user/$USER_UID" ]; then
    log "INFO" "Creating XDG_RUNTIME_DIR for user $USER_UID..."
    mkdir -p "/run/user/$USER_UID"
    chown "$USER_UID:$USER_UID" "/run/user/$USER_UID"
    chmod 700 "/run/user/$USER_UID"
fi

# ==============================================================================
# Setup Log Rotation
# ==============================================================================
log "INFO" "Setting up log rotation..."
# Install cron if not available
if ! command -v cron >/dev/null 2>&1; then
    apt-get update && apt-get install -y cron && apt-get clean
fi

# Setup cron job for log rotation
if [ -f "/usr/local/bin/log-rotation.sh" ]; then
    # Create cron job for hourly log rotation
    echo "0 * * * * root /usr/local/bin/log-rotation.sh rotate >/dev/null 2>&1" > /etc/cron.d/deskbox-log-rotation
    echo "0 2 * * * root /usr/local/bin/log-rotation.sh compress >/dev/null 2>&1" >> /etc/cron.d/deskbox-log-rotation
    echo "0 3 * * 0 root /usr/local/bin/log-rotation.sh clean >/dev/null 2>&1" >> /etc/cron.d/deskbox-log-rotation
    
    # Start cron service
    service cron start
    log "INFO" "Log rotation configured and cron service started"
else
    log "WARN" "Log rotation script not found"
fi

# Keyring already configured above

# ==============================================================================
# Starts Deskbox Services
# ==============================================================================
log "INFO" "Starting D-Bus..."
service dbus start

log "INFO" "Starting SSH server..."
/usr/sbin/sshd
log "INFO" "SSH server started on port 2222"

log "INFO" "Starting sesman IPv4->IPv6 bridge..."
# Sesman binds to ::1 but xrdp wants 127.0.0.1. We bridge them.
socat TCP4-LISTEN:3350,bind=127.0.0.1,fork TCP6:[::1]:3350 &

log "INFO" "Starting xrdp-sesman..."
/usr/sbin/xrdp-sesman &
log "INFO" "xrdp-sesman started"

# Waits for session manager to fully initialize
log "INFO" "Waiting for session manager initialization..."
sleep 2

# ==============================================================================
# Starts XRDP in foreground mode (keeps container running)
# ==============================================================================
# --nodaemon: Keeps process in foreground (required for containers)
log "INFO" "Starting XRDP server..."
log "INFO" "==================================================================="
log "INFO" "Deskbox Desktop Environment is ready!"
log "INFO" "RDP Access: <host>:3389 (user: $USER_NAME)"
log "INFO" "SSH Access: ssh -p 2222 $USER_NAME@<host>"
log "INFO" "==================================================================="

exec /usr/sbin/xrdp --nodaemon 2>&1 | tee -a "$LOG_DIR/xrdp.log"
