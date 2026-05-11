#!/bin/bash
# Create default monitors.lua if it doesn't exist

MONITORS_LUA="$HOME/.config/hypr/monitors.lua"

if [ ! -f "$MONITORS_LUA" ]; then
    mkdir -p "$(dirname "$MONITORS_LUA")"
    cat > "$MONITORS_LUA" << 'EOF'
-- Default monitor configuration
-- Uses Hyprland's automatic monitor detection and positioning.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
EOF
    echo "Created default monitors.lua"
fi
