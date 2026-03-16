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

    services/
        Audio.qml                 # Singleton: Quickshell.Services.Pipewire
        Battery.qml               # Singleton: UPower + powerprofilesctl power profile switching
        Bluetooth.qml             # Singleton: Quickshell.Services.Bluetooth
        Clock.qml                 # Singleton: SystemClock + format helpers
        Hypr.qml                  # Singleton: Quickshell.Hyprland + workspace rules
        Network.qml               # Singleton: iwd via Process polling
        Notifications.qml         # Singleton: NotificationServer, popup management, history, notification center state
        Popout.qml                # Singleton: popout state machine (show/close/cleanup + graceActive)
        Brightness.qml            # Singleton: brightnessctl + sysfs FileView watching
        Players.qml               # Singleton: Quickshell.Services.Mpris (live position interpolation)
        SystemStats.qml           # Singleton: CPU, RAM, temp, disk, GPU polling (nvidia-smi / AMD sysfs)
        Calendar.qml              # TODO: khal event polling via Process

    modules/
        drawers/                   # Full-screen wrapper (Caelestia "drawers" pattern)
            Drawers.qml            # Variants per screen, layershell window, popout background Shape
            Border.qml             # Screen frame with shadow
            Exclusions.qml         # Wayland exclusion zones

        bar/
            BarWrapper.qml         # Outer container with background + padding
            BarContent.qml         # Vertical ColumnLayout with all bar components
            components/
                Workspaces.qml     # Workspace switcher with per-workspace window icons
                StatusIcons.qml    # Volume, brightness, network, battery icons with popout triggers
                Tray.qml           # System tray container
                TrayItem.qml       # Individual tray icon
                TrayOverflow.qml   # Tray icons with hover-to-open popout menus
            popouts/
                PopoutWrapper.qml  # Master popout container with animations + flush-edge pinning
                CalendarPopout.qml # Month grid with today highlight, nav, clock footer
                SystemPopout.qml   # Distro, kernel, uptime, hostname, shell, packages + hardware/GPU stats
                BatteryPopout.qml  # Battery %, capacity bar, power profile toggle
                VolumePopout.qml   # Volume slider + output device switcher + MPRIS now-playing controls
                WifiPopout.qml     # Wi-Fi status, network list, connect/disconnect
                BluetoothPopout.qml # Bluetooth device list, connect/disconnect
                PowerPopout.qml    # Shutdown, restart, sleep, lock, logout
                TrayMenuPopout.qml # Dynamic tray app menus with submenu navigation
                BrightnessPopout.qml # Brightness slider popout
                ThemePopout.qml    # Palette file list with click-to-switch theme
                PlaceholderPopout.qml # Stub popout for unimplemented features

        notifications/
            NotificationCard.qml       # Notification card: icon, text, actions, close, image, timestamp
        osd/                       # TODO
        session/                   # TODO
        dashboard/                 # TODO

    utils/
        Theme.qml                  # Design tokens: colors, sizes, spacing, animation curves
        Icons.qml                  # Material Symbol icon mappings for app categories
        Anim.qml                   # Standard MD3-curve NumberAnimation helper
        MaterialIcon.qml           # Material Symbols variable font component
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
3. **Single full-screen window per monitor** — one `WlrLayershell` window hosts bar + all panels. `Variants { model: Quickshell.screens }` at the shell level, not per-module. Panels slide in/out via width/height animations with `HyprlandFocusGrab` for click-away dismissal.
4. **Material Symbols Rounded for icons** — use `utils/MaterialIcon.qml` component. Set `text` to icon name, `fill` (0=outline, 1=filled), `color` for theming. Animate `fill` for state transitions.
5. **MD3 animation curves** — BezierSpline easing (Emphasized, Standard, EmphasizedDecel) via `utils/Anim.qml`. Durations: 400ms normal, 200ms small, 150ms fast.
6. **Don't over-engineer** — no 16-file config system, no typed config classes. Keep it flat.

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
- We skip their config abstraction layer (hardcode sensible defaults, theme from JSON)
- We keep: focus grab, region masking, visibility state, slide animations
- We built our own popout system with hover-triggered shelf extending from the bar, concave protrusion ShapePath, flush-edge pinning, and MD3 animation curves

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
    path: Quickshell.env("HOME") + "/.config/palette/active.json"
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

### Phase 1: Foundation + Shell Wrapper + Bar ✅
- [x] Directory structure with `qs.` module imports
- [x] `utils/Theme.qml` — design tokens (colors, sizes, spacing, animation curves)
- [x] `utils/MaterialIcon.qml` — variable Material Symbols font component
- [x] `services/` — Audio, Battery, Bluetooth, Clock, Hypr, Network, Popout singletons
- [x] `modules/drawers/Drawers.qml` — full-screen layershell window, Region mask, Border
- [x] `modules/bar/` — vertical bar (left edge) with BarWrapper + BarContent
- [x] Bar: Workspaces — per-workspace window icons, active indicator pill, click to switch
- [x] Bar: Clock — 12-hour AM/PM display with calendar+clock hover group
- [x] Bar: StatusIcons — volume, network, battery with hover popouts
- [x] Bar: Tray — system tray icons
- [x] Popout system — hover-triggered shelf with concave protrusion, flush-edge pinning, MD3 curves

### Phase 1.5: Bar Polish
- [x] Tray menus — dynamic QsMenuOpener menus with StackView submenu navigation, fade transitions, back pill button
- [x] Tray interaction fixes — HoverHandler for non-blocking hover, acceptedButtons: Qt.NoButton for click passthrough
- [x] Popout grace period — graceActive flag prevents premature close during menu resize/transitions
- [x] Bar: CalendarPopout — month grid with today highlight, month navigation, fixed 6-row layout, clock footer
- [x] Bar: VolumePopout — drag/click slider, mute toggle, output device switcher with click-to-select
- [x] Bar: WifiPopout — iwd/iwctl network list, click to connect/disconnect, scan button, signal levels
- [x] Bar: BluetoothPopout — native Quickshell.Bluetooth API, device list, click to connect/disconnect
- [x] Bar: BatteryPopout — capacity bar, power profile pill toggle (powerprofilesctl)
- [x] Bar: PowerPopout — click actions for shutdown, restart, sleep, lock, logout
- [x] Bar: SystemPopout — distro, kernel, uptime, hostname, shell, native/AUR package counts
- [x] Standardized popout widths — all popouts use 280px Item spacer pattern
- [x] Theme integration — palette JSON via FileView, _quickshell semantic roles for variant-aware contrast
- [x] Bar: ThemePopout — palette file list with click-to-switch, active highlight
- [x] UI polish — three-pass design review: color consistency, tokenization, tray icon fallbacks
- [x] Composited frame shadow — single MultiEffect layer for unified frame + popout silhouette shadow
- [x] Flush popout fix — cached content height prevents top-flush detection flicker during Loader activation
- [x] `services/Players.qml` — MPRIS singleton with live position interpolation (used in VolumePopout)
- [x] `services/SystemStats.qml` — CPU, RAM, temp, disk, GPU stats (polls only when SystemPopout open)
- [x] Bar: VolumePopout — MPRIS now-playing: album art, seek bar, transport controls
- [x] Bar: SystemPopout — hardware stats (CPU, RAM, temp, disk) + conditional GPU section (NVIDIA/AMD)
- [x] Parameterizable bezel intensity — `_quickshell.bezelIntensity` (0=none, 1=subtle, 2=normal, 3=heavy)
- [x] Startup animations — bar slide-in, workspace pill cascade
- [x] Hover effects on bar items — color transitions on status icons, scale/opacity on workspace indicators
- [x] Theme-overridable accent token — `_quickshell.accent` per palette, defaults to `blue`
- [x] Slider gradient fix — subtleText as low-end blend (not lavender) for semantic consistency
- [x] Multi-palette support — Rose Pine (base/moon/dawn), Nord, Everforest (dark/light)
- [x] Bar: BrightnessPopout — brightness slider, visible only when backlight hardware present

### Phase 2: OSD — skipped, covered by bar popouts
- [x] `services/Brightness.qml` — brightnessctl + sysfs FileView (no polling)
- [~] `modules/osd/OsdPopup.qml` — skipped, VolumePopout + BrightnessPopout already provide feedback

### Phase 3: Notifications
- [x] `services/Notifications.qml` — NotificationServer singleton, popup management, tracked history
- [x] `modules/notifications/NotificationCard.qml` — card with icon, summary, body, image, actions, close button
- [x] Popup notifications — bezel-integrated, top-right, auto-expire with hover pause, entrance/exit animations
- [x] Notification API fixes — expire vs dismiss, lastGeneration filter, persistenceSupported, duplicate image suppression
- [x] Notification center — expandable from popup stack, scrollable history, header with "Clear all", HyprlandFocusGrab
- [ ] Keybind / launcher entry point for notification center (currently only accessible from popup stack)

### Phase 4: Calendar Integration
- [ ] Set up pimsync (vdirsyncer successor) with CalDAV sources + secret storage
- [ ] Set up khal to read pimsync vdir for CLI event queries
- [ ] `services/Calendar.qml` — periodic `khal list` polling via Process, parse into event model
- [ ] `CalendarPopout.qml` — integrate khal events below month grid (today + upcoming)
- [ ] Event indicators on calendar days (dots for days with events)

### Phase 5: Dashboard — redirected
- [x] Media player controls — integrated into VolumePopout (Phase 1.5)
- [x] System stats — integrated into SystemPopout (Phase 1.5)
- [ ] `modules/dashboard/Dashboard.qml` — future use (app launcher or other)

### Phase 6: Polish + Cutover
- [ ] Coordinated panel visibility (opening one closes others)
- [ ] Per-monitor workspace support
- [ ] Run Quickshell alongside Waybar, validate parity
- [ ] Disable Waybar in Hyprland config
- [ ] Remove Waybar/swaync from chezmoi

### Phase 7: Rust Tooling (optional)
- [ ] `qs-visualizer` — PipeWire FFT, JSON line output
- [ ] `qs-color-extract` — wallpaper dominant color extraction
