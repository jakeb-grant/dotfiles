# Zed Theme Property Guide

Schema: `https://zed.dev/schema/themes/v0.2.0.json`
Builder: `https://zed.dev/theme-builder`

## File Structure

```json
{
  "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
  "name": "Theme Family Name",
  "author": "Author",
  "themes": [
    {
      "name": "Theme Variant Name",
      "appearance": "dark" | "light",
      "style": { /* all properties below */ }
    }
  ]
}
```

All colors use 8-character hex: `#RRGGBBAA` where `AA` is the alpha channel.

## Common Alpha Values

| Hex suffix | Opacity | Typical use |
|------------|---------|-------------|
| `ff` | 100% | Solid colors (text, icons, surfaces) |
| `f3` | 95% | Elevated surfaces |
| `e6` | 90% | Primary backgrounds with slight transparency |
| `cc` | 80% | Word-level diffs |
| `c2` | 76% | Diagnostic borders (status borders) |
| `bf` | 75% | Active line background |
| `ae` | 68% | Light theme backgrounds |
| `80` | 50% | Drop targets, toolbar backgrounds |
| `66` | 40% | Search match highlights, document write highlights |
| `59` | 35% | Word-level added markers |
| `4c` | 30% | Scrollbar thumbs |
| `40` | 25% | Element selection backgrounds |
| `3d` | 24% | Player selection highlights |
| `2d` | 18% | Indent guide hover/active |
| `1b` | 11% | Indent guides |
| `1a` | 10% | Diagnostic backgrounds, status backgrounds |
| `0d` | 5% | Wrap guides |
| `00` | 0% | Fully transparent (ghost backgrounds, track backgrounds) |

---

## 1. Surfaces & Backgrounds

The background layer hierarchy from darkest to lightest (dark themes):

```
crust   --> editor.background, toolbar.background, tab.active_background
mantle  --> background, status_bar, title_bar, element.disabled
base    --> surface.background, elevated_surface, tab_bar, panel, tab.inactive
surface0 --> element.background
surface1 --> element.hover, element.selected, editor.active_line
surface2 --> element.active
```

| Property | Purpose | Linked to |
|----------|---------|-----------|
| `background` | Main window background | - |
| `background.appearance` | `"blurred"` for transparency support | - |
| `surface.background` | General surface layer | - |
| `elevated_surface.background` | Popups, modals, floating panels | Defaults to `surface.background` |
| `panel.background` | Side panels (file tree, terminal) | Defaults to `surface.background` |
| `panel.overlay_background` | Command palette, overlay panels | Defaults to `surface.background` |
| `panel.overlay_hover` | Overlay hover state | Defaults to `background` |
| `drop_target.background` | Drag-and-drop target highlight | Use ~50% alpha |

**Key:** `elevated_surface`, `panel.background`, and `panel.overlay_background` all default to `surface.background`. Change the surface and they follow.

---

## 2. Borders

| Property | Purpose | Linked to |
|----------|---------|-----------|
| `border` | Default border color | - |
| `border.variant` | Subtle/alternate border | - |
| `border.focused` | Focused element border | - |
| `border.selected` | Selected element border | - |
| `border.transparent` | Invisible spacer border | Always `#00000000` |
| `border.disabled` | Disabled element border | - |
| `panel.focused_border` | Focused panel border | Defaults to `border.focused` |
| `pane.focused_border` | Focused editor pane border | Defaults to `border.focused` |

**Key:** `panel.focused_border` and `pane.focused_border` both link to `border.focused`. Set to `null` to hide them entirely.

---

## 3. Interactive Elements

Buttons, list items, and other clickable components.

| Property | Purpose | Notes |
|----------|---------|-------|
| `element.background` | Default state | Solid color |
| `element.hover` | Hovered | One step lighter than background |
| `element.active` | Pressed/active | One step lighter than hover |
| `element.selected` | Selected | Typically same as hover |
| `element.disabled` | Disabled | Typically same as window background |

---

## 4. Ghost Elements

Same states as elements but default background is transparent. Used for sidebar items, toolbar buttons, breadcrumbs.

| Property | Purpose | Notes |
|----------|---------|-------|
| `ghost_element.background` | Default state | Always `#00000000` (transparent) |
| `ghost_element.hover` | Hovered | Same color as `element.hover` |
| `ghost_element.active` | Pressed/active | Same color as `element.active` |
| `ghost_element.selected` | Selected | Same color as `element.selected` |
| `ghost_element.disabled` | Disabled | Same color as `element.disabled` |

**Key:** Ghost hover/active/selected should match their element counterparts. Only the default state differs (transparent vs solid).

---

## 5. Text

| Property | Purpose | Palette mapping |
|----------|---------|----------------|
| `text` | Primary text | `text` |
| `text.muted` | Secondary/dimmed | `subtext0` |
| `text.placeholder` | Input placeholders | `overlay1` |
| `text.disabled` | Disabled text | `overlay1` (same as placeholder) |
| `text.accent` | Accent text (links, highlights) | Primary accent color (e.g., `blue`) |

---

## 6. Icons

Icons mirror the text group exactly:

| Property | Purpose | Should match |
|----------|---------|-------------|
| `icon` | Primary icon | `text` |
| `icon.muted` | Dimmed icon | `text.muted` |
| `icon.disabled` | Disabled icon | `text.placeholder` |
| `icon.placeholder` | Placeholder icon | `text.muted` |
| `icon.accent` | Accent icon | `text.accent` |

**Key:** `icon` values should always match their `text` counterparts.

---

## 7. Chrome / Window UI

The structural bars and tab areas.

| Property | Purpose | Typical layer |
|----------|---------|---------------|
| `status_bar.background` | Bottom status bar | `mantle` or darker |
| `title_bar.background` | Top title bar | Same as status bar |
| `title_bar.inactive_background` | Unfocused window title bar | Same or slightly darker |
| `toolbar.background` | Below tabs, above editor | `crust` (darkest) |
| `tab_bar.background` | Tab strip | `base` |
| `tab.inactive_background` | Inactive tabs | `base` |
| `tab.active_background` | Active/selected tab | `crust` (matches editor bg) |

**Key:** `tab.active_background` should match `editor.background` so the active tab visually connects to the editor content.

---

## 8. Editor

| Property | Purpose | Notes |
|----------|---------|-------|
| `editor.foreground` | Default editor text | Often `overlay0` (dimmer than `text`) |
| `editor.background` | Editor pane background | Darkest layer (`crust`) |
| `editor.gutter.background` | Line number column | Should match `editor.background` |
| `editor.subheader.background` | Sticky headers | One step lighter (`base`) |
| `editor.active_line.background` | Current line highlight | Use ~75% alpha (`bf`) on `surface1` |
| `editor.highlighted_line.background` | Go-to-line highlight | Solid, one step up from editor bg |
| `editor.line_number` | Default line numbers | `overlay0` |
| `editor.active_line_number` | Current line number | `subtext1` (brighter) |
| `editor.hover_line_number` | Hovered line number | `subtext0` |
| `editor.invisible` | Whitespace/tab markers | `overlay2` |
| `editor.wrap_guide` | Soft wrap guide | Accent at ~5% alpha (`0d`) |
| `editor.active_wrap_guide` | Active wrap guide | Accent at ~10% alpha (`1a`) |
| `editor.document_highlight.read_background` | LSP read-reference | Accent at ~10% alpha (`1a`) |
| `editor.document_highlight.write_background` | LSP write-reference | Neutral at ~40% alpha (`66`) |

**Key:** `editor.gutter.background` must match `editor.background`. `editor.active_line.background` uses transparency so it works over both editor and gutter.

---

## 9. Indent Guides

| Property | Purpose | Notes |
|----------|---------|-------|
| `panel.indent_guide` | Default indent guide | ~11% alpha (`1b`) |
| `panel.indent_guide_hover` | Hovered indent guide | ~18% alpha (`2d`) |
| `panel.indent_guide_active` | Active indent guide | ~18% alpha (`2d`) |
| `editor.indent_guide` | Editor indent guide | Same as panel |
| `editor.indent_guide_active` | Active editor indent guide | Same as panel |

---

## 10. Search

| Property | Purpose | Notes |
|----------|---------|-------|
| `search.match_background` | All search matches | Accent at ~40% alpha (`66`) |
| `search.active_match_background` | Current/focused match | Secondary accent at ~40% alpha |

**Key:** Use your primary accent for matches, secondary accent (e.g., `peach`) for the active match to distinguish them.

---

## 11. Scrollbar

| Property | Purpose | Notes |
|----------|---------|-------|
| `scrollbar.thumb.background` | Scrollbar thumb | Subtle, ~30% alpha (`4c`) |
| `scrollbar.thumb.hover_background` | Thumb on hover | Solid, slightly visible |
| `scrollbar.thumb.border` | Thumb border | Match hover or transparent |
| `scrollbar.track.background` | Track behind thumb | Transparent (`00`) |
| `scrollbar.track.border` | Track border | Very subtle or transparent |

---

## 12. Minimap

| Property | Purpose | Should match |
|----------|---------|-------------|
| `minimap.thumb.background` | Viewport indicator | `scrollbar.thumb.background` |
| `minimap.thumb.hover_background` | Hover state | `scrollbar.thumb.hover_background` |
| `minimap.thumb.border` | Border | `scrollbar.thumb.border` |

**Key:** Minimap thumb should match scrollbar thumb exactly.

---

## 13. Terminal

### Base colors
| Property | Purpose | Palette mapping |
|----------|---------|----------------|
| `terminal.background` | Terminal background | `crust` (or `00` alpha for transparent) |
| `terminal.foreground` | Default text | `text` |
| `terminal.bright_foreground` | Bright text | `text` |
| `terminal.dim_foreground` | Dim text | `overlay0` |

### ANSI Colors (each has normal, bright, dim variants)

For catppuccin-style palettes, the standard mapping is:

| ANSI Color | Normal | Bright | Dim |
|------------|--------|--------|-----|
| black | `surface1` | `surface2` | `crust` |
| red | `red` | lighter red | darker red |
| green | `green` | lighter green | darker green |
| yellow | `yellow` | lighter yellow | darker yellow |
| blue | `blue` | lighter blue | darker blue |
| magenta | `pink`/`mauve` | lighter | darker |
| cyan | `teal` | lighter teal | darker teal |
| white | `subtext1` | `text` | `overlay1` |

**Bright** = same hue, higher lightness (~15-20% lighter)
**Dim** = same hue, lower lightness (~15-20% darker)

---

## 14. Diagnostic Status Colors

Each status has a triplet: solid color, background (10% alpha), and border.

| Status | Color role | Background | Border |
|--------|-----------|------------|--------|
| `error` | `red` | red + `1a` | darkened red |
| `warning` | `yellow` | yellow + `1a` | darkened yellow |
| `info` | `blue` | blue + `1a` | darkened blue |
| `hint` | muted blue | muted blue + `1a` | darkened muted blue |
| `success` | `green` | green + `1a` | darkened green |
| `conflict` | `yellow` | yellow + `1a` | darkened yellow |
| `created` | `green` | green + `1a` | darkened green |
| `deleted` | `red` | red + `1a` | darkened red |
| `modified` | `yellow` | yellow + `1a` | darkened yellow |
| `renamed` | `blue` | blue + `1a` | darkened blue |
| `hidden` | `overlay1` | overlay + `1a` | `border` color |
| `ignored` | `overlay1` | overlay + `1a` | `border` color |
| `predictive` | muted accent | muted + `1a` | darkened |
| `unreachable` | `subtext0` | overlay + `1a` | `border` color |

**Pattern:** `.background` = same hex as base color but with `1a` (10%) alpha. `.border` = a darkened version of the base color, often at `c2` (76%) alpha or solid.

**Linked groups** (same base color):
- `error` = `deleted` (both use red)
- `warning` = `conflict` = `modified` (all use yellow)
- `success` = `created` (both use green)
- `info` = `renamed` (both use blue)
- `hidden` = `ignored` (both use muted gray)

---

## 15. Version Control

| Property | Purpose | Color role |
|----------|---------|-----------|
| `version_control.added` | Added lines/files | `green` |
| `version_control.modified` | Modified lines/files | `yellow` |
| `version_control.deleted` | Deleted lines/files | `red` |
| `version_control.renamed` | Renamed files | `blue` |
| `version_control.conflict` | Conflicting files | `yellow` |
| `version_control.ignored` | Ignored files | `overlay1` |
| `version_control.conflict_marker.ours` | "Ours" conflict side | `green` at `1a` alpha |
| `version_control.conflict_marker.theirs` | "Theirs" conflict side | accent at `1a` alpha |
| `version_control.word_added` | Word-level diff added | `green` at ~35% alpha |
| `version_control.word_deleted` | Word-level diff deleted | `red` at ~80% alpha |

---

## 16. Links

| Property | Purpose | Should match |
|----------|---------|-------------|
| `link_text.hover` | Hovered link color | `text.accent` (e.g., `blue`) |

---

## 17. Players (Multiplayer Cursors)

Array of 6-8 player color objects. Each uses a distinct accent color.

```json
{
  "cursor": "#colorff",      // solid
  "background": "#colorff",  // solid (same as cursor)
  "selection": "#color3d"    // same color at 24% alpha
}
```

**Pattern:** `cursor` = `background` (same color). `selection` = same hex but `3d` alpha.

Use distinct accent colors from the palette for each player. Typical order: blue, red/maroon, peach, mauve, teal, pink, yellow, green.

---

## 18. Syntax Highlighting

Each token has `{ color, font_style, font_weight }`.
- `font_style`: `null`, `"normal"`, or `"italic"`
- `font_weight`: `null`, `400` (normal), or `700` (bold)

### Semantic color roles for syntax tokens:

| Role | Tokens | Typical palette color |
|------|--------|----------------------|
| **Accent/Primary** | `attribute`, `emphasis`, `label`, `selector.pseudo`, `tag` | Primary accent (blue/lavender) |
| **Function** | `function`, `constructor`, `variant` | Blue/sapphire |
| **Keyword** | `keyword` | Mauve/purple |
| **String** | `string`, `text.literal` | Green |
| **Number/Boolean** | `number`, `boolean`, `variable.special`, `string.regex`, `string.special`, `string.special.symbol`, `emphasis.strong` | Peach/orange |
| **Constant** | `constant`, `selector` | Yellow |
| **Type** | `type`, `operator`, `link_uri` | Teal/cyan |
| **Property/Markup** | `property`, `enum`, `title`, `punctuation.list_marker`, `punctuation.markup`, `punctuation.special` | Red |
| **Comment** | `comment` | Muted (`overlay0`) |
| **Comment doc** | `comment.doc`, `string.escape` | Slightly brighter (`overlay1`) |
| **Neutral** | `primary`, `variable`, `punctuation`, `punctuation.bracket`, `punctuation.delimiter` | `subtext0` / `subtext1` |
| **Text-like** | `embedded`, `namespace`, `preproc` | `text` |
| **Hint/Predictive** | `hint` | Muted blue |
| **Predictive** | `predictive` | Muted accent, italic |
| **Link** | `link_text` | Function color, `font_style: "normal"` |

---

## 19. Blur / Transparency Mode

To enable wallpaper blur-through, set `"background.appearance": "blurred"` and reduce alpha on surfaces. Without this, Zed renders fully opaque.

### Blur alpha map

Which properties need transparency and how much:

| Property | Blurred alpha | Why |
|----------|--------------|-----|
| `background` | `e6` (90%) | Base window tint, mostly opaque for structure |
| `surface.background` | `00` (0%) | Fully transparent — panels/surfaces inherit this |
| `panel.background` | `00` (0%) | File tree, terminal panel — blur shows through |
| `elevated_surface.background` | `f3` (95%) | Popups/modals must be readable, nearly solid |
| `panel.overlay_background` | `f3` (95%) | Command palette — same as elevated |
| `panel.overlay_hover` | `e6` (90%) | Match window background opacity |
| `editor.background` | `80` (50%) | Semi-transparent editor, blur visible behind code |
| `editor.gutter.background` | `80` (50%) | Must match `editor.background` |
| `editor.subheader.background` | `80` (50%) | Sticky headers over editor |
| `editor.highlighted_line.background` | `bf` (75%) | Needs some opacity but shouldn't be a solid stripe |
| `toolbar.background` | `80` (50%) | Semi-transparent, between tabs and editor |
| `tab_bar.background` | `80` (50%) | Semi-transparent tab strip |
| `tab.inactive_background` | `40` (25%) | Very transparent — inactive tabs fade into bar |
| `tab.active_background` | `f3` (95%) | Nearly solid so active tab stands out |
| `status_bar.background` | `e6` (90%) | Mostly opaque for readability |
| `title_bar.background` | `e6` (90%) | Mostly opaque |
| `title_bar.inactive_background` | `e6` (90%) | Matches title bar |
| `terminal.background` | `00` (0%) | Fully transparent terminal |
| `element.background` | `00` (0%) | Transparent default, visible on hover |
| `element.hover/active/selected` | `e6` (90%) | Semi-transparent hover states |
| `element.disabled` | `e6` (90%) | Matches window background |
| `ghost_element.hover/active/selected` | `e6` (90%) | Must match element counterparts for blur |
| `ghost_element.disabled` | `e6` (90%) | Matches element disabled |
| `border` / `border.variant` | `66` (40%) | Subtle, semi-transparent dividers |
| `border.focused` | `66` (40%) | Soft focus indicator |
| `panel.focused_border` | `null` | Hidden — blur makes hard borders look bad |
| `pane.focused_border` | `null` | Hidden |
| `scrollbar.thumb.hover` | `a6` (65%) | Semi-transparent, not jarring |
| `scrollbar.thumb.border` | `00` (0%) | Hidden |
| `minimap.thumb.hover` | `a6` (65%) | Match scrollbar |
| `minimap.thumb.border` | `00` (0%) | Hidden |

### Gotchas for blur themes

- **Ghost elements must use transparency too.** They sit on transparent panels (file tree, breadcrumbs). Solid `ff` hover states look like opaque rectangles floating on blur.
- **`editor.highlighted_line` should NOT be solid.** It creates a harsh opaque stripe across a semi-transparent editor.
- **Scrollbar/minimap borders should be hidden** (`00`). On blur, visible borders on scrollbar thumbs look out of place.
- **`panel.focused_border` and `pane.focused_border` work best as `null`** in blur themes. Hard border lines between blurred panels look jarring.
- **`tab.active_background` should be nearly solid** (`f3`) so it clearly indicates which tab is active against the transparent tab bar.
- **`elevated_surface` and `panel.overlay` must stay nearly opaque** (`f3`). These are popups/modals — if they're too transparent, text over blurred content becomes unreadable.

### Reverting to opaque

To make a non-blur (solid) version of the same theme, change these properties:

```
background            e6 → FF
surface.background    00 → FF
panel.background      00 → FF
elevated_surface      f3 → FF
panel.overlay_bg      f3 → FF
panel.overlay_hover   e6 → FF
editor.background     80 → FF
editor.gutter.bg      80 → FF
editor.subheader.bg   80 → FF
editor.highlighted    bf → FF
toolbar.background    80 → FF
tab_bar.background    80 → FF
tab.inactive_bg       40 → FF
tab.active_bg         f3 → FF
status_bar.bg         e6 → FF
title_bar.bg          e6 → FF
title_bar.inactive    e6 → FF
terminal.background   00 → FF
element.background    00 → FF
element.hover         e6 → FF
element.active        e6 → FF
element.selected      e6 → FF
element.disabled      e6 → FF
ghost_element.*       e6 → FF
border / border.var   66 → CC/99
border.focused        66 → FF
panel.focused_border  null → border.focused value
pane.focused_border   null → border.focused value
scrollbar.thumb.hover a6 → FF
scrollbar.thumb.bdr   00 → match hover
minimap.thumb.hover   a6 → FF
minimap.thumb.border  00 → match hover
```

Remove `"background.appearance": "blurred"` or keep it (it has no effect when everything is solid).
