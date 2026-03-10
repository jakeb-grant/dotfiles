# Quickshell Migration Plan

Replacing Waybar + swaync with a unified Quickshell desktop shell on Hyprland.

## Current Stack

| Component | Current | Replacement |
|-----------|---------|-------------|
| Bar | Waybar | Quickshell bar (vertical, left edge) |
| Notifications | swaync | Quickshell sidebar (notification dock + history) |
| OSD | (none) | Quickshell OSD (volume/brightness overlay) |
| Session menu | (none) | Quickshell session panel (slide-in from right) |
| Dashboard | (none) | Quickshell dashboard (slide-down from top: calendar, media, stats) |
| Launcher | Walker | Keep Walker |
| Lock screen | hyprlock | Keep hyprlock |

## Architecture

### Directory Structure

```
dot_config/quickshell/
    shell.qml                     # ShellRoot entry point

    theme/
        qmldir
        Theme.qml                 # Singleton: reads ~/.config/themes/active.json via FileView

    services/
        qmldir
        Audio.qml                 # Singleton: Quickshell.Services.Pipewire
        Hypr.qml                  # Singleton: Quickshell.Hyprland + raw event handling
        Power.qml                 # Singleton: Quickshell.Services.UPower
        Players.qml               # Singleton: Quickshell.Services.Mpris
        Network.qml               # Singleton: iwd via Process polling (no native API)
        Brightness.qml            # Singleton: brightnessctl via Process
        Tray.qml                  # Singleton: Quickshell.Services.SystemTray

    modules/
        shell/                     # Full-screen wrapper (Caelestia "drawers" pattern)
            qmldir
            Shell.qml              # Variants per screen, full-screen layershell window
            Panels.qml             # Anchors all panel wrappers (osd, session, sidebar, dashboard)
            Interactions.qml       # Mouse/drag logic for showing/hiding panels
            Backgrounds.qml        # Shaped backgrounds behind panels (optional)

        bar/
            qmldir
            Bar.qml                # Vertical bar (left edge), ColumnLayout
            components/
                Workspaces.qml
                ActiveWindow.qml
                Clock.qml
                StatusIcons.qml    # Battery, network, audio, bluetooth
                TrayHost.qml
                MediaWidget.qml    # MPRIS now-playing

        osd/
            qmldir
            OsdPopup.qml           # Volume/brightness overlay (right edge, center)

        session/
            qmldir
            SessionPanel.qml       # Slide-in from right: logout/shutdown/reboot/hibernate

        sidebar/
            qmldir
            Sidebar.qml            # Slide-in from right: notification history + dock
            NotifDock.qml          # Live notification list

        dashboard/
            qmldir
            Dashboard.qml          # Slide-down from top: clock, calendar, media, stats

    components/
        qmldir
        StyledRect.qml             # Theme-aware rectangle
        StyledText.qml             # Theme-aware text
        IconLabel.qml              # Nerd font icon + label pattern
        Pill.qml                   # Rounded pill container

    rust/                          # Rust workspace (optional, for perf-critical features)
        Cargo.toml
        crates/
            qs-visualizer/         # Audio FFT visualization
            qs-color-extract/      # Wallpaper dominant color extraction
```

### Dependencies

```bash
sudo pacman -S ttf-material-symbols-variable
```

- **Material Symbols Rounded** — variable icon font used for all UI icons. Supports `FILL`, `GRAD`, `opsz`, `wght` axes for dynamic icon styling (e.g., outline→filled on state change). Named ligature icons (e.g., `"volume_up"`, `"wifi"`) instead of opaque codepoints.
- **JetBrainsMono Nerd Font** — used for text content (clock, labels, etc.)

### Design Principles

1. **Use native Quickshell APIs** wherever possible (PipeWire, UPower, Hyprland, MPRIS, SystemTray). Only fall back to `Process` polling for iwd network and brightnessctl.
2. **Service singletons** wrap Quickshell APIs and expose clean properties. UI modules never import Quickshell service modules directly.
3. **Theme.qml** reads `~/.config/themes/active.json` via `FileView` with `watchChanges: true`. Theme switches are detected automatically. No chezmoi `.tmpl` processing needed for QML files.
4. **Single full-screen window per monitor** — one `WlrLayershell` window hosts bar + all panels. `Variants { model: Quickshell.screens }` at the shell level, not per-module. Panels slide in/out via width/height animations with `HyprlandFocusGrab` for click-away dismissal.
5. **Material Symbols Rounded for icons** — use `utils/MaterialIcon.qml` component. Set `text` to icon name, `fill` (0=outline, 1=filled), `color` for theming. Animate `fill` for state transitions.
5. **Don't over-engineer** — no 16-file config system, no typed config classes. Keep it flat.

### Full-Screen Wrapper Architecture (from Caelestia "drawers" pattern)

The key insight: instead of separate `PanelWindow`/`PopupWindow` per UI element, use **one full-screen transparent layershell window** per monitor with `ExclusionMode.Ignore`. The bar and all panels live inside this window:

```
┌────────────────────────────────────────────┐
│ ┌──┐                          ┌──────────┐ │
│ │  │                          │ Dashboard│ │
│ │  │                          │ (top)    │ │
│ │B │                          └──────────┘ │
│ │A │                                       │
│ │R │                    ┌──┐ ┌───────────┐ │
│ │  │                    │OS│ │  Session   │ │
│ │  │                    │D │ │  (right)   │ │
│ │  │                    └──┘ └───────────┘ │
│ │  │                                       │
│ │  │                         ┌───────────┐ │
│ │  │                         │  Sidebar   │ │
│ │  │                         │  (notifs)  │ │
│ └──┘                         └───────────┘ │
└────────────────────────────────────────────┘
```

**Why this approach:**
- Panels can share backgrounds and blend visually (connected borders, shadows)
- Mouse interactions (hover-to-reveal, drag-to-open) work across the full screen surface
- `HyprlandFocusGrab` grabs focus for the whole window when any panel is open
- `Region` + `mask` with `Intersection.Xor` makes empty areas click-through
- `PersistentProperties` tracks which panels are visible across reloads
- Panels animate width/height from 0 to reveal, using `states` + `transitions`

**Simplified vs Caelestia:**
- We skip their drag-threshold system (just use hover + click/keybind)
- We skip their popouts system (bar popouts are separate PopupWindows if needed)
- We skip their config abstraction layer (hardcode sensible defaults, theme from JSON)
- We keep: focus grab, region masking, visibility state, slide animations

### Rust Integration

Performance-critical code goes in Rust (not C++). Communication with QML via **stdout JSON streaming** through Quickshell's `Process` + `SplitParser`:

```qml
Process {
    command: ["qs-visualizer", "--bars", "24"]
    running: true
    stdout: SplitParser {
        onRead: data => { values = JSON.parse(data) }
    }
}
```

**What needs Rust:**
- Audio visualization (real-time FFT on PipeWire stream)
- Wallpaper color extraction (image processing)

**What does NOT need Rust:**
- Everything else. Audio control, workspaces, tray, MPRIS, battery — all native in Quickshell.

Rust crates live in a separate repo, installed via `cargo install`, binaries in `~/.local/bin/`. Keeps dotfiles repo clean.

### Gotchas

- **Always clean `~/.config/quickshell/` before applying.** Chezmoi doesn't remove files that no longer exist in the source. Stale QML files (old renames, deleted files, leftover `qmldir`) will poison Quickshell's module loader and produce cryptic "X is not a type" errors. Run `rm -rf ~/.config/quickshell/ && chezmoi apply` when things break unexpectedly.
- **Use `qs.` imports, not relative paths.** `import qs.services as Services` is preferred over `import "../../../services" as Services`. Quickshell auto-synthesizes `qmldir` files from the directory structure relative to `shell.qml`.

### Key Quickshell Patterns

```qml
// Full-screen wrapper per monitor (the "drawers" pattern)
Variants {
    model: Quickshell.screens
    Scope {
        required property ShellScreen modelData
        StyledWindow {
            screen: modelData
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }

            // Click-through except bar + open panels
            mask: Region { intersection: Intersection.Xor; ... }

            // Grab focus when panels open
            HyprlandFocusGrab { active: anyPanelOpen; windows: [win] }

            // Track open/closed state across reloads
            PersistentProperties { property bool session; property bool sidebar; ... }

            Bar { anchors.left: parent.left }
            Panels { anchors.fill: parent; anchors.leftMargin: bar.width }
        }
    }
}

// Panel slide animation (width from 0 to target)
states: State { name: "visible"; when: visibilities.sidebar
    PropertyChanges { root.implicitWidth: 350 }
}
transitions: Transition { NumberAnimation { property: "implicitWidth"; duration: 300 } }

// Singleton service
pragma Singleton
Singleton { id: root; readonly property int activeWsId: ... }

// Process polling
Process {
    command: ["iwctl", "station", "wlan0", "show"]
    stdout: SplitParser { onRead: data => { /* parse */ } }
}
Timer { interval: 5000; running: true; repeat: true; onTriggered: proc.running = true }

// Theme-reactive colors
FileView {
    path: Quickshell.env("HOME") + "/.config/themes/active.json"
    watchChanges: true
    onLoaded: { root.colors = JSON.parse(text()) }
}

// Hyprland event handling
Connections {
    target: Hyprland
    function onRawEvent(event) {
        if (["workspace", "focusedmon"].includes(event.name))
            Hyprland.refreshWorkspaces()
    }
}
```

## Documentation References

### Context7 MCP (use for up-to-date docs)

```
Quickshell v0.2.1:  /websites/quickshell_v0_2_1   (650 snippets, High reputation)
Caelestia shell:    /caelestia-dots/shell           (56 snippets, Medium reputation)
```

Query examples:
- `"PanelWindow PopupWindow properties signals methods"` — core window types
- `"Hyprland workspace monitor integration"` — Hyprland module
- `"SystemTray Pipewire Mpris UPower service API"` — service modules
- `"Process FileView SplitParser IO"` — I/O patterns

### Local References

- Caelestia shell: `~/references/caelestia-shell/` — 281 QML files, comprehensive reference
  - Key files: `shell.qml`, `services/Hypr.qml`, `modules/drawers/Drawers.qml`, `modules/bar/Bar.qml`
  - Drawers pattern: `modules/drawers/` — Shell.qml (full-screen wrapper), Panels.qml, Interactions.qml, Backgrounds.qml
  - Sidebar: `modules/sidebar/` — notification dock, history, slide-in wrapper
  - Session: `modules/session/` — logout/shutdown/reboot/hibernate panel
  - Dashboard: `modules/dashboard/` — calendar, media, weather, performance stats
  - Their C++ plugins are NOT needed (audio viz, image analysis, calculator — all bloat or doable in Rust)
- Memory files:
  - `memory/quickshell-docs.md` — API type index and key type details
  - `memory/quickshell-caelestia-reference.md` — Caelestia architecture analysis

### Online

- Quickshell docs: https://quickshell.org/docs/v0.2.1/
- Quickshell types: https://quickshell.org/docs/v0.2.1/types/
- Qt QML reference: https://doc.qt.io/qt-6/qtquick-index.html

## Roadmap

### Phase 1: Foundation + Shell Wrapper + Bar
- [ ] Create directory structure and qmldir module declarations
- [ ] `theme/Theme.qml` — read active.json, expose all color properties
- [ ] `services/Hypr.qml` — workspace/monitor/toplevel state, dispatch(), raw event handling
- [ ] `services/Audio.qml` — PipeWire volume/mute state, increment/decrement
- [ ] `components/` — StyledRect, StyledText, Pill, IconLabel
- [ ] `modules/shell/Shell.qml` — full-screen layershell window per monitor, ExclusionMode.Ignore, Region mask
- [ ] `modules/shell/Panels.qml` — anchor all panel wrappers, pass visibilities
- [ ] `modules/bar/Bar.qml` — vertical bar (left edge), ColumnLayout
- [ ] Bar: Workspaces — numbered buttons, active/occupied/empty states, click to switch, animations
- [ ] Bar: Clock — date + time with nerd font icon
- [ ] Bar: StatusIcons — volume, network, battery with state-appropriate icons and colors
- [ ] Bar: TrayHost — system tray icons
- [ ] Bar: ActiveWindow — focused window title
- [ ] Bar: MediaWidget — MPRIS now-playing with controls
- [ ] Startup animations — slide-in, cascade workspace pills, tray icon pop-in
- [ ] Hover effects — scale, border glow, color transitions

### Phase 2: OSD + Session Panel
- [ ] `services/Brightness.qml` — brightnessctl wrapper
- [ ] `modules/osd/OsdPopup.qml` — volume/brightness overlay (right edge, vertically centered)
- [ ] Auto-show on change, auto-hide after timeout
- [ ] `modules/session/SessionPanel.qml` — slide-in from right with scrim overlay
- [ ] Session buttons: logout, shutdown, reboot, hibernate with keyboard navigation
- [ ] HyprlandFocusGrab when session panel is open
- [ ] Trigger via keybind (GlobalShortcut or Hyprland IPC)

### Phase 3: Sidebar (Notifications)
- [ ] `modules/sidebar/Sidebar.qml` — slide-in from right, notification dock
- [ ] `modules/sidebar/NotifDock.qml` — live notification list with dismiss/action
- [ ] Notification history (scrollable)
- [ ] `Quickshell.Services.Notifications` as notification server (replaces swaync)
- [ ] Hover or keybind to reveal sidebar

### Phase 4: Dashboard
- [ ] `modules/dashboard/Dashboard.qml` — slide-down from top edge
- [ ] Calendar widget
- [ ] Media player controls (MPRIS)
- [ ] System stats (CPU/RAM/disk/temp via Process)
- [ ] Hover or keybind to reveal

### Phase 5: Interactions + Polish
- [ ] `modules/shell/Interactions.qml` — hover zones, drag-to-reveal, click-away dismiss
- [ ] Coordinated panel visibility (e.g., opening session closes sidebar)
- [ ] Popup windows for bar items (audio mixer, battery details)
- [ ] Per-monitor workspace support

### Phase 6: Replace Waybar + swaync
- [ ] Run Quickshell alongside Waybar, validate parity
- [ ] Disable Waybar in Hyprland config
- [ ] Remove Waybar/swaync from chezmoi

### Phase 7: Rust Tooling
- [ ] Set up Rust workspace with cargo
- [ ] `qs-visualizer` — PipeWire FFT, JSON line output
- [ ] Visualizer bar widget or desktop background integration
- [ ] `qs-color-extract` — wallpaper dominant color extraction (optional)
