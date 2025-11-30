# Hyprland Dotfiles

Chezmoi-managed dotfiles for a minimal Hyprland desktop environment.

## Features

- **Window Manager**: Hyprland with vim-style keybindings
- **Status Bar**: Waybar with system monitoring
- **Launcher**: Rofi for application launching
- **Notifications**: Mako notification daemon
- **Shell**: Bash with custom aliases and functions
- **Theme System**: Runtime theme switching with template support

## Quick Start

```bash
chezmoi init --apply https://github.com/jakeb-grant/dotfiles.git
```

## What's Included

```
dot_bashrc              # Shell configuration
dot_config/
├── hypr/               # Hyprland window manager
├── waybar/             # Status bar
├── themes/             # Theme definitions
└── theme-templates/    # Theme template files
dot_local/
└── bin/theme-switch    # Theme switching utility
```

## Keybindings

| Key | Action |
|-----|--------|
| `Super + Return` | Terminal (Ghostty) |
| `Super + Shift + Return` | Editor (Zed) |
| `Super + D` | Application launcher |
| `Super + E` | File manager |
| `Super + Q` | Close window |
| `Super + V` | Toggle floating |
| `Super + L` | Lock screen |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move to workspace |
| `Print` | Screenshot (full) |
| `Shift + Print` | Screenshot (selection) |
| `Super + Shift + V` | Clipboard history |
| `Super + Shift + C` | Color picker |

## Theme System

Switch themes at runtime:

```bash
theme-switch carbonfox
```

Themes are defined in `~/.config/themes/` and templates in `~/.config/theme-templates/`.

## Customization

After applying, edit configs with:

```bash
chezmoi edit ~/.config/hypr/hyprland.conf
chezmoi apply
```

## License

MIT
