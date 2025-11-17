#!/bin/bash
# ==============================================================================
# Debian-RDP Desktop Environment Setup Script
# ==============================================================================
# Ensures proper initialization of XFCE4 desktop environment
# ==============================================================================

# Create necessary directories for X11 and desktop
mkdir -p "$HOME/.cache/sessions"
mkdir -p "$HOME/.local/share/xfce4"
mkdir -p "$HOME/.config/autostart"

# Set proper permissions
chmod 755 "$HOME"
chmod -R 755 "$HOME/.config"
chmod -R 755 "$HOME/.cache"
chmod -R 755 "$HOME/.local"

# Ensure .xsession exists and is executable
if [ ! -f "$HOME/.xsession" ]; then
    echo "startxfce4" > "$HOME/.xsession"
fi
chmod +x "$HOME/.xsession"

# Create desktop directories if they don't exist
for dir in Desktop Documents Downloads Pictures Videos Music; do
    mkdir -p "$HOME/$dir"
done

# Set proper ownership
chown -R "$USER:$USER" "$HOME"

exit 0