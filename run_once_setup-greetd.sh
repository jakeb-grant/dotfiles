#!/bin/bash
# Configure greetd with tuigreet (runs once on new machines)

set -e

echo "Setting up greetd with tuigreet..."
echo "This requires sudo access."

# Install greetd config
sudo mkdir -p /etc/greetd
cat <<'EOF' | sudo tee /etc/greetd/config.toml > /dev/null
[terminal]
vt = 1

[default_session]
command = "tuigreet --remember --remember-session --time --asterisks --cmd 'start-hyprland &>/dev/null'"
user = "greeter"
EOF
sudo chmod 644 /etc/greetd/config.toml

# Configure greetd PAM with gnome-keyring support
cat <<'PAMEOF' | sudo tee /etc/pam.d/greetd > /dev/null
#%PAM-1.0

auth       required     pam_securetty.so
auth       requisite    pam_nologin.so
auth       include      system-local-login
-auth      optional     pam_gnome_keyring.so

account    include      system-local-login

password   include      system-local-login
-password  optional     pam_gnome_keyring.so    use_authtok

session    include      system-local-login
-session   optional     pam_gnome_keyring.so    auto_start
PAMEOF
sudo chmod 644 /etc/pam.d/greetd

# Ensure greeter user can access greetd
sudo usermod -aG video greeter 2>/dev/null || true

# Enable greetd, disable SDDM if active
if systemctl is-enabled --quiet sddm 2>/dev/null; then
    echo "Disabling SDDM..."
    sudo systemctl disable sddm
fi

if ! systemctl is-enabled --quiet greetd 2>/dev/null; then
    echo "Enabling greetd..."
    sudo systemctl enable greetd
fi

echo "greetd setup complete!"
