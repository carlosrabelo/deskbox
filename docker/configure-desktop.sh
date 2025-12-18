#!/bin/bash
# ==============================================================================
# Deskbox - Desktop Configuration Script
# ==============================================================================
# Configures Chromium, XRDP, Keyrings, and Autostart
# Usage: ./configure-desktop.sh <user_name>
# ==============================================================================

set -e

USER_NAME="$1"

if [ -z "$USER_NAME" ]; then
    echo "Usage: $0 <user_name>"
    exit 1
fi

echo "Configuring desktop environment..."

# 1. Chromium Wrapper
# Uses --no-sandbox because containers don't support user namespaces properly
if [ -f /usr/bin/chromium ]; then
    mv /usr/bin/chromium /usr/bin/chromium-bin
    cat << 'EOF' > /usr/bin/chromium
#!/bin/bash
exec /usr/bin/chromium-bin --no-sandbox "$@"
EOF
    chmod +x /usr/bin/chromium
fi

# 2. XRDP Startup Script
# We use a standard, simplified configuration that works well in containers
cat << 'EOF' > /etc/xrdp/startwm.sh
#!/bin/sh
# Load system profile
if [ -r /etc/profile ]; then
  . /etc/profile
fi

# Set runtime dir (crucial for dbus)
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Sanitize DISPLAY (ensure it is :10.0 not ::10.0)
if [ -n "$DISPLAY" ]; then
    DISPLAY_NUM=$(echo "$DISPLAY" | sed 's/.*:\([0-9]\+\(\.[0-9]\+\)\?\)$/:\1/')
    export DISPLAY="$DISPLAY_NUM"
fi

# Unset DBUS address so dbus-launch starts a new session bus
unset DBUS_SESSION_BUS_ADDRESS

# Redirect stderr to file for debugging
exec 2> "$HOME/.xsession-errors"

# Launch the session
test -x /etc/X11/Xsession && exec /etc/X11/Xsession
exec /bin/sh /etc/X11/Xsession
EOF
chmod +x /etc/xrdp/startwm.sh

# 3. User Session Config (.xsession)
# Use dbus-launch + xfce4-session directly to avoid startxfce4 wrapper issues
echo "exec dbus-launch --exit-with-session xfce4-session" > /home/$USER_NAME/.xsession
chmod +x /home/$USER_NAME/.xsession
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.xsession

# 4. Keyring Configuration (PAM Auto-Unlock)
# Enable pam_gnome_keyring to unlock default keyring on login
if [ -f /etc/pam.d/xrdp-sesman ]; then
    # Add auth module if not present
    if ! grep -q "pam_gnome_keyring.so" /etc/pam.d/xrdp-sesman; then
        sed -i 's/@include common-auth/auth optional pam_gnome_keyring.so\n@include common-auth/' /etc/pam.d/xrdp-sesman
        sed -i 's/@include common-session/session optional pam_gnome_keyring.so auto_start\n@include common-session/' /etc/pam.d/xrdp-sesman
    fi
fi

# 5. First Run Configuration
mkdir -p /etc/skel/.config/autostart
cat << 'EOF' > /etc/skel/.config/autostart/deskbox-first-run.desktop
[Desktop Entry]
Type=Application
Name=Deskbox First Run Configuration
Exec=/usr/local/bin/xfce4-first-run.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# Copy autostart to existing user
mkdir -p /home/$USER_NAME/.config/autostart
cp /etc/skel/.config/autostart/deskbox-first-run.desktop /home/$USER_NAME/.config/autostart/
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config

echo "Desktop configuration completed."
