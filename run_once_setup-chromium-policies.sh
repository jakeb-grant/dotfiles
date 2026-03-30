#!/bin/bash
# Create Chromium and Google Chrome managed policy directories and grant
# user write access so theme-switch can write theme policies without sudo.

set -e

POLICY_DIRS=(
    "/etc/chromium/policies/managed"
    "/etc/opt/chrome/policies/managed"
)

echo "Setting up browser policy directories..."
echo "This requires sudo access."

for dir in "${POLICY_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
        echo "  Already set up: $dir"
        continue
    fi
    sudo mkdir -p "$dir"
    sudo setfacl -m "u:$USER:rwx" "$dir"
    echo "  Ready: $dir"
done
