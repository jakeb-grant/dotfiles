# Hyprland Dotfiles

Chezmoi-managed dotfiles for a minimal Hyprland desktop environment.

## Features

- **Window Manager**: Hyprland
- **Status Bar**: Waybar with system monitoring
- **Theme System**: Runtime theme switching with template support

## Installation

### Quick Start

```bash
chezmoi init --apply https://github.com/jakeb-grant/dotfiles.git
```

### Safe Installation (Preserving Existing Configs)

Chezmoi will overwrite managed files (`~/.config/hypr/`, `~/.config/waybar/`, etc.). To preview changes first:

```bash
# Clone without applying
chezmoi init https://github.com/jakeb-grant/dotfiles.git

# Preview what would change
chezmoi diff

# Apply when ready
chezmoi apply
```

## What's Included

```
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
| `Super + Shift + Return` | Editor (Zeditor) |
| `Super + D` | Application launcher (Walker) |
| `Super + E` | File manager (Nautilus) |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + V` | Toggle floating |
| `Super + S` | Scratchpad |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move to workspace |
| `Print` | Screenshot (selection) |
| `Shift + Print` | Screenshot (full) |

## Theme System

The theme system uses a two-stage template process that integrates with chezmoi:

```
Theme File              Theme Template                  Chezmoi Template           Final Config
(carbonfox.conf)  --->  (hyprland.conf.theme)  --->    (hyprland.conf.tmpl)  ---> (hyprland.conf)
                        theme-switch                    chezmoi apply
```

### How It Works

1. **Theme files** (`dot_config/themes/*.conf`) define color palettes and semantic mappings
2. **Theme templates** (`dot_config/theme-templates/`) contain `{{UPPERCASE_VARS}}` for colors
3. **`theme-switch`** processes theme variables, outputs `.tmpl` files to chezmoi source
4. **`chezmoi apply`** processes machine-specific variables (e.g., `{{ .graphics }}`)

### Template Syntax

Theme variables (processed by `theme-switch`):
```
{{WM_BORDER_ACTIVE_COLOR}}                    # Simple replacement
{{WM_BORDER_ACTIVE_COLOR:hypr_rgba}}          # With format conversion
{{WM_BORDER_ACTIVE_COLOR:hypr_rgba:OPACITY}}  # With format and opacity
```

Chezmoi variables (processed by `chezmoi apply`):
```
{{ .graphics }}                               # Machine-specific data
{{ if eq .graphics "nvidia" }}...{{ end }}    # Conditionals
```

**Convention**: Theme variables are `UPPERCASE`, chezmoi uses lowercase/dots.

### Available Color Formats

| Format | Output Example |
|--------|----------------|
| `hex` | `#3ddbd9` |
| `hex_alpha` | `#3ddbd9ee` |
| `hypr_rgb` | `rgb(3ddbd9)` |
| `hypr_rgba` | `rgba(3ddbd9ee)` |
| `css_rgb` | `rgb(61, 219, 217)` |
| `css_rgba` | `rgba(61, 219, 217, 0.93)` |
| `rgb_only` | `61, 219, 217` |

### Usage

```bash
# Switch theme (regenerates .tmpl files in chezmoi source)
theme-switch carbonfox

# Apply to system (processes machine-specific templates)
chezmoi apply
```

## Machine-Specific Configuration

On first run, chezmoi prompts for machine-specific settings stored in `~/.config/chezmoi/chezmoi.toml`:

| Variable | Options | Description |
|----------|---------|-------------|
| `graphics` | `amd`, `nvidia`, `nvidia-prime` | GPU driver configuration |

These values are used in templates for conditional configuration (e.g., NVIDIA environment variables are only included when `graphics` is set to `nvidia` or `nvidia-prime`).

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
