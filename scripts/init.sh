#!/bin/bash
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

set -euo pipefail  # Enhanced error handling

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function to validate input
validate_input() {
    local var_name=$1
    local var_value=$2
    local pattern=$3
    
    if [[ -z "$var_value" ]]; then
        print_status $RED "Error: $var_name is not set"
        exit 1
    fi
    
    if [[ -n "$pattern" ]] && [[ ! "$var_value" =~ $pattern ]]; then
        print_status $RED "Error: $var_name has invalid value: $var_value"
        exit 1
    fi
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_status $RED "This script must be run as root"
        exit 1
    fi
}

# Function to check available disk space
check_disk_space() {
    local required_gb=5  # Minimum 5GB required
    local path=$1
    
    local available_kb=$(df "$path" | awk 'NR==2 {print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    
    if [[ $available_gb -lt $required_gb ]]; then
        print_status $RED "Insufficient disk space. Required: ${required_gb}GB, Available: ${available_gb}GB"
        exit 1
    fi
    
    print_status $GREEN "Disk space check passed: ${available_gb}GB available"
}

# Function to create directory with validation
create_secure_dir() {
    local dir_path=$1
    local owner=$2
    local permissions=$3
    
    # Validate path
    if [[ ! "$dir_path" =~ ^/mnt/deskbox ]]; then
        print_status $RED "Error: Directory path must be under /mnt/deskbox"
        exit 1
    fi
    
    # Create directory
    mkdir -p "$dir_path"
    
    # Set permissions
    chmod "$permissions" "$dir_path"
    
    # Set ownership if specified
    if [[ -n "$owner" ]]; then
        chown "$owner" "$dir_path"
    fi
    
    print_status $GREEN "Created directory: $dir_path"
}

# Function to validate UID/GID
validate_uid_gid() {
    local uid=$1
    local gid=$2
    
    # Check if UID is numeric and within valid range
    if ! [[ "$uid" =~ ^[0-9]+$ ]] || [[ $uid -lt 1000 ]] || [[ $uid -gt 65533 ]]; then
        print_status $RED "Error: Invalid UID: $uid (must be 1000-65533)"
        exit 1
    fi
    
    # Check if GID is numeric and within valid range
    if ! [[ "$gid" =~ ^[0-9]+$ ]] || [[ $gid -lt 1000 ]] || [[ $gid -gt 65533 ]]; then
        print_status $RED "Error: Invalid GID: $gid (must be 1000-65533)"
        exit 1
    fi
    
    print_status $GREEN "UID/GID validation passed: UID=$uid, GID=$gid"
}

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
# Pre-initialization Validation
# ==============================================================================
print_status $BLUE "Starting Deskbox directory initialization..."
print_status $BLUE "============================================"

# Check if running as root
check_root

# Validate configuration
validate_input "USER_NAME" "$USER_NAME" "^[a-z][a-z0-9_-]*$"
validate_input "BASE_DIR" "$BASE_DIR" "^/mnt/deskbox"
validate_input "LOGS_DIR" "$LOGS_DIR" "^/mnt/deskbox"

# Validate UID/GID
validate_uid_gid "$USER_UID" "$USER_GID"

# Check disk space
check_disk_space "/mnt"

# ==============================================================================
# Creates base directories that will be mounted in container
# ==============================================================================
print_status $BLUE "Creating base directories..."

# Create base directory for home
create_secure_dir "$BASE_DIR" "" "$DIR_PERMISSIONS"

# Create logs directory
create_secure_dir "$LOGS_DIR" "" "$DIR_PERMISSIONS"

# ==============================================================================
# Structure for default user
# ==============================================================================
USER_HOME="$BASE_DIR/$USER_NAME"

print_status $BLUE "Creating user home directory structure..."

# Create user home directory
create_secure_dir "$USER_HOME" "$USER_UID:$USER_GID" "$DIR_PERMISSIONS"

# ==============================================================================
# Creates standard user directory structure (XDG Base Directory)
# ==============================================================================
print_status $BLUE "Creating XDG user directories..."

# Creates each directory in the list with validation
for dir in $USER_DIRS; do
    # Validate directory name
    if [[ ! "$dir" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]]; then
        print_status $RED "Error: Invalid directory name: $dir"
        exit 1
    fi
    
    dir_path="$USER_HOME/$dir"
    create_secure_dir "$dir_path" "$USER_UID:$USER_GID" "$DIR_PERMISSIONS"
done

# ==============================================================================
# Final Validation and Summary
# ==============================================================================
print_status $BLUE "Performing final validation..."

# Verify all directories were created
validation_failed=0

for dir in "$BASE_DIR" "$LOGS_DIR" "$USER_HOME"; do
    if [[ ! -d "$dir" ]]; then
        print_status $RED "Error: Directory not created: $dir"
        validation_failed=1
    fi
done

# Verify user directories
for dir in $USER_DIRS; do
    dir_path="$USER_HOME/$dir"
    if [[ ! -d "$dir_path" ]]; then
        print_status $RED "Error: User directory not created: $dir_path"
        validation_failed=1
    fi
done

# Check permissions
if [[ $validation_failed -eq 0 ]]; then
    # Verify ownership
    actual_owner=$(stat -c "%u:%g" "$USER_HOME" 2>/dev/null || stat -f "%u:%g" "$USER_HOME" 2>/dev/null)
    expected_owner="$USER_UID:$USER_GID"
    
    if [[ "$actual_owner" != "$expected_owner" ]]; then
        print_status $RED "Error: Ownership mismatch. Expected: $expected_owner, Actual: $actual_owner"
        validation_failed=1
    fi
fi

if [[ $validation_failed -eq 0 ]]; then
    print_status $GREEN "✓ All validations passed!"
else
    print_status $RED "✗ Validation failed!"
    exit 1
fi

# ==============================================================================
# Initialization summary
# ==============================================================================
print_status $GREEN "============================================"
print_status $GREEN "Directory structure created successfully!"
print_status $GREEN "============================================"
print_status $GREEN "Home directory: $BASE_DIR"
print_status $GREEN "Logs directory: $LOGS_DIR"
print_status $GREEN "Default user: $USER_NAME (UID $USER_UID)"
print_status $GREEN "You can add other users after starting the container"
echo ""
print_status $BLUE "Home directory structure:"
ls -la "$BASE_DIR"
echo ""
print_status $BLUE "Logs directory:"
ls -la "$LOGS_DIR"
echo ""
print_status $GREEN "Initialization completed successfully!"
