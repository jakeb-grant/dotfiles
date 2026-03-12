# Sidebar Roadmap

Layout and popout plan for the Quickshell vertical bar (left edge).

## Bar Layout (top to bottom)

### Arch Logo (standalone)
- [x] Icon: `\uf303` nerd font
- [x] Popout: SystemPopout (distro, kernel, uptime, hostname, shell, native/AUR package counts)

### Theme Selector (standalone)
- [x] Icon: `palette` (Material Symbol)
- [x] Popout: ThemePopout (palette file list, click to switch, active highlight)

### Workspaces (pill + sliding indicator)
- [x] Per-workspace window icons
- [x] Active indicator pill
- [x] Occupied = glyph, empty = dot

### --- spacer ---

### System Tray (dynamic, no pill)
- [x] All SNI items rendered as icons via `SystemTray.items`
- [x] Icons with fallback (custom `?path=` icons fall back to theme icon by id, then Material fallback)
- [x] Dynamic popout menus via `QsMenuOpener` — renders real app menu entries
- [x] Per-item popout architecture (Repeater in PopoutWrapper)
- [x] Click interaction — menu items receive clicks correctly
- [x] Submenu navigation — StackView with back button for entries with `hasChildren`
- [x] Menu entry icons — icon theme cache with graceful fallback (hide all if any fail per menu)
- [x] Checkbox/radio state display for menu entries

### --- gap ---

### Calendar + Clock (merged hover group, no pill)
- [x] Icon: `calendar_today` + hours/minutes stacked text
- [x] Popout: CalendarPopout (month grid, today highlight, month navigation, 6-row layout, clock footer)
- [ ] Calendar events integration (khal/pimsync)

### --- gap ---

### System Icons (pill grouping)

**Volume**
- [x] Icon: `volume_up` / `volume_down` / `volume_off` (Material Symbol)
- [x] Popout: VolumePopout (drag/click slider, mute toggle, output device switcher)

**Wifi**
- [x] Icon: `wifi` (Material Symbol)
- [x] Popout: WifiPopout (iwd/iwctl network list, connect/disconnect, scan, signal levels)

**Bluetooth**
- [x] Icon: `bluetooth` / `bluetooth_connected` / `bluetooth_disabled` (Material Symbol)
- [x] Popout: BluetoothPopout (native Quickshell.Bluetooth API, device list, connect/disconnect)

**Battery**
- [x] Icon: granular battery state icons (Material Symbol, color-coded by level)
- [x] Popout: BatteryPopout (percent, capacity bar, power profile toggle via powerprofilesctl)

### --- gap ---

### Power (prominent, standalone)
- [x] Icon: `power_settings_new` (Material Symbol, red)
- [x] Popout: PowerPopout (shutdown, restart, sleep, lock screen, logout)

## Remaining Work

1. [ ] Calendar events integration (khal/pimsync)
2. [ ] MPRIS media widget + popout (now-playing, controls, album art)
