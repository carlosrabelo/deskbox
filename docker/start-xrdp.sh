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
# Configures user password via Docker secrets or environment variable
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
sudo -u "$USER_NAME" /usr/local/bin/setup-desktop.sh

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
# Starts D-Bus (Message Bus for inter-process communication)
# ==============================================================================
# Required for desktop applications and XFCE4
if [ ! -f /var/run/dbus/pid ]; then
    log "INFO" "Starting D-Bus..."
    dbus-daemon --system --fork
    log "INFO" "D-Bus started successfully"
else
    log "INFO" "D-Bus is already running"
fi

# ==============================================================================
# Starts SSH Server
# ==============================================================================
log "INFO" "Starting SSH server..."
/usr/sbin/sshd
log "INFO" "SSH server started on port 22 (exposed as 2222)"

# ==============================================================================
# Starts XRDP Session Manager (manages user sessions)
# ==============================================================================
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
