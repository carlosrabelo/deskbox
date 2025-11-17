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
# Configures user password via environment variable
# ==============================================================================
# USER_PASSWORD should be defined in docker-compose.yml or via -e
# Default: 'deskbox' (defined in docker-compose.yml)
if [ -n "$USER_PASSWORD" ]; then
    log "INFO" "Setting password for user $USER_NAME..."
    echo "$USER_NAME:$USER_PASSWORD" | chpasswd
    log "INFO" "Password set successfully"
else
    log "WARN" "USER_PASSWORD not set. Configure via -e USER_PASSWORD=yourpassword"
fi

# ==============================================================================
# Setup desktop environment for all users
# ==============================================================================
log "INFO" "Setting up desktop environment..."
sudo -u "$USER_NAME" /usr/local/bin/setup-desktop.sh
log "INFO" "Desktop environment configured"

# ==============================================================================
# Creates runtime directories required for XRDP, D-Bus, and SSH
# ==============================================================================
log "INFO" "Creating runtime directories..."
mkdir -p /var/run/dbus
mkdir -p /var/run/xrdp
mkdir -p /var/run/sshd

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
