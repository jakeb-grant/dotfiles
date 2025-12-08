# 1. Configure iwd with DHCP BEFORE switching
sudo mkdir -p /etc/iwd
sudo tee /etc/iwd/main.conf << 'EOF'
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF

# 2. Stop NetworkManager and wpa_supplicant
sudo systemctl disable --now NetworkManager wpa_supplicant

# 3. Reload wifi driver (key step you missed last time)
sudo modprobe -r ath10k_pci && sudo modprobe ath10k_pci

# 4. Start iwd
sudo systemctl enable --now iwd

# 5. Connect to wifi
iwctl station wlan0 scan
iwctl station wlan0 get-networks
iwctl station wlan0 connect "MOTOF054"
