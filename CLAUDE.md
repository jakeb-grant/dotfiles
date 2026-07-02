# Chezmoi Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Theme System — Palette as Single Source of Truth

Palette JSONs in `dot_config/palette/` are the single source of truth for all theme colors.

```
Palette JSON          theme-switch              Chezmoi Template            Final Config
(palette/*.json) --> writes active.json    --> (*.tmpl reads active.json) --> (~/.config/...)
                     (Quickshell instant)      [Go: {{ }}] chezmoi apply
```

`theme-switch <name>` copies the palette to `active.json` (plus derived keys: `_accent` and its HSL as `_accent_h/_s/_l`), then runs `chezmoi apply` on the themed targets. Themed configs are chezmoi templates that read the palette at apply time — the `.tmpl` starts with `{{- $p := include "dot_config/palette/active.json" | fromJson -}}` and uses `{{ $p.<role> }}` plus color helpers from `.chezmoitemplates/`:

- `{{ template "hypr_rgb" $p.base }}` → `rgb(1e1e2e)` (hyprlang)
- `{{ template "hypr_rgba" (list $p.base 0.8) }}` → `rgba(1e1e2ecb)` (hyprlang)
- `{{ template "rgba" (list $p.crust 0.5) }}` → `rgba(17, 17, 27, 0.50)` (CSS)
- `{{ template "rgb_values" $p.red }}` → `243, 139, 168` (CSS custom props)

Templated this way: gtk-3.0, gtk-4.0, phylax, zed `settings.json`, yazi, hyprlock, obsidian (`knowledge/dot_obsidian/themes/Palette/theme.css.tmpl` → `~/knowledge/.obsidian/...`), btop (`btop/themes/palette.theme.tmpl` — a single templated theme file; `color_theme = "palette"` is static in `btop.conf`), and pane-fm (`pane-fm/themes/palette.css.tmpl`, plus `config.toml.tmpl` for the variant-driven `light_icons`; `theme = "palette"` is static).

Some apps have their config direct-written by `theme-switch` rather than fully templated — precise updates to specific keys, not full-file substitution:
- **Ghostty**: `_ghostty_theme` → writes `theme = ...` and `background-opacity = ...` to config
- **Chromium/Chrome**: `_chromium_seed_color` + `_variant` → writes a managed policy JSON under `/etc/chromium/policies/managed/` (and the Chrome equivalent).

Zed's template substitutes the `_zed_theme_dark`/`_zed_theme_light`/`_variant` meta keys into `settings.json`, with per-palette Zed theme JSON in `dot_config/zed/themes/` (Zed themes stay hand-made — per-role alpha nuance earns it).

Two targets are hot-reloaded by their apps via inotify watches on the file's *inode* — Zed `settings.json` and pane-fm `themes/palette.css`. chezmoi applies by atomic rename, which replaces the inode and kills such watches, so `theme-switch` renders these via `chezmoi cat` and syncs them in place *before* apply (apply then sees no diff and never touches them). The list lives in `INODE_WATCHED_TARGETS` in theme-switch.

**Hyprland** uses a Lua-require pattern (`hl.config({...})` API, 0.55+). `theme-switch` generates `dot_config/hypr/palette.lua` — a Lua module exposing role helpers like `p.surface0_rgba(0.93)`. `dot_config/hypr/hyprland.lua.tmpl` does `local p = require("palette")`, so it carries no palette tokens itself; its `{{ }}` blocks are real Go template conditionals for machine-specific GPU config. `hyprlock` stays on hyprlang, themed like the other `.tmpl` configs; `hypridle` is a plain config with no templating.

### Palette Definitions (`dot_config/palette/`)

Catppuccin-style JSON files with named color roles:
- `everforest.json`, `catppuccin-mocha.json`, `rose-pine.json`, etc.
- `active.json` — copy of current theme written by theme-switch (watched by Quickshell for live updates; committed so fresh clones apply cleanly). Also carries derived `_accent*` keys — palette files themselves don't define them.

### Chezmoi Templates

All `.tmpl` files are hand-edited sources (nothing generates them). Themed ones read `active.json` as described above; others use standard chezmoi variables for machine-specific config (GPU drivers, hostname). The only generated theme artifact is `dot_config/hypr/palette.lua`, rewritten by each theme-switch run.

## Important: Editing Themed Files

Edit `.tmpl` files directly — they are the real sources. Theme colors come from the palette via `$p.<role>`; don't hardcode hex values in themed configs.

## Key Commands

```bash
# Switch themes (updates active.json, applies chezmoi, reloads apps)
theme-switch <theme-name>

# Apply chezmoi changes
chezmoi apply

# Preview changes
chezmoi diff
```

## Desktop Shell

Quickshell provides the bar, launcher, and notification center. Configs in `dot_config/quickshell/`.

## Machine-Specific Config

Variables in `.chezmoi.toml.tmpl`
