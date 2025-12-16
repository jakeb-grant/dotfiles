#!/bin/bash
# Create default monitors.conf if it doesn't exist

MONITORS_CONF="$HOME/.config/hypr/monitors.conf"

if [ ! -f "$MONITORS_CONF" ]; then
    mkdir -p "$(dirname "$MONITORS_CONF")"
    cat > "$MONITORS_CONF" << 'EOF'
# Default monitor configuration
# This uses Hyprland's automatic monitor detection and positioning.
# To customize, use: monitor-mgr

# Automatic monitor setup
monitor = ,preferred,auto,1
EOF
    echo "Created default monitors.conf"
fi
