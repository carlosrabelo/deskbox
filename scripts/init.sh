#!/bin/sh
# ==============================================================================
# Deskbox Host Initialization Script
# ==============================================================================
# Prepares directory structure on HOST before first container start
# Executed via SSH on remote host: make init CTX=<context>
#
# Requirements:
#   - Root SSH access to host
#   - Available space in /mnt/deskbox
#
# Usage: make init CTX=production
# ==============================================================================

# ==============================================================================
# Configuration Variables
# ==============================================================================
BASE_DIR="/mnt/deskbox/home"           # Base directory mounted as /home in container
LOGS_DIR="/mnt/deskbox/logs"           # Logs directory mounted as /var/log/deskbox
USER_NAME="deskbox"                    # Fixed user name
USER_UID="${USER_UID:-1000}"           # User ID from env or default (must match container UID)
USER_GID="${USER_GID:-1000}"           # Group ID from env or default (must match container GID)
DIR_PERMISSIONS=755                    # Directory permissions (rwxr-xr-x)

# XDG user directories to create
USER_DIRS="Desktop Documents Downloads Pictures Videos"

# ==============================================================================
# Initialization
# ==============================================================================
echo "Initializing directory structure for Deskbox project..."

# ==============================================================================
# Creates base directories that will be mounted in container
# ==============================================================================
echo "Creating base directory for home..."
mkdir -p "$BASE_DIR"
chmod "$DIR_PERMISSIONS" "$BASE_DIR"

echo "Creating logs directory..."
mkdir -p "$LOGS_DIR"
chmod "$DIR_PERMISSIONS" "$LOGS_DIR"

# ==============================================================================
# Structure for default user
# ==============================================================================
USER_HOME="$BASE_DIR/$USER_NAME"

echo "Creating $USER_NAME user home directory..."
mkdir -p "$USER_HOME"

# Sets ownership to specified UID:GID
chown -R "$USER_UID:$USER_GID" "$USER_HOME"
chmod -R "$DIR_PERMISSIONS" "$USER_HOME"

# ==============================================================================
# Creates standard user directory structure (XDG Base Directory)
# ==============================================================================
# Creates each directory in the list
for dir in $USER_DIRS; do
    mkdir -p "$USER_HOME/$dir"
done

chown -R "$USER_UID:$USER_GID" "$USER_HOME"

# ==============================================================================
# Initialization summary
# ==============================================================================
echo ""
echo "[OK] Directory structure created successfully!"
echo "[OK] Home directory: $BASE_DIR"
echo "[OK] Logs directory: $LOGS_DIR"
echo "[OK] Default user: $USER_NAME (UID $USER_UID)"
echo "[OK] You can add other users after starting the container"
echo ""
echo "Home directory structure:"
ls -la "$BASE_DIR"
echo ""
echo "Logs directory:"
ls -la "$LOGS_DIR"
