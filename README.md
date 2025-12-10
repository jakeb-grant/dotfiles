# Hyprland Dotfiles

Chezmoi-managed dotfiles for a minimal Hyprland desktop environment.

## Features

- **Window Manager**: Hyprland
- **Status Bar**: Waybar with system monitoring, update checker, rebuild detector
- **Notifications**: SwayNC notification center with quick actions
- **Launcher**: Walker with custom menus (apps, packages, keybinds, clipboard, calculator)
- **Terminal**: Ghostty with themed colors
- **Editor**: Zed with theme integration
- **File Manager**: Nautilus (GTK themed), Yazi (terminal)
- **Theme System**: Runtime theme switching with Jinja2 templates
- **GTK Theming**: libadwaita color overrides for GTK3/GTK4 apps

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

- hyprland, waybar, swaync, walker, elephant, ghostty
- zed, nautilus, yazi
- grim, slurp, wl-copy, hyprpicker (screenshots)
- hyprlock (lock screen)

## What's Included

```
dot_config/
├── hypr/               # Hyprland window manager
├── waybar/             # Status bar
├── swaync/             # Notification center
├── walker/             # Application launcher
├── ghostty/            # Terminal emulator
├── zed/                # Zed editor settings
├── yazi/               # Yazi file manager theme
├── gtk-3.0/            # GTK3 color overrides
├── gtk-4.0/            # GTK4/libadwaita color overrides
├── elephant/           # Walker backend & custom menus
│   └── menus/          # Main menu, keybinds menu
├── themes/             # Theme definitions (JSON)
└── theme-templates/    # Jinja2 theme templates
dot_local/bin/
├── theme-switch        # Theme switching utility
├── waybar-updates      # Package update checker
└── waybar-rebuild      # Go plugin rebuild detector
```

## Keybindings

### Applications
| Key | Action |
|-----|--------|
| `Super + Space` | Main menu (Walker) |
| `Super + Return` | Terminal (Ghostty) |
| `Super + Shift + B` | Browser |
| `Super + Shift + F` | File manager (Nautilus) |
| `Super + Shift + Z` | Editor (Zed) |
| `Super + Ctrl + V` | Clipboard history |
| `Super + I` | Package search (AUR + repos) |

### Window Management
| Key | Action |
|-----|--------|
| `Super + W` | Close window |
| `Super + T` | Toggle floating |
| `Super + F` | Fullscreen |
| `Super + O` | Pin window (sticky) |
| `Super + L` | Lock screen |
| `Super + Shift + Arrow` | Swap window |
| `Super + =/-` | Resize width |
| `Super + Shift + =/-` | Resize height |

### Workspaces
| Key | Action |
|-----|--------|
| `Super + 1-0` | Switch workspace |
| `Super + Shift + 1-0` | Move to workspace |
| `Super + Tab` | Next workspace |
| `Super + Shift + Tab` | Previous workspace |
| `Super + Ctrl + Tab` | Last workspace |
| `Super + S` | Scratchpad |
| `Super + Shift + S` | Move to scratchpad |

### Notifications
| Key | Action |
|-----|--------|
| `Super + ,` | Dismiss notification |
| `Super + Shift + ,` | Dismiss all |
| `Super + Ctrl + ,` | Toggle DND |
| `Super + Alt + ,` | Toggle panel |

### Screenshots
| Key | Action |
|-----|--------|
| `Print` | Screenshot area to clipboard |
| `Shift + Print` | Screenshot full screen |
| `Super + Print` | Color picker |

### Other
| Key | Action |
|-----|--------|
| `Super + Shift + Space` | Toggle waybar |

## Theme System

The theme system uses Jinja2 templates with custom delimiters to avoid conflicts with chezmoi:

```
Theme JSON              Theme Template                  Chezmoi Template           Final Config
(everforest.json) --->  (style.css.theme)      --->    (style.css.tmpl)     ---> (style.css)
                        theme-switch                    chezmoi apply
```

### How It Works

1. **Theme files** (`dot_config/themes/*.json`) define color palettes
2. **Theme templates** (`dot_config/theme-templates/`) use `{< variable >}` syntax
3. **`theme-switch`** processes templates, outputs `.tmpl` files, reloads apps
4. **`chezmoi apply`** processes machine-specific variables

### Template Syntax

Theme variables (processed by `theme-switch`):
```
{< background >}                      # Direct color value
{< background | rgba(0.95) >}         # With filter and opacity
{< primary | hypr_rgba(0.93) >}       # Hyprland format
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
# Switch theme (processes templates, applies chezmoi, reloads apps)
theme-switch everforest
```

## Machine-Specific Configuration

On first run, chezmoi prompts for machine-specific settings stored in `~/.config/chezmoi/chezmoi.toml`:

| Variable | Options | Description |
|----------|---------|-------------|
| `graphics` | `amd`, `nvidia`, `nvidia-prime` | GPU driver configuration |

To change settings:
```bash
chezmoi edit-config
chezmoi apply
```

## Customization

After applying, edit configs with:

```bash
chezmoi edit ~/.config/hypr/hyprland.conf
chezmoi apply
```

## License

MIT
