#!/bin/bash
# ==============================================================================
# Deskbox Desktop Environment Setup Script
# ==============================================================================
# Ensures proper initialization of XFCE4 desktop environment
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

# Function to validate HOME directory
validate_home() {
    if [[ -z "$HOME" ]]; then
        print_status $RED "Error: HOME environment variable is not set"
        exit 1
    fi
    
    if [[ ! "$HOME" =~ ^/home/ ]]; then
        print_status $RED "Error: HOME must be under /home directory"
        exit 1
    fi
    
    if [[ ! -d "$HOME" ]]; then
        print_status $RED "Error: HOME directory does not exist: $HOME"
        exit 1
    fi
    
    print_status $GREEN "HOME directory validation passed: $HOME"
}

# Function to create directory
create_user_dir() {
    local dir_path=$1
    
    if [[ ! -d "$dir_path" ]]; then
        mkdir -p "$dir_path"
        print_status $GREEN "Created directory: $dir_path"
    else
        print_status $YELLOW "Directory already exists: $dir_path"
    fi
}

# Function to create .xsession
create_xsession() {
    local xsession_file="$HOME/.xsession"
    
    if [[ ! -f "$xsession_file" ]]; then
        echo "startxfce4" > "$xsession_file"
        print_status $GREEN "Created .xsession file"
    fi
    
    chmod +x "$xsession_file"
    print_status $GREEN ".xsession configured and made executable"
}

# ==============================================================================
# Main Setup Process
# ==============================================================================
print_status $BLUE "Starting desktop environment setup..."
print_status $BLUE "=================================="

# Validate environment
validate_home

# Create necessary directories
print_status $BLUE "Creating X11 and desktop directories..."
create_user_dir "$HOME/.cache/sessions"
create_user_dir "$HOME/.local/share/xfce4"
create_user_dir "$HOME/.config/autostart"

# Create desktop directories
print_status $BLUE "Creating desktop directories..."
for dir in Desktop Documents Downloads Pictures Videos Music; do
    create_user_dir "$HOME/$dir"
done

# Configure X session
print_status $BLUE "Configuring X session..."
create_xsession

print_status $GREEN "✓ Desktop environment setup completed successfully!"