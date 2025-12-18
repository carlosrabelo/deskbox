#!/bin/bash
# ==============================================================================
# Deskbox - System Configuration Script
# ==============================================================================
# Configures user, SSH, and system-wide settings
# Usage: ./configure-system.sh <user_name> <user_uid>
# ==============================================================================

set -e

USER_NAME="$1"
USER_UID="$2"

if [ -z "$USER_NAME" ] || [ -z "$USER_UID" ]; then
    echo "Usage: $0 <user_name> <user_uid>"
    exit 1
fi

echo "Configuring system for user: $USER_NAME (UID: $USER_UID)..."

# Creates non-root user with sudo privileges
useradd -m -u $USER_UID -s /bin/bash "$USER_NAME"
usermod -aG sudo "$USER_NAME"
echo "$USER_NAME ALL=(ALL) ALL" >> /etc/sudoers

# Adjusts home directory permissions
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME

# SSH Server Configuration
# SSH Server Configuration
mkdir -p /var/run/sshd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
echo "AllowUsers $USER_NAME" >> /etc/ssh/sshd_config

# Docker Secrets Support
mkdir -p /run/secrets
chmod 700 /run/secrets

# Custom Profile Configuration
cat << 'EOF' > /etc/profile.d/deskbox.sh
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

chmod +x /etc/profile.d/deskbox.sh

echo "System configuration completed."
