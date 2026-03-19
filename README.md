# Hyprland Dotfiles

Chezmoi-managed dotfiles for my Hyprland desktop environment.

## Preview

<!-- TODO: Add screenshot -->
![Desktop screenshot](screenshots/desktop.png)

## Features

- **Window Manager**: Hyprland
- **Desktop Shell**: Quickshell (bar, launcher, notifications, lock screen — replaces waybar + swaync + hyprlock; uses hyprlock's PAM config for authentication)
- **Terminal**: Ghostty
- **Editor**: Zed with hand-crafted themes per palette
- **File Manager**: Yazi (terminal, themed)
- **System Monitor**: btop
- **Theme System**: Palette-based runtime theme switching across all apps
- **GTK Theming**: libadwaita color overrides for GTK3/GTK4 apps
- **Boot Theming**: GRUB and SDDM login screen

## Getting Started

```bash
# 1. Initialize and apply dotfiles
chezmoi init --apply https://github.com/jakeb-grant/dotfiles.git

# 2. Restart your shell (or log out and back in)
exec bash

# 3. Apply a theme
theme-switch everforest
```

## Installation

### Quick Start

```bash
chezmoi init --apply https://github.com/jakeb-grant/dotfiles.git
```

### Safe Installation (Preserving Existing Configs)

Chezmoi will overwrite managed files. To preview changes first:

```bash
# Clone without applying
chezmoi init https://github.com/jakeb-grant/dotfiles.git

# Preview what would change
chezmoi diff

# Apply when ready
chezmoi apply
```

### Dependencies

These dotfiles are designed for [arch-quickstart](https://github.com/jakeb-grant/arch-quickstart), which provides a custom Arch ISO with all required packages pre-installed.

## What's Included

```
dot_config/
├── hypr/               # Hyprland window manager + hypridle
├── quickshell/         # Desktop shell (bar, launcher, notifications, lock screen)
├── ghostty/            # Terminal emulator
├── zed/                # Zed editor settings + hand-crafted themes
├── yazi/               # Yazi file manager theme
├── btop/               # System monitor theme
├── phylax/             # Desktop widget styling
├── gtk-3.0/            # GTK3 color overrides
├── gtk-4.0/            # GTK4/libadwaita color overrides
├── grub/               # GRUB bootloader theme
├── sddm-theme/         # SDDM login screen theme
├── palette/            # Theme palette definitions (JSON)
├── theme-templates/    # Jinja2 theme templates
└── wallpapers/         # Per-theme wallpapers
dot_local/bin/
├── theme-switch        # Theme switching utility
└── win-vm              # Windows VM management
```

## Theme System

Palette JSONs are the single source of truth. `theme-switch` applies them across all apps via two methods:

**Templated apps** (Jinja2 → chezmoi pipeline):
```
Palette JSON              Theme Template                  Chezmoi Template           Final Config
(everforest.json) --->   (style.css.theme)      --->    (style.css.tmpl)     ---> (style.css)
                          theme-switch                    chezmoi apply
```
Used by: Hyprland, GTK3/4, Phylax, Yazi, Zed settings

**Direct-write apps** (built-in theme selection):
```
Palette JSON              theme-switch                    Final Config
(everforest.json) --->   reads _ghostty_theme   --->    writes theme = Everforest Dark Hard
```
Used by: Ghostty (`_ghostty_theme`), Zed (`_zed_theme_dark`/`_zed_theme_light`), btop (`_btop_theme`)

**Quickshell** watches `active.json` directly for live animated transitions — no restart needed.

### How It Works

1. **Palette files** (`dot_config/palette/*.json`) define color roles using Catppuccin-style naming
2. **`theme-switch`** copies active palette, processes Jinja2 templates, updates direct-write apps
3. **`chezmoi apply`** processes machine-specific variables (GPU config, hostname)
4. **Quickshell** detects `active.json` change and animates to new colors instantly

### Available Palettes

| Palette | Variant |
|---------|---------|
| Catppuccin Mocha | dark |
| Catppuccin Frappé | dark |
| Catppuccin Macchiato | dark |
| Catppuccin Latte | light |
| Rosé Pine | dark |
| Rosé Pine Moon | dark |
| Rosé Pine Dawn | light |
| Everforest | dark |
| Everforest Light | light |
| Nord | dark |

### Template Syntax

Theme variables (processed by `theme-switch`):
```
{< crust >}                           # Direct color value
{< crust | rgba(0.95) >}             # With filter and opacity
{< surface0 | hypr_rgba(0.93) >}     # Hyprland format
```

Chezmoi variables (processed by `chezmoi apply`):
```
{{ .graphics }}                       # Machine-specific data
{{ if eq .graphics "nvidia" }}...{{ end }}
```

### Available Filters

| Filter | Output Example |
|--------|----------------|
| `hex` | `#3ddbd9` |
| `hex_alpha(0.9)` | `#3ddbd9e6` |
| `rgb` | `rgb(61, 219, 217)` |
| `rgba(0.9)` | `rgba(61, 219, 217, 0.90)` |
| `rgb_values` | `61, 219, 217` |
| `hypr_rgb` | `rgb(3ddbd9)` |
| `hypr_rgba(0.9)` | `rgba(3ddbd9e6)` |
| `strip` | `3ddbd9` |

### Usage

```bash
# Switch theme (updates palette, processes templates, applies chezmoi, reloads apps)
theme-switch everforest
```

## Machine-Specific Configuration

On first run, chezmoi prompts for machine-specific settings stored in `~/.config/chezmoi/chezmoi.toml`:

| Variable | Options | Description |
|----------|---------|-------------|
| `graphics` | `amd`, `prime`, `nvidia` | GPU driver configuration |
| `igpu_pci` | PCI ID (auto-detected) | Integrated GPU — only prompted for `prime` |
| `dgpu_pci` | PCI ID (auto-detected) | Discrete GPU — only prompted for `prime` |

To change settings:
```bash
chezmoi edit-config
chezmoi apply
```

## License

MIT
