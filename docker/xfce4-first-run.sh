#!/bin/bash
# ==============================================================================
# Deskbox XFCE4 First Run Configuration
# ==============================================================================
# Configures XFCE4 desktop environment on first user login
# Executed automatically via autostart mechanism
# ==============================================================================

MARKER_FILE="$HOME/.config/deskbox-configured"

# Exit if already configured
if [ -f "$MARKER_FILE" ]; then
    exit 0
fi

# ==============================================================================
# Create XFCE4 configuration directories
# ==============================================================================
mkdir -p "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$HOME/.config/autostart"

# ==============================================================================
# Configure XFCE4 Panel (complete panel with applets)
# ==============================================================================
cat > "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="2"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="size" type="uint" value="30"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="7"/>
        <value type="int" value="8"/>
        <value type="int" value="9"/>
      </property>
    </property>
    <property name="panel-2" type="empty">
      <property name="position" type="string" value="p=2;x=0;y=0"/>
      <property name="size" type="uint" value="30"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="10"/>
        <value type="int" value="11"/>
        <value type="int" value="12"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="empty">
      <property name="name" type="string" value="applicationsmenu"/>
    </property>
    <property name="plugin-2" type="empty">
      <property name="name" type="string" value="whiskermenu"/>
    </property>
    <property name="plugin-3" type="empty">
      <property name="name" type="string" value="tasklist"/>
    </property>
    <property name="plugin-4" type="empty">
      <property name="name" type="string" value="separator"/>
    </property>
    <property name="plugin-5" type="empty">
      <property name="name" type="string" value="pager"/>
    </property>
    <property name="plugin-6" type="empty">
      <property name="name" type="string" value="separator"/>
    </property>
    <property name="plugin-7" type="empty">
      <property name="name" type="string" value="systray"/>
    </property>
    <property name="plugin-8" type="empty">
      <property name="name" type="string" value="pulseaudio"/>
    </property>
    <property name="plugin-9" type="empty">
      <property name="name" type="string" value="clock"/>
    </property>
    <property name="plugin-10" type="empty">
      <property name="name" type="string" value="showdesktop"/>
    </property>
    <property name="plugin-11" type="empty">
      <property name="name" type="string" value="launcher"/>
    </property>
    <property name="plugin-12" type="empty">
      <property name="name" type="string" value="actions"/>
    </property>
  </property>
</channel>
EOF

# ==============================================================================
# Configure XFCE4 Desktop (wallpaper, icons and appearance)
# ==============================================================================
cat > "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/xfce/xfce-blue.jpg"/>
          <property name="image-style" type="int" value="5"/>
          <property name="image-show" type="bool" value="true"/>
        </property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="file-icons" type="empty">
      <property name="show-home" type="bool" value="true"/>
      <property name="show-filesystem" type="bool" value="true"/>
      <property name="show-trash" type="bool" value="true"/>
      <property name="show-removable" type="bool" value="true"/>
    </property>
    <property name="icon-size" type="uint" value="48"/>
    <property name="tooltip-size" type="uint" value="128"/>
  </property>
</channel>
EOF

# ==============================================================================
# Configure Appearance (themes, icons, fonts)
# ==============================================================================
cat > "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Default"/>
    <property name="title_font" type="string" value="Ubuntu Bold 11"/>
    <property name="button_layout" type="string" value="O|SHMC"/>
  </property>
</channel>
EOF

cat > "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Adwaita"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
    <property name="DoubleClickTime" type="int" value="400"/>
    <property name="DndDragThreshold" type="int" value="8"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Ubuntu 11"/>
    <property name="MonospaceFontName" type="string" value="Ubuntu Mono 11"/>
    <property name="CursorThemeName" type="string" value="Adwaita"/>
    <property name="CursorThemeSize" type="int" value="24"/>
    <property name="ThemeName" type="string" value="Adwaita"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
  </property>
</channel>
EOF

# ==============================================================================
# Configure Window Manager (keyboard shortcuts)
# ==============================================================================
cat > "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="default" type="empty">
      <property name="&lt;Alt&gt;F2" type="string" value="xfce4-appfinder --collapsed"/>
      <property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="xfce4-terminal"/>
      <property name="&lt;Super&gt;e" type="string" value="thunar"/>
    </property>
  </property>
</channel>
EOF

# ==============================================================================
# Configure Whisker Menu (modern application menu)
# ==============================================================================
cat > "$HOME/.config/xfce4/panel/whiskermenu-1.rc" << 'EOF'
# Whisker Menu Configuration
favorites=xfce4-terminal.desktop,google-chrome.desktop,thunar.desktop,mousepad.desktop
recent=
button-title=Applications
button-icon=applications-system
button-single-row=false
show-button-title=true
show-button-icon=true
launcher-show-name=true
launcher-show-description=true
item-icon-size=2
hover-switch-category=false
category-icon-size=2
load-hierarchy=false
view-mode=1
recent-items-max=10
favorites-in-recent=true
position-search-alternate=true
position-commands-alternate=true
position-categories-alternate=false
menu-width=450
menu-height=500
menu-opacity=100
command-settings=xfce4-settings-manager
command-lockscreen=xflock4
command-switchuser=xfce4-session-logout -u
command-logout=xfce4-session-logout
command-reboot=xfce4-session-logout -r
command-shutdown=xfce4-session-logout -h
EOF

# ==============================================================================
# Create Welcome file on Desktop
# ==============================================================================
cat > "$HOME/Desktop/Welcome.txt" << 'EOF'
Welcome to Deskbox Desktop Environment!

Keyboard Shortcuts:
- Alt + F2         : Application Finder
- Ctrl + Alt + T   : Terminal
- Super + E        : File Manager
- Super (Win Key)  : Open Application Menu

Desktop Features:
- Modern Whisker Menu with search
- Dual panel layout (top and bottom)
- System tray with volume control
- Workspace switcher
- Desktop icons (Home, Filesystem, Trash)

Pre-installed Applications:
- Chromium         : Web Browser
- Thunar           : File Manager
- Mousepad         : Text Editor
- Xfce4 Terminal   : Terminal Emulator
- Task Manager     : System Monitor
- Screenshot       : Screen Capture Tool

For SSH access, use port 2222:
  ssh -p 2222 username@hostname

Enjoy your desktop!
EOF

chmod 644 "$HOME/Desktop/Welcome.txt"

# ==============================================================================
# Mark as configured
# ==============================================================================
echo "XFCE4 configured on $(date)" > "$MARKER_FILE"

exit 0
