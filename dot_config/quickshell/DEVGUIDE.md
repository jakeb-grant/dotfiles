# Quickshell Dev Guide

Best practices for building and extending the Quickshell desktop shell.

## Theme System

### How It Works

Theme colors are loaded at runtime from `~/.config/palette/active.json` via `FileView` with `watchChanges: true`. When the active palette file changes (e.g. via `theme-switch`), the entire shell re-themes live — no restart needed.

`utils/Theme.qml` is the single source of truth for all visual properties: colors, sizes, spacing, rounding, fonts, and animation parameters. Never hardcode *colors* — they must track the palette. For sizes/durations, tokenize anything reused across files or likely to be tuned (bar/popout surfaces hold to this strictly); one-off geometry internal to a single component (lockscreen blob layout, entrance animation choreography) may stay inline.

### Color Hierarchy

Colors are organized in three tiers:

**1. Palette colors** — raw Catppuccin-format colors from the JSON file:
```
Neutrals:  crust → mantle → base → surface0/1/2 → overlay0/1/2 → subtext0/1 → text
Accents:   rosewater, flamingo, pink, mauve, red, maroon, peach, yellow, green, teal, sky, sapphire, blue, lavender
```

These have consistent *names* across all variants but different *values*. On Mocha (dark), `crust` is near-black; on Latte (light), `crust` is near-white. The scale always runs from the background anchor (`crust`) to the foreground/text anchor (`text`) — dark-to-light on dark variants, light-to-dark on light ones.

**2. Semantic roles** — purpose-driven aliases that map to different palette positions per variant:
```qml
// Theme.qml
readonly property color disabledText:      _qs.disabledText      ?? overlay0
readonly property color subtleText:        _qs.subtleText        ?? overlay1
readonly property color separator:         _qs.separator         ?? surface1
readonly property color pillBg:            _qs.pillBg            ?? base
readonly property color hoverBg:           _qs.hoverBg           ?? surface1
readonly property color islandShadowColor: _qs.islandShadowColor ?? crust
```

The `??` fallback is the default (works well on dark variants). Light variants override via `_quickshell` in their palette JSON to maintain contrast. For example, `pillBg` defaults to `base` (dark on Mocha) but Latte overrides it to `crust` (darker than `base` on light themes, creating the needed contrast inversion).

**3. Accent colors** — used sparingly for interactive state and emphasis:
- `accent` — active/connected state and emphasis (connected device, active wifi, checkmarks); per-palette via `_quickshell.accent`, falls back to `blue`
- `red` — destructive/power actions
- `green` — success/enabled state
- `mauve` — special highlights (theme popout accent)
- `subtext0`/`subtext1` — secondary text (status lines, battery %, timestamps)
- `subtleText` — tertiary text and inactive icons
- `disabledText` — disabled/placeholder text

### Adding a New Semantic Role

When a color needs to map to different palette positions across light/dark variants:

1. Add the property to Theme.qml under `// ── Semantic Roles ──`:
```qml
readonly property color myRole: _qs.myRole ?? surface0  // default for dark
```

2. Add the override to light variant palette JSONs (`dot_config/palette/catppuccin-latte.json`):
```json
"_quickshell": {
    "myRole": "#acb0be"
}
```

3. If the default works for all dark variants, you only need to override in Latte (and potentially Frappé). Test across variants.

### When to Use What

| Purpose | Use | Example |
|---------|-----|---------|
| Background fills | `mantle`, `base`, `pillBg` | Popout bg, pill bg |
| Text (primary) | `text` | Labels, values |
| Text (secondary) | `subtext0`, `subtext1` | Status lines, subtitles |
| Text (tertiary) | `subtleText` | Inactive bar icons |
| Text (disabled) | `disabledText` | Placeholder, unavailable |
| Hover state | `hoverBg` | List item hover overlay |
| Borders/dividers | `separator` | Horizontal rules in popouts |
| Active/connected | `accent` | Connected BT, active wifi |
| Destructive | `red` | Power button, disconnect |
| Popout titles | `text` | Not accent — titles use primary text |
| Header icons | `subtleText` | Popout header icons (non-interactive) |
| Floating island corners | `islandRounding` | Popouts, launcher, notifications, bar |
| Island ↔ bar/neighbor gap | `islandGap` | Spacing between floating surfaces |
| Bar ↔ screen edge | `barMargin` | Bar's breathing room |
| Island drop shadow | `islandShadow*` | Shadow color/blur/opacity/Y offset |

## Dimensions & Spacing

Never use magic numbers. All sizes live in Theme.qml under organized sections.

### Token Reference

```qml
// Sizes
iconSize: 20          iconSizeSmall: 14
fontSize: 14          fontSizeSmall: 11      fontSizeXSmall: 9

// Spacing
spacingTiny: 2        spacingSmall: 4
spacingNormal: 8      spacingLarge: 12

// Rounding
roundingSmall: 10     roundingNormal: 16     roundingFull: 999

// Floating islands
islandRounding: 20    islandGap: 8
islandShadowBlur: 24  islandShadowOpacity: 0.35    islandShadowY: 6
barMargin: 4          barRounding: 16

// Popouts
popoutWidth: 280
popoutListHeight: 180

// List items
listItemHeight: 32    listItemRadius: 6
listItemMargin: 8     listFontSize: 13

// Pills
pillHeight: 30        pillFontSize: 12       pillSpacing: 4

// Headers
headerFontSize: 16    popoutTitleSize: 18
headerActionIconSize: 18 (= popoutTitleSize)
headerIconSize: 24    headerIconSizeLarge: 28
```

### Adding New Tokens

If you find yourself writing a literal number, ask: will this value be reused, or should it change with the design? If yes, add it to Theme.qml under the appropriate section. Name it by purpose, not value (`listItemHeight`, not `height32`).

## Components

### MaterialIcon

All UI icons use `utils/MaterialIcon.qml` with Material Symbols Rounded ligature names:

```qml
Utils.MaterialIcon {
    text: "wifi"                              // ligature name
    font.pixelSize: Utils.Theme.iconSize      // always from Theme
    color: Utils.Theme.subtleText             // always from Theme
    fill: 0                                   // 0 = outline, 1 = filled
}
```

Animate `fill` for state changes (e.g., outline when off, filled when on). The component has a built-in `Behavior on fill` animation.

One deliberate exception: wifi signal strength uses Nerd Font glyphs (`Network.signalIcon` / `signalIconFor(level)`) instead of MaterialIcon — Material Symbols has no per-level wifi-strength ligatures, the Nerd Font set does.

### Anim

Standard animation helper using MD3 curves:

```qml
Behavior on someProperty {
    Utils.Anim {}    // 400ms, standard curve
}
```

For color animations, use `ColorAnimation` directly:
```qml
Behavior on color {
    ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
}
```

### Animation Durations

```qml
animDuration: 400       // normal (layout changes, popout open)
animDurationSmall: 200  // small (content fade, opacity)
animDurationFast: 150   // fast (hover feedback, quick reshape)
animDurationSpin: 800   // continuous (refresh spinner)
```

## Popout Patterns

Popouts are built from the shared component library in
`modules/bar/popouts/components/` (`import qs.modules.bar.popouts.components`).
Don't hand-roll separators, hover rows, pill buttons, or sliders — import them.

| Component | Use |
|-----------|-----|
| `PopoutColumn` | Popout body: standard spacing + width spacer (`contentWidth` overridable) |
| `Separator` | 1px full-width divider |
| `SectionLabel` | Small muted section label ("Networks", "Hardware") |
| `SectionHeader` | Label row + optional spinning refresh button; extra actions as children |
| `ConnectionHeader` | Wifi/Bluetooth header: icon slot, connected/disconnected crossfade, disconnect button |
| `IconButton` | Hoverable MaterialIcon button (`baseColor`/`hoverColor`, `bounce`, `hitPadding`) |
| `PillButton` | Footer pill button (`icon` + `label`) |
| `ListRow` | Hover list row: slide-right + hover bg; children land in its inner RowLayout |
| `PopoutListView` | Fixed-height clipped ListView + centered `emptyText` |
| `FlowBar` | Track + masked flowing-gradient fill (`ratio`, `flowColors`, `flatFill`) |
| `FlowSlider` | Interactive FlowBar with thumb; emits `pressStarted`/`moved(newValue)`/`released` |
| `EmptyLabel` | Italic muted empty-state text |

A typical popout:

```qml
import QtQuick
import QtQuick.Layouts
import qs.modules.bar.popouts.components
import qs.services as Services
import qs.utils as Utils

PopoutColumn {
    id: root

    // Header: icon + title (titles use text color, not accent)
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "icon_name"
            font.pixelSize: Utils.Theme.headerIconSize
            color: Utils.Theme.subtleText
        }

        Text {
            text: "Title"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.popoutTitleSize
            font.bold: true
            color: Utils.Theme.text
            Layout.fillWidth: true
        }
    }

    Separator {}

    // Content...

    PillButton {
        Layout.fillWidth: true
        icon: "terminal"
        label: "Open something"
        onClicked: proc.running = true
    }
}
```

### List Items

Scrollable lists combine `PopoutListView` + `ListRow`:

```qml
PopoutListView {
    Layout.fillWidth: true
    model: Services.Network.networks
    emptyText: "No networks found"

    delegate: ListRow {
        id: row

        required property string ssid

        width: ListView.view.width
        interactive: true            // hover feedback + click; false for static rows
        onClicked: doSomething(row.ssid)

        // Children land in the row's inner RowLayout
        Text {
            text: row.ssid
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.listFontSize
            color: Utils.Theme.text
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
```

For non-scrolling lists (fixed action lists), use a plain `Column` +
`Repeater` with `ListRow { width: parent?.width ?? 0 }` delegates
(see `PowerPopout.qml`).

### Sliders

`FlowSlider` is display-only — the caller owns the value:

```qml
FlowSlider {
    Layout.fillWidth: true
    value: Services.Brightness.brightness              // 0..1 displayed
    flowColors: [Utils.Theme.accent, Utils.Theme.yellow, Utils.Theme.peach]

    onPressStarted: Services.Brightness.beginUserInput()
    onMoved: (newValue) => Services.Brightness.setBrightness(Math.round(newValue * 100))
    onReleased: Services.Brightness.endUserInput()
}
```

`flowColors` takes 2 or 3 colors; both tile seamlessly across the animated
gradient. See `VolumePopout.qml` for the decoupled-display + resync-timer
pattern used when the service echoes values back asynchronously.

## Floating Island Design Language

Every shell surface (bar, popouts, notifications, launcher, OSD) is a self-contained rounded `Rectangle` grounded by a soft drop shadow. No painted frames, no concave-curve seams. Islands sit in space with `barMargin` breathing room from the screen edges.

### Drop-shadow pattern

The shadow primitive lives on the Rectangle's `layer.effect: MultiEffect`. `autoPaddingEnabled: true` expands the layer's allocated texture so the shadow renders without clipping at the Rectangle's bounds.

```qml
Rectangle {
    color: Utils.Theme.mantle
    radius: Utils.Theme.islandRounding

    layer.enabled: true
    layer.smooth: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Utils.Theme.islandShadowColor
        shadowOpacity: Utils.Theme.islandShadowOpacity
        blurMax: Utils.Theme.islandShadowBlur
        shadowVerticalOffset: Utils.Theme.islandShadowY
        shadowHorizontalOffset: 0
        autoPaddingEnabled: true
    }
}
```

Tokens: `islandRounding`, `islandGap`, `islandShadowBlur`, `islandShadowOpacity`, `islandShadowY`, `islandShadowColor`.

For ephemeral surfaces, prefer `layer.enabled: visible` over `layer.enabled: true` so the offscreen surface is only allocated while the layer is being drawn.

### Bar-item hover

The bar deliberately has *no* hover decoration on its items — no scale grow, no backdrop pill, no glow. Hovering a popout-source icon (volume, brightness, calendar, etc.) opens its popout; the cursor's position plus the open popout is the only feedback. If you add a new bar item that spawns a popout, mirror the existing pattern: a `MouseArea` with `onEntered: Services.Popout.showFrom(item, name, screen)` and `onExited: Services.Popout.barItemExited()`, and nothing else visual. For top-level bar entries, `BarContent.qml`'s inline `BarItem { step; popout }` component wires this up (plus the entrance animation) — just set `popout` and drop the content in as a child.

The one non-hover addition bar items may carry is a wheel handler (volume/brightness scroll-to-adjust). Accumulate `angleDelta.y` and only act per ±120 accumulated — touchpads emit streams of small-delta events, and stepping per event overshoots badly.

### OSD

Transient feedback for keyboard-initiated state changes (volume/brightness/mic/media keys). Split the same way as popouts: `Services.Osd` decides *when* (watches `Audio`/`Brightness` value changes — including `Audio.sourceMuted` for the mic — with a startup grace period; `showMedia()` for explicit media keys; suppressed while the matching popout is open), `modules/osd/OsdOverlay.qml` renders *what*. The overlay lives in its own per-screen `WlrLayer.Overlay` PanelWindow (in `Drawers.qml`) rather than the drawers window: Hyprland draws fullscreen windows above the Top layer, and the OSD must survive fullscreen video. The window has an empty input `mask` (fully click-through) and maps only while the OSD is visible — its `visible` tracks the overlay's fade so unmap waits for the fade-out.

### Invisible hover bridge

Popouts sit `islandGap` away from the bar, so the cursor traverses transparent space when moving from a bar item to its popout. To prevent dismissal during traversal, `PopoutWrapper.qml` renders an invisible `Item` of width/height equal to `islandGap`, anchored between the bar item's edge and the popout's near edge, with its own `HoverHandler` setting a `bridgeHovered` flag. The popout closes only when *neither* the panel nor the bridge is hovered.

### Scale.origin pivot

Popouts bloom from the source bar item with an `OutBack` overshoot. The bloom point lives on `Scale.origin`, not `transformOrigin`:

```qml
transform: Scale {
    origin.x: bloomX   // local x of the bar item center inside the container
    origin.y: bloomY   // local y
    xScale: animatedScale
    yScale: animatedScale
}
```

`Scale.origin` accepts pivots outside the item's bounds with no clipping or warping, which is what makes "popouts that visibly spring from the bar item that spawned them" work even when the popout has been clamped to screen edges away from its natural origin.

## Common Mistakes

**Hardcoded colors** — never write `color: "#89b4fa"`. Use `Utils.Theme.accent`.

**Hardcoded sizes** — never write `font.pixelSize: 14`. Use `Utils.Theme.fontSize`.

**Accent-colored titles** — popout titles use `Utils.Theme.text`, not an accent color. Accents are for state indicators and interactive elements.

**Missing font.family** — every `Text` element needs `font.family: Utils.Theme.fontFamily`.

**Opacity for disabled states** — don't dim entire delegates with `opacity: 0.5`. Use `Utils.Theme.disabledText` or `Utils.Theme.subtleText` on text/icons individually. Whole-element opacity creates visual inconsistency with hover states.

**Raw ColorAnimation** — always use Theme durations:
```qml
// Bad
ColorAnimation { duration: 150 }

// Good
ColorAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
```

## Import Convention

```qml
import qs.services as Services                // service singletons
import qs.utils as Utils                      // Theme, MaterialIcon, Anim, Icons
import qs.modules.bar.popouts.components      // popout component library (unaliased)

// Access via namespace
Services.Popout.show(...)
Utils.Theme.accent
Utils.MaterialIcon { ... }
```

Never use relative path imports. Quickshell auto-synthesizes `qmldir` from the directory structure.

## Testing Across Variants

The palette system supports four Catppuccin variants: Mocha (dark), Macchiato (dark), Frappé (medium), Latte (light). Always test new UI on at least Mocha and Latte to verify:

- Semantic roles provide sufficient contrast on both light and dark
- Accent colors remain readable against both dark and light backgrounds
- Island shadows are visible (dark variants use `crust`, light variants override `islandShadowColor` to a darker neutral like `overlay0`)
- Hover/active states are distinguishable from resting state

Switch variants with: `theme-switch catppuccin-<variant>`
