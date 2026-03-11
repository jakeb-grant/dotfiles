# Sidebar Roadmap

Layout and popout plan for the Quickshell vertical bar (left edge).

## Bar Layout (top to bottom)

### Arch Logo (standalone)
- [x] Icon: `\uf303` nerd font
- [x] Popout: SystemPopout (distro, kernel, uptime, hostname, shell)

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
- [ ] Fix click interaction — menu items render but clicks don't reach them
- [ ] Submenu navigation for entries with `hasChildren`
- [ ] Polish: icons for menu entries, checkbox/radio state display

### --- gap ---

### Calendar (standalone, no pill)
- [x] Icon: `calendar_today` (Material Symbol)
- [x] Popout: PlaceholderPopout
- [ ] Popout: real calendar widget, upcoming events

### Clock (standalone, no pill)
- [x] Icon: hours/minutes stacked text (slightly enlarged font)
- [x] Popout: ClockPopout (day, date, time)

### --- gap ---

### System Icons (pill grouping)

**Volume**
- [x] Icon: `volume_up` / `volume_down` / `volume_off` (Material Symbol)
- [x] Popout: VolumePopout (level bar, mute hint)

**Wifi**
- [x] Icon: `wifi` (Material Symbol)
- [x] Popout: PlaceholderPopout
- [ ] Popout: real wifi controls (SSID, signal strength, saved networks)

**Bluetooth**
- [x] Icon: `bluetooth` (Material Symbol)
- [x] Popout: PlaceholderPopout
- [ ] Popout: real bluetooth controls (connected devices, toggle)

**Battery**
- [x] Icon: battery state icons (Material Symbol)
- [x] Popout: BatteryPopout (percent, capacity bar, charging status)

### --- gap ---

### Power (prominent, standalone)
- [x] Icon: `power_settings_new` (Material Symbol, red)
- [x] Popout: PlaceholderPopout
- [ ] Popout: real session actions (shutdown, reboot, logout, suspend, hibernate)

## Remaining Work

1. [ ] Fix tray menu click interaction (MouseArea not receiving events)
2. [ ] Add submenu navigation (StackView or nested QsMenuOpener for `hasChildren` entries)
3. [ ] Build calendar popout (calendar grid, events)
4. [ ] Build wifi popout (NetworkManager integration)
5. [ ] Build bluetooth popout (bluez integration)
6. [ ] Build power popout (session actions via systemd/logind)
7. [ ] Build spotify MPRIS popout (now-playing, controls, album art)
