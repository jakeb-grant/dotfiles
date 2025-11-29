#!/bin/bash

# Start SSH daemon for remote access
systemctl start sshd 2>/dev/null

if [[ -z \$DISPLAY ]] && [[ \$(tty) = /dev/tty1 ]]; then
    clear
    echo "Welcome to Hyprland Minimal Installer"
    echo ""
    echo "Type 'installer' to start the installation process"
    echo "SSH is available on port 22 (forwarded to host port 2222)"
    echo ""
fi

alias installer="/usr/local/bin/installer.sh"
source ~/.bashrc 2>/dev/null || true
