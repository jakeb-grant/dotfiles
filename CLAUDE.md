# Chezmoi Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Theme System — Palette as Single Source of Truth

Palette JSONs in `dot_config/palette/` are the single source of truth for all theme colors.

```
Palette JSON          theme-switch              Chezmoi Template            Final Config
(palette/*.json) --> writes active.json    --> (*.tmpl reads active.json) --> (~/.config/...)
                     (Strand instant)          [Go: {{ }}] chezmoi apply
```

`theme-switch <name>` copies the palette to `active.json` (plus derived keys: `_accent` and its HSL as `_accent_h/_s/_l`), then runs `chezmoi apply` on the themed targets. Themed configs are chezmoi templates that read the palette at apply time — the `.tmpl` starts with `{{- $p := include "dot_config/palette/active.json" | fromJson -}}` and uses `{{ $p.<role> }}` plus color helpers from `.chezmoitemplates/`:

- `{{ template "hypr_rgb" $p.base }}` → `rgb(1e1e2e)` (hyprlang)
- `{{ template "hypr_rgba" (list $p.base 0.8) }}` → `rgba(1e1e2ecb)` (hyprlang)
- `{{ template "rgba" (list $p.crust 0.5) }}` → `rgba(17, 17, 27, 0.50)` (CSS)
- `{{ template "rgb_values" $p.red }}` → `243, 139, 168` (CSS custom props)

Templated this way: gtk-3.0, gtk-4.0, kitty (`kitty.conf.tmpl` includes `themes/<_kitty_theme>.conf`, one per palette, converted from the Ghostty built-in theme each palette used before the move to Kitty; opacity is `_blur_opacity`, tabs and split borders take palette roles), zed `settings.json`, yazi, hyprlock, obsidian (`knowledge/dot_obsidian/themes/Palette/theme.css.tmpl` → `~/knowledge/.obsidian/...`), btop (`btop/themes/palette.theme.tmpl` — a single templated theme file; `color_theme = "palette"` is static in `btop.conf`), and pane-fm (`pane-fm/themes/palette.css.tmpl`, plus `config.toml.tmpl` for the variant-driven `light_icons`; `theme = "palette"` is static).

Some apps have their config direct-written by `theme-switch` rather than fully templated — precise updates to specific keys, not full-file substitution:
- **Chromium/Chrome**: `_chromium_seed_color` + `_variant` → writes a managed policy JSON under `/etc/chromium/policies/managed/` (and the Chrome equivalent).
- **GTK**: `_variant` → gsettings `gtk-theme` (`adw-gtk3` or `adw-gtk3-dark`), `_gtk_color_scheme` → `color-scheme`. GTK3's built-in Adwaita ignores the libadwaita `@define-color` names; adw-gtk3 reads them, so `gtk-3.0/gtk.css.tmpl` and `gtk-4.0/gtk.css.tmpl` carry the same colour block (accent = `_accent`, shades libadwaita's own by `_variant`). gtk-4.0 adds one `:root` line because adw-gtk3's GTK4 tweaks pin plain GTK4 apps to GNOME blue. Restyle through those names, not per-widget selectors.

Zed's template substitutes the `_zed_theme_dark`/`_zed_theme_light`/`_variant` meta keys into `settings.json`, with per-palette Zed theme JSON in `dot_config/zed/themes/` (Zed themes stay hand-made — per-role alpha nuance earns it).

Two targets are hot-reloaded by their apps via inotify watches on the file's *inode* — Zed `settings.json` and pane-fm `themes/palette.css`. chezmoi applies by atomic rename, which replaces the inode and kills such watches, so `theme-switch` renders these via `chezmoi cat` and syncs them in place *before* apply (apply then sees no diff and never touches them). The list lives in `INODE_WATCHED_TARGETS` in theme-switch.

**Hyprland** uses a Lua-require pattern (`hl.config({...})` API, 0.55+). `theme-switch` generates `dot_config/hypr/palette.lua` — a Lua module exposing role helpers like `p.surface0_rgba(0.93)`, for the 26 roles plus the derived accent as `accent` (window borders use it). `dot_config/hypr/hyprland.lua.tmpl` does `local p = require("palette")`, so it carries no palette tokens itself; its `{{ }}` blocks are real Go template conditionals for machine-specific GPU config. `hyprlock` (the fallback locker) stays on hyprlang, themed like the other `.tmpl` configs; `hypridle` is a plain config with no templating.

### Palette Definitions (`dot_config/palette/`)

Catppuccin-style JSON files with named color roles:
- `everforest.json`, `catppuccin-mocha.json`, `rose-pine.json`, etc.
- `active.json` — copy of current theme written by theme-switch (watched by Strand for live updates; committed so fresh clones apply cleanly). Also carries derived `_accent*` keys — palette files themselves don't define them.

### Chezmoi Templates

All `.tmpl` files are hand-edited sources (nothing generates them). Themed ones read `active.json` as described above; others use standard chezmoi variables for machine-specific config (GPU drivers). The only generated theme artifact is `dot_config/hypr/palette.lua`, rewritten by each theme-switch run.

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

Strand (https://strand.jacobgrant.dev) provides the island bar, launcher, notifications, lock screen and polkit password prompt: `dot_config/strand/*.strand`, started by `strand run` in Hyprland's autostart and bound with `strand toggle <file>.<key>`. A saved `.strand` file hot-reloads the running shell, so test a change on a copy (`strand check <dir>`) before `chezmoi apply`. Its feature list and parked Strand problems are in `docs/strand-shell/`.

Locking is Strand's (`lock.strand`): everything locks through `loginctl lock-session`, and Strand answers logind's request. hypridle starts hyprlock only while no `strand` process is running. Recovering from a lock screen that died is in `dot_config/hypr/README.md`.

Quickshell (`dot_config/quickshell/`) has not been started since the switch on 2026-11-04. Its config, the `_quickshell` palette keys and `toggle-bar-mode` stay as a rollback (it opens terminal apps in Ghostty, so Ghostty stays installed with it) until about 2026-11-11, then go. Before dropping `_quickshell`, move its `accent`: theme-switch derives `_accent` from it (and validates it, and lists it in `--list`), and the Strand launcher's theme preview reads it, all falling back to `blue` when it's missing.

## Machine-Specific Config

Variables in `.chezmoi.toml.tmpl`
