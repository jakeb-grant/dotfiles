#!/bin/bash
# Generate .tmpl files from .theme templates on first chezmoi apply.
# These are gitignored build artifacts that theme-switch normally creates.
# On a fresh clone they don't exist, so chezmoi has nothing to apply.

CHEZMOI_SOURCE="$(chezmoi source-path)"
THEME_SWITCH="$CHEZMOI_SOURCE/dot_local/bin/executable_theme-switch"
DEFAULT_THEME="catppuccin-mocha"

if [ ! -f "$THEME_SWITCH" ]; then
    echo "Warning: theme-switch not found, skipping template generation"
    exit 0
fi

if ! command -v uv >/dev/null 2>&1; then
    echo "Warning: uv not found, cannot generate templates. Install uv then run: theme-switch $DEFAULT_THEME"
    exit 0
fi

# Only generate templates — run theme-switch's Python directly with a flag
# to skip app reloads and recursive chezmoi apply.
# We use a minimal inline script that imports just the template processing.
uv run --quiet --script - <<'PYTHON'
# /// script
# requires-python = ">=3.11"
# dependencies = ["jinja2"]
# ///
import json, sys
from pathlib import Path

# Reuse theme-switch's paths
src = Path.home() / ".local/share/chezmoi/dot_config"
palette_dir = src / "palette"
template_dir = src / "theme-templates"
theme = "catppuccin-mocha"

# Load palette
palette_file = palette_dir / f"{theme}.json"
if not palette_file.exists():
    print(f"Warning: palette {theme} not found, skipping")
    sys.exit(0)
with open(palette_file) as f:
    palette = json.load(f)

# Copy to active.json in source dir
with open(palette_dir / "active.json", "w") as f:
    json.dump(palette, f, indent=2)

# Process templates (same logic as theme-switch)
from jinja2 import BaseLoader, Environment

def hex_to_rgb(c):
    h = c.lstrip("#")
    return int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)

def opacity_hex(o):
    return f"{int(o*255):02x}"

env = Environment(
    loader=BaseLoader(),
    variable_start_string="{<", variable_end_string=">}",
    block_start_string="{%<", block_end_string=">%}",
    comment_start_string="{#<", comment_end_string=">#}",
    keep_trailing_newline=True,
)
env.filters["hex"] = lambda c: f"#{c.lstrip('#')[:6]}"
env.filters["hex_alpha"] = lambda c, o=1.0: f"#{c.lstrip('#')[:6]}{opacity_hex(o)}"
env.filters["rgb"] = lambda c: "rgb(%d, %d, %d)" % hex_to_rgb(c)
env.filters["rgba"] = lambda c, o=1.0: "rgba(%d, %d, %d, %.2f)" % (*hex_to_rgb(c), o)
env.filters["rgb_values"] = lambda c: "%d, %d, %d" % hex_to_rgb(c)
env.filters["hypr_rgb"] = lambda c: f"rgb({c.lstrip('#')[:6]})"
env.filters["hypr_rgba"] = lambda c, o=1.0: f"rgba({c.lstrip('#')[:6]}{opacity_hex(o)})"
env.filters["strip"] = lambda c: c.lstrip("#")

for tf in template_dir.rglob("*.theme"):
    rel = tf.relative_to(template_dir)
    out = src / rel.with_suffix(".tmpl")
    out.parent.mkdir(parents=True, exist_ok=True)
    tmpl = env.from_string(tf.read_text())
    out.write_text(tmpl.render(**palette))
    print(f"  {rel} -> {rel.with_suffix('.tmpl')}")

print(f"Templates generated with theme: {theme}")
PYTHON
