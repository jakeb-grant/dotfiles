# Hyprland Minimal Dotfiles & ISO Builder

A minimal Arch Linux ISO with Hyprland window manager and automated installer, plus chezmoi-managed dotfiles.

## Features

### Dotfiles
- **Window Manager**: Hyprland with custom keybindings
- **Terminal**: Ghostty with Catppuccin Mocha theme
- **Status Bar**: Waybar with system monitoring
- **Launcher**: Rofi-wayland for application launching
- **Notifications**: Mako notification daemon
- **Shell**: Bash with custom aliases and functions
- **Managed by**: Chezmoi for easy deployment across machines

### ISO Installer
- **Interactive**: Gum-based TUI installer
- **Network Setup**: Automatic WiFi/Ethernet configuration
- **Partitioning**: Automatic with customizable swap size
- **Encryption**: Optional LUKS full disk encryption
- **UEFI Only**: Modern systems only (no legacy BIOS)
- **Bootloader**: GRUB with encrypted boot support

## Quick Start

### Using the ISO

1. Download the latest ISO from [Releases](https://github.com/jakeb-grant/dotfiles/releases)
2. Write to USB drive:
   ```bash
   sudo dd if=hyprland-minimal-*.iso of=/dev/sdX bs=4M status=progress
   ```
3. Boot from USB in UEFI mode
4. Run `installer` to start the installation

### Managing Dotfiles

Install chezmoi and apply dotfiles:
```bash
chezmoi init --apply https://github.com/jakeb-grant/dotfiles.git
```

## Building the ISO

### Locally (Arch Linux)

```bash
# Install dependencies
sudo pacman -S archiso git

# Clone repository
git clone https://github.com/jakeb-grant/dotfiles.git
cd dotfiles

# Build ISO (requires root)
sudo ./build-iso.sh

# ISO will be in out/ directory
```

### Using GitHub Actions

The ISO is automatically built when:
- Changes are pushed to `archiso/`, `dot_config/`, or workflow files
- Manually triggered via GitHub Actions tab
- Can create releases with the workflow dispatch option

## Project Structure

```
.
├── dot_config/           # Chezmoi-managed config files
│   ├── hypr/            # Hyprland configuration
│   ├── waybar/          # Status bar config
│   ├── rofi/            # App launcher config
│   ├── mako/            # Notification config
│   └── ghostty/         # Terminal config
├── dot_bashrc           # Bash configuration
├── archiso/             # ISO build files
│   ├── airootfs/        # Live system filesystem
│   ├── packages.x86_64  # Package list
│   └── profiledef.sh    # ISO profile
└── .github/workflows/   # GitHub Actions

```

## Keybindings

### Hyprland

| Key | Action |
|-----|--------|
| `Super + Return` | Open terminal (Ghostty) |
| `Super + D` | Open launcher (Rofi) |
| `Super + Q` | Close window |
| `Super + Shift + E` | Exit Hyprland |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle floating |
| `Super + H/J/K/L` | Move focus |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + Ctrl + H/J/K/L` | Resize window |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move to workspace |
| `Print` | Screenshot (full) |
| `Shift + Print` | Screenshot (selection) |

## System Requirements

- UEFI-capable system
- 2GB+ RAM (4GB recommended)
- 20GB+ disk space
- Internet connection for installation

## Package List

The ISO includes a minimal set of packages for a functional Hyprland desktop:

- **Core**: Base system, Linux kernel, NetworkManager, GRUB
- **Hyprland**: Compositor and Wayland utilities
- **Audio**: PipeWire audio stack
- **Apps**: Firefox, Thunar file manager
- **Terminal**: Ghostty terminal emulator
- **Utilities**: Git, Neovim, system tools

## Customization

### Changing Dotfiles Repository

Edit `archiso/airootfs/usr/local/bin/installer.sh`:
```bash
DOTFILES_REPO="https://github.com/jakeb-grant/dotfiles.git"
```

### Adding Packages

Edit `archiso/packages.x86_64` to add packages to the ISO.

### Modifying Installer

The installer script is at `archiso/airootfs/usr/local/bin/installer.sh`.

## Troubleshooting

### Network Issues During Installation
- Try manual configuration with `iwctl` for WiFi
- Use `nmtui` for NetworkManager TUI

### GRUB Not Installing
- Ensure system is booted in UEFI mode
- Check `/sys/firmware/efi/efivars` exists

### Dotfiles Not Applied
- Manually run: `chezmoi init --apply <repo-url>`
- Check GitHub repository accessibility

## Contributing

Pull requests welcome! Please test ISO builds before submitting.

## License

MIT

## Credits

- [Hyprland](https://hyprland.org/) - Wayland compositor
- [Gum](https://github.com/charmbracelet/gum) - TUI components
- [Chezmoi](https://www.chezmoi.io/) - Dotfile manager
- [Arch Linux](https://archlinux.org/) - Base distribution