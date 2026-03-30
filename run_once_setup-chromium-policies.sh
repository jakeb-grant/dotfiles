#!/bin/bash
# Create Chromium managed policy directory and grant user write access
# so theme-switch can write theme policies without sudo.

set -e

POLICY_DIR="/etc/chromium/policies/managed"

if [ -d "$POLICY_DIR" ] && [ -w "$POLICY_DIR" ]; then
    echo "Chromium policy dir already set up."
    exit 0
fi

echo "Setting up Chromium managed policy directory..."
echo "This requires sudo access."

sudo mkdir -p "$POLICY_DIR"
sudo setfacl -m "u:$USER:rwx" "$POLICY_DIR"

echo "Chromium policy dir ready: $POLICY_DIR"
