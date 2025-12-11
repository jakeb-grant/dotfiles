# Chezmoi Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Two-Tier Theme Template Architecture

This repo uses a two-tier templating system for runtime theme switching:

```
Theme JSON          Theme Template           Chezmoi Template         Final Config
(themes/*.json) --> (*.theme)           --> (*.tmpl)             --> (~/.config/...)
                    [Jinja2: {< >}]         [Go: {{ }}]
                    theme-switch            chezmoi apply
```

### Tier 1: Theme Definitions (`dot_config/themes/`)

JSON files containing color palettes and metadata:
- `everforest.json`, `violet-lake.json` - theme definitions
- `active.json` - symlink to current theme

### Tier 2: Theme Templates (`dot_config/theme-templates/`)

Jinja2 templates with custom delimiters `{< >}` that reference theme colors:
```css
background: {< background | rgba(0.9) >};
color: {< foreground >};
```

Available filters: `hex`, `rgba(0.9)`, `rgb`, `rgb_values`, `hypr_rgb`, `hypr_rgba(0.9)`, `strip`

### Tier 3: Chezmoi Templates (`*.tmpl`)

Standard chezmoi Go templates for machine-specific config (GPU drivers, hostname).

## Important: Editing Themed Files

If a config file has both `.theme` and `.tmpl` versions, **edit the `.theme` file** in `dot_config/theme-templates/`. The `.tmpl` file is generated and will be overwritten.

Example: To modify Waybar styles:
- Edit: `dot_config/theme-templates/waybar/style.css.theme`
- Not: `dot_config/waybar/style.css.tmpl` (generated)

## Key Commands

```bash
# Switch themes (regenerates .tmpl files and applies)
theme-switch <theme-name>

# Apply chezmoi changes
chezmoi apply

# Preview changes
chezmoi diff
```

## Walker/Elephant Menus

Custom menus are in `dot_config/elephant/menus/`. To view provider documentation and available options:

```bash
elephant generatedoc
```

For Lua menus, use global `Action` with `%VALUE%` substitution rather than per-entry `Actions = { ["open"] = "..." }` (reserved for submenus).

## Machine-Specific Config

Variables in `.chezmoi.toml.tmpl`:
- `graphics`: GPU driver (amd, nvidia, nvidia-prime)
- `hostname`: machine hostname
- `name`, `email`: user identity
