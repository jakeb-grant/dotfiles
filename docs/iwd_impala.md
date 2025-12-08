# iwd WiFi Configuration

## What You Need
- `iwd` package installed
- `systemd-resolved` (comes with systemd, already installed)

## Configuration

### 1. Create iwd config file
**File:** `/etc/iwd/main.conf`
```ini
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
```

### 2. Enable services
```bash
# Enable iwd
sudo systemctl enable iwd
sudo systemctl start iwd

# Enable systemd-resolved for DNS
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved
```

### 3. Disable old network managers (if switching from NetworkManager)
```bash
sudo systemctl disable --now NetworkManager
sudo systemctl disable --now wpa_supplicant
```

### 4. Connect to WiFi
```bash
iwctl station wlan0 scan
iwctl station wlan0 get-networks
iwctl station wlan0 connect "YourNetworkName"
```

## What Each Part Does
- **iwd**: Manages WiFi connections and assigns IP addresses (DHCP)
- **systemd-resolved**: Handles DNS lookups
- **EnableNetworkConfiguration=true**: iwd's built-in DHCP client
- **NameResolvingService=systemd**: Tells iwd to use systemd-resolved for DNS

## Troubleshooting
If DNS doesn't work, link resolv.conf:
```bash
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```
