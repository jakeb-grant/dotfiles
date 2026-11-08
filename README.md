# Hyprland Dotfiles

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Chezmoi-managed dotfiles for my Hyprland desktop. A palette-driven theme system wires one JSON into every app (Hyprland, Strand, GTK, Qt, Kitty, Zed, Yazi, btop, Obsidian), so switching from Everforest to Catppuccin is a single command, and the shell animates to the new colours.

## Features

- **Window Manager**: Hyprland
- **Desktop Shell**: [Strand](https://strand.jacobgrant.dev) (island bar, launcher, notifications, lock screen, polkit password prompt, wallpaper picker, screen recording; hyprlock is the fallback locker)
- **Terminal**: Kitty (its drag-and-drop protocol lets Yazi drag files in and out)
- **Editor**: Zed with hand-crafted themes per palette
- **File Manager**: Yazi, in Kitty (Super+Shift+F)
- **System Monitor**: btop
- **Theme System**: Palette-based runtime theme switching across all apps
- **GTK Theming**: libadwaita color names for GTK4 apps, and the same for GTK3 apps through the adw-gtk3 theme
- **Qt Theming**: Qt5 apps (VLC) through qt5ct, Fusion coloured from the palette
- **Monitors and Thunderbolt**: Strand, named monitor profiles with their workspaces, several a set and one its default (`monitors.toml`; it writes `monitors.lua`), and bolt's devices allowed from the launcher
- **Login Manager**: greetd + tuigreet

## Installation

```bash
chezmoi init --apply https://github.com/jakeb-grant/dotfiles.git
exec bash                  # or log out and back in
theme-switch everforest
```

chezmoi overwrites the files it manages. To see what would change first, run `chezmoi init` with the same URL, then `chezmoi diff`, then `chezmoi apply`.

### Dependencies

These dotfiles are built for [arch-quickstart](https://github.com/jakeb-grant/arch-quickstart), a custom Arch ISO, but its package lists predate Strand and Kitty. Until they catch up, the configs and scripts also need:

- **Strand**, the shell: `curl -fsSL https://strand.jacobgrant.dev/install.sh | sh -s -- --edge`. Edge, because these configs track Strand's main branch (`monitors.strand` needs `d9d726f4` or later).
- **Apps**: `kitty`, `yazi`, `zed`, `btop`, and `1password` (AUR), whose SSH agent `private_1Password/` configures
- **Desktop**: `awww` (wallpapers), `bolt` (Thunderbolt; with `jq` and `glib2`'s `gdbus` for `bolt-devices`), `hypridle`, `hyprlock`, `phinger-cursors` (AUR), `adw-gtk-theme` (the GTK3 base that `theme-switch` sets and `gtk-3.0/gtk.css` recolours), `qt5ct`
- **Shell features**: `wf-recorder` (screen recording), `libqalculate` (the launcher's sums), `grim`, `slurp` and `wl-clipboard` (screenshots), `hyprpicker`
- **Scripts**: `uv` (`theme-switch` and `wallpaper-upscale` run as `uv run --script`), `jq` and ImageMagick (`wallpaper-split`), `acl` (`setfacl`, for the Chromium policy script); `fzf` and `fnm` are used by `.bashrc` when present
- **Login**: `greetd`, `greetd-tuigreet` and a `greeter` user; the greetd setup script writes `/etc/greetd/config.toml` pointing at them and at `start-hyprland`, which ships with hyprland

Install notes:

- The `run_once` setup scripts (greetd, Chromium policies, retiring hyprpier) and the `run_onchange` scripts for the Thunderbolt resume service, the IPU7 camera relay (on machines with that camera; it also needs `v4l2-relayd` from the AUR) and GPU symlinks (on `prime` machines) need interactive sudo — a fully unattended `chezmoi init --apply` will stop and prompt.
- The greetd script heredocs its config straight into `/etc`, so later out-of-band edits there are invisible to `chezmoi diff` — accepted trade-off for a personal repo; the script is the source of truth.
- chezmoi only manages the `.obsidian` theme files inside the `~/knowledge` Obsidian vault, so an install that applies before the vault is cloned (arch-quickstart does, in the chroot) leaves a bare `~/knowledge/.obsidian`, and `git clone` then refuses the non-empty directory. Clone into it instead: `git -C ~/knowledge init && git -C ~/knowledge remote add origin https://github.com/jakeb-grant/knowledge.git && git -C ~/knowledge fetch && git -C ~/knowledge checkout -f main`, then `chezmoi apply` to put the theme back.

## What's Included

```
dot_config/
├── hypr/               # Hyprland window manager + hypridle + hyprlock (fallback)
├── strand/             # Desktop shell (Strand)
│   ├── island.strand       # The island: workspaces, status, clock, OSD, polkit prompt
│   ├── launcher.strand     # Launcher: apps, Wi-Fi, Bluetooth, sound, themes, wallpapers, power…
│   ├── lock.strand         # Lock screen (answers loginctl lock-session)
│   ├── notify.strand       # Notification server
│   └── record.strand       # Screen recording (wf-recorder)
├── kitty/              # Terminal emulator + a colour theme per palette; launch-actions
│                       #   opens folders handed to it (the system folder handler) in Yazi
├── zed/                # Zed editor settings + hand-crafted themes
├── yazi/               # Yazi file manager theme
├── btop/               # System monitor theme
├── gtk-3.0/            # GTK3 color overrides
├── gtk-4.0/            # GTK4/libadwaita color overrides
├── qt5ct/              # Qt5 apps (VLC): Fusion, coloured from the palette
├── age/                # age recipients (public key) — ~/knowledge's git clean
│                       #   filter encrypts personal/finance/** to this key
│                       #   (decrypt side reads the private key from 1Password)
├── private_1Password/  # 1Password SSH agent config (serves keys from the Developer vault)
├── windows-vm/         # Windows VM (docker-compose)
├── wireplumber/        # Hides the IPU7 raw camera nodes (see run_onchange_after_setup-ipu7-camera)
├── palette/            # Theme palette definitions (JSON)
└── wallpapers/         # Flat image pool + wallpapers.json config
knowledge/
└── dot_obsidian/           # Obsidian vault theme (~/knowledge/ must be the vault)
    ├── appearance.json     # Selects "Palette" theme
    └── themes/Palette/     # Theme CSS template + manifest
dot_local/share/applications/
└── win-vm.desktop      # "Windows VM" in the launcher
dot_local/bin/
├── ipu7-camera-check   # Check the IPU7 camera relay end to end
├── screenshot          # Capture (region/full) + clipboard + notification
├── term                # Kitty's single instance; Strand's launcher runs terminal apps through it
├── theme-switch        # Theme switching utility
├── wallpaper-split     # Split wide/panoramic images into per-monitor sets
├── wallpaper-upscale   # AI upscale images using EDSR 4x (CPU)
└── win-vm              # Windows VM management
dot_bashrc              # Shell config (PATH, Zed as $EDITOR, history, fzf, y for Yazi, fnm)
dot_claude/             # Claude Code config (writing skills)
.chezmoitemplates/      # Colour helpers, GTK's shared colour block, the IPU7 camera's /etc files
run_*                   # Setup scripts: greetd, Chromium policies, GPU symlinks, IPU7 camera
```

## Theme System

Palette JSONs are the single source of truth. `theme-switch` applies them across all apps in four ways:

**Templated apps** (chezmoi templates reading the active palette):
```
Palette JSON              active.json                     Chezmoi Template            Final Config
(everforest.json) --->   written by theme-switch --->   (style.css.tmpl reads  ---> (style.css)
                                                          active.json) chezmoi apply
```
Used by: GTK3/4, Qt5 (qt5ct), Kitty, Yazi, Zed settings, Obsidian, hyprlock, btop. btop gets a single templated theme (`palette.theme`) that always matches the active palette; its config points at it statically.

**Direct-write apps** (config written by theme-switch itself):
```
Palette JSON              theme-switch                         Final Config
(everforest.json) --->   reads base and _variant      --->    writes a managed policy JSON
```
Used by: Chromium/Chrome (managed color policy) and GTK (gsettings). (Zed theme selection is templated via the `_zed_theme` meta key; theme-switch syncs Zed's settings in place before apply so its inode-level hot-reload watch survives.)

**Lua-required (Hyprland)**:
```
active.json               palette.lua.tmpl                hyprland.lua
(written by       --->   renders palette.lua    --->     local p = require("palette") ---> p.surface0_rgba(0.93)
 theme-switch)
```
`hyprland.lua` requires `palette.lua` (a chezmoi template like the rest) and reads role-helpers like `p.surface0_rgba(0.93)`.

**Strand** reads `active.json` through a `from file` service and springs to the new colours — no restart needed.

### How It Works

1. **Palette files** (`dot_config/palette/*.json`) define color roles using Catppuccin-style naming
2. **`theme-switch`** writes `active.json` (palette + derived `_slug`, `_accent*` and `_on_accent` keys), updates direct-write apps
3. **`chezmoi apply`** renders themed `.tmpl` configs from `active.json` and machine-specific variables (GPU config)
4. **Strand** sees the `active.json` change and animates to the new colours instantly

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

Theme colors (chezmoi Go templates, rendered by `chezmoi apply`):
```
{{- $p := include "dot_config/palette/active.json" | fromJson -}}
{{ $p.crust }}                              # Direct color value: #11111b
{{ template "rgba" (list $p.crust 0.95) }}  # CSS rgba with opacity
{{ template "hypr_rgba" (list $p.surface0 0.93) }}  # Hyprland format (hyprlock)
```

Lua-side colors in `hyprland.lua.tmpl` (via `palette.lua`):
```lua
local p = require("palette")
p.surface0_rgba(0.93)                 -- "rgba(313244ed)"
p.crust_rgb()                         -- "rgb(11111b)"
```

Chezmoi variables (Go templates, processed by `chezmoi apply`):
```
{{ .graphics }}                       # Machine-specific data
{{ if eq .graphics "nvidia" }}...{{ end }}
```

### Color Helpers (`.chezmoitemplates/`)

| Helper | Output Example |
|--------|----------------|
| `rgba` (color, opacity) | `rgba(61, 219, 217, 0.90)` |
| `rgb_values` (color) | `61, 219, 217` |
| `hypr_rgb` (color) | `rgb(3ddbd9)` |
| `hypr_rgba` (color, opacity) | `rgba(3ddbd9e5)` |

### Usage

```bash
theme-switch everforest    # switch (updates active.json, applies chezmoi, reloads apps)
theme-switch               # apply the theme in use again
theme-switch --list        # the themes
```

## Wallpaper System

Wallpapers live in a flat directory (`~/.config/wallpapers/`) with a `wallpapers.json` config that defines singles and sets with palette assignments.

```json
{
  "wallpapers": [
    { "file": "forest.jpg", "palettes": ["everforest*"] },
    { "file": "sunset.jpg", "palettes": ["*"] }
  ],
  "sets": [
    {
      "name": "Cyberpunk",
      "images": ["cyberpunk-1.png", "cyberpunk-2.png", "cyberpunk-3.png"],
      "palettes": ["catppuccin*"]
    }
  ],
  "defaults": [
    { "palettes": ["everforest*"], "file": "forest.jpg" },
    { "palettes": ["*"], "file": "sunset.jpg" }
  ]
}
```

- **Singles** apply one image across all monitors
- **Sets** assign images to monitors left-to-right, cycling with modulo if there are fewer images than monitors
- **Palettes** supports exact names (`catppuccin-mocha`), globs (`catppuccin*`), or `*` for all themes
- **Defaults** name the wallpaper (its file, or a set's name) a theme switch falls back to: one listing the theme by exact name wins, then a trailing glob (`everforest*`), then `*`
- The launcher's Wallpapers page lists those suited to the theme in use and puts one up with awww; after a theme switch it keeps the wallpaper if it suits the new theme, else puts up the theme's default
- Strand reads `wallpapers.json` live; `awww-daemon` restores the last images at login

### Wallpaper Tools

```bash
# Split panoramic images into per-monitor sets (default: 3 monitors, jpg)
wallpaper-split ~/Downloads/panoramas/ --palettes "catppuccin*,rose-pine*"

# AI upscale images using EDSR 4x (CPU-only, tiled processing)
wallpaper-upscale ~/Downloads/lowres/ -o ~/Downloads/upscaled/
```

## Machine-Specific Configuration

On first run, chezmoi prompts for machine-specific settings stored in `~/.config/chezmoi/chezmoi.toml`:

| Variable | Options | Description |
|----------|---------|-------------|
| `graphics` | `amd`, `intel`, `prime`, `nvidia` | GPU driver configuration |
| `igpu_pci` | PCI ID (auto-detected) | Integrated GPU — only prompted for `prime` |
| `dgpu_pci` | PCI ID (auto-detected) | Discrete GPU — only prompted for `prime` |

To change settings:
```bash
chezmoi edit-config
chezmoi apply
```

## License

MIT
