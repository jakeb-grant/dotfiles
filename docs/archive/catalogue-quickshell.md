# Catalogue of the current Quickshell shell

What the shell does as a person experiences it, read from the source on 2026-10-31. Nothing was run, so everything here comes from reading the code and docs.

Source files are relative to `~/.local/share/chezmoi/dot_config/quickshell/` unless the path starts with `dot_`, in which case it is relative to `~/.local/share/chezmoi/`.

**Tags**

- **MOUSE ONLY**: no keyboard route to this function was found.
- **Partial**: only part of the function has a keyboard route; the row says which part.
- **Unfinished?**, **Unused?**, **Can't tell**: see the row, and the lists near the end.

Rows carry an ID so features can be picked by number.

## Keys at a glance

Every key below is bound in `dot_config/hypr/hyprland.lua.tmpl`. Super is the modifier.

| Key | Does |
|---|---|
| Super+Space | Open or close the launcher |
| Super+L | Lock the session |
| Super+, | Dismiss the newest notification |
| Super+Shift+, | Dismiss all notifications |
| Super+Shift+T | Switch the bar between side and top |
| Print | Screenshot a selected region |
| Shift+Print | Screenshot the full screen |
| Super+Print | Colour picker (`hyprpicker -a`; no shell surface involved) |
| Volume up / down / mute keys | Change volume; the OSD shows it; repeat on hold; work while locked |
| Mic mute key | Toggle the mic; the OSD and bar show it; works while locked |
| Brightness up / down keys | Change brightness; the OSD shows it; repeat on hold; work while locked |
| Play / Pause, Next, Previous keys | Control the active media player; the OSD shows the track; work while locked |

Compositor keys whose result shows on the bar's workspace row:

| Key | Does |
|---|---|
| Super+1..9, Super+0 | Go to workspace 1..9, 10 |
| Super+Shift+1..9, Super+Shift+0 | Move the window to workspace 1..9, 10 |
| Super+Tab, Super+Shift+Tab | Next, previous existing workspace |
| Super+Ctrl+Tab | Last workspace |
| Super+scroll, three-finger horizontal swipe | Change workspace |
| Super+S, Super+Shift+S | Toggle the scratchpad, move a window to it |

The shell registers seven global shortcuts: lock, launcher, three media, two notification. It has no command-line or IPC control surface (`shell.qml`; no `IpcHandler` anywhere).

## Bar

One bar per monitor, as a floating rounded strip. Left to right (or top to bottom in side mode): logo, workspaces, tray, clock, status icons, power.

| ID | Feature | How it's reached | File |
|---|---|---|---|
| B1 | Bar on every monitor, reserving screen space so tiled windows don't slide under it | Always there | `modules/drawers/Drawers.qml`, `modules/drawers/Exclusions.qml`, `modules/bar/BarWrapper.qml` |
| B2 | Two layouts: vertical on the left, or horizontal along the top. No right or bottom option. The choice survives theme changes | Super+Shift+T, or launcher Keybinds row | `utils/Theme.qml`, `dot_local/bin/executable_toggle-bar-mode` |
| B3 | Bar fades away while the monitor's workspace has a fullscreen window | Automatic | `modules/drawers/Drawers.qml` |
| B4 | Bar items drop in one after another at shell start | Automatic | `modules/bar/BarContent.qml` |
| B5 | Workspace row: one slot per workspace assigned to that monitor, a sliding accent pill on the active one, and a different glyph for empty and occupied | Passive. See C1 | `modules/bar/components/Workspaces.qml`, `services/Hypr.qml` |
| B6 | Window icons inside each workspace slot, one per app category rather than per window. An app with no known category shows a terminal icon. Slots grow to fit | Passive | `modules/bar/components/Workspaces.qml`, `utils/Icons.qml` |
| B7 | Click a workspace slot to go to it. Clicking an icon also goes to the workspace, not that window | Mouse, or Super+digit | `modules/bar/components/Workspaces.qml` |
| B8 | Tray icons from running apps, shown only when there are any. All items are shown; see U1 | Passive; hover opens P27 | `modules/bar/components/TrayOverflow.qml` |
| B9 | Clock, 12-hour only with am/pm. Stacked in side mode, one line in top mode. Its calendar glyph fills with accent on hover | Passive; hover opens P14 | `modules/bar/BarContent.qml`, `services/Clock.qml` |
| B10 | Volume icon that changes with level and mute | Passive; hover opens P5 | `modules/bar/components/StatusIcons.qml` |
| B11 | Scroll on the volume icon: 5% per notch, touchpad-safe, up to 100% | Mouse, or volume keys | `modules/bar/components/StatusIcons.qml` |
| B12 | Brightness icon with seven levels, shown only if a backlight exists | Passive; hover opens P11 | `modules/bar/components/StatusIcons.qml`, `services/Brightness.qml` |
| B13 | Scroll on the brightness icon: 5% per notch, never below 1% | Mouse, or brightness keys | `modules/bar/components/StatusIcons.qml` |
| B14 | Wi-Fi icon with five signal levels and a disconnected glyph, refreshed every 3 s | Passive; hover opens P15 | `modules/bar/components/StatusIcons.qml`, `services/Network.qml` |
| B15 | Bluetooth icon: off, on, connected (accent) | Passive; hover opens P20 | `modules/bar/components/StatusIcons.qml` |
| B16 | Battery icon: level, charging glyph, red/yellow/green. Pulses gently, and faster below 15% while discharging. Hidden without a laptop battery | Passive; hover opens P12 | `modules/bar/components/StatusIcons.qml`, `services/Battery.qml` |
| B17 | Do Not Disturb indicator, shown only while DND is on | Passive | `modules/bar/components/StatusIcons.qml` |
| B18 | Muted-mic indicator in red, shown only while the mic is muted | Passive | `modules/bar/components/StatusIcons.qml` |
| B19 | Distro logo and red power icon as entry points to their popouts | Hover opens P2 and P26 | `modules/bar/BarContent.qml` |

## Bar popouts

Panels that open from bar items. They never take keyboard focus, so nothing inside one responds to keys. That was an owner decision (`docs/ux-backlog.md`, session 6): keyboard access goes through the launcher.

| ID | Feature | How it's reached | File |
|---|---|---|---|
| P1 | Popout behaviour: opens on hover and grows out of the item. Survives the gap as the cursor crosses to it. Closes 200 ms after the mouse leaves, or on a click outside. Morphs size when moving between items. No key closes it | **MOUSE ONLY** | `modules/bar/popouts/PopoutWrapper.qml`, `services/Popout.qml` |

**System** (hover the logo)

| ID | Feature | How it's reached | File |
|---|---|---|---|
| P2 | Machine facts: distro, kernel, uptime, hostname, login shell, native and AUR package counts. "Arch Linux" is fixed text | **MOUSE ONLY** (launcher About shows similar facts through `fastfetch`) | `modules/bar/popouts/SystemPopout.qml`, `services/SystemInfo.qml` |
| P3 | Live CPU, RAM, CPU temperature and root-disk bars, green to red, refreshed every 3 s while open | **MOUSE ONLY** (launcher Process Manager opens `btop`) | `modules/bar/popouts/SystemPopout.qml`, `services/SystemStats.qml` |
| P4 | GPU section when a GPU is found: usage, temperature, and VRAM except on Intel. See U5 | **MOUSE ONLY** | `modules/bar/popouts/SystemPopout.qml`, `services/SystemStats.qml` |

**Volume and media** (hover the volume icon)

| ID | Feature | How it's reached | File |
|---|---|---|---|
| P5 | Volume percent and drag slider; click the icon to mute. See U3 | Mouse, or volume and mute keys | `modules/bar/popouts/VolumePopout.qml`, `services/Audio.qml` |
| P6 | Now Playing: album art, title, artist, elapsed and total time. Shown only with a player. Picks the first playing player, then paused, then stopped | **Partial**: media keys flash title and artist on the OSD; art and times are mouse only | `modules/bar/popouts/VolumePopout.qml`, `services/Players.qml` |
| P7 | Seek bar | **MOUSE ONLY** | `modules/bar/popouts/VolumePopout.qml` |
| P8 | Previous, play/pause, next buttons | Mouse, or media keys | `modules/bar/popouts/VolumePopout.qml` |
| P9 | Output device list with the active one ticked; click to switch | Mouse, or launcher Audio Output | `modules/bar/popouts/VolumePopout.qml` |
| P10 | Input (microphone) device list; click to switch | **MOUSE ONLY** | `modules/bar/popouts/VolumePopout.qml` |

There is no per-app volume, mic level control, or mic mute button anywhere in the shell. Mic mute is the hardware key only.

**Brightness** (hover the brightness icon)

| ID | Feature | How it's reached | File |
|---|---|---|---|
| P11 | Brightness percent and drag slider. Controls the backlight `brightnessctl` finds first; no external monitor control. See U3 | Mouse, or brightness keys | `modules/bar/popouts/BrightnessPopout.qml`, `services/Brightness.qml` |

**Battery** (hover the battery icon)

| ID | Feature | How it's reached | File |
|---|---|---|---|
| P12 | Percent, Charging or Discharging, capacity bar. No time estimate. A full battery reads "Charging" | **MOUSE ONLY** | `modules/bar/popouts/BatteryPopout.qml`, `services/Battery.qml` |
| P13 | Power profile switch: Power Saver, Balanced, Performance | **MOUSE ONLY**. A code comment mentions a profile keybind, but none exists in `dot_config/hypr` | `modules/bar/popouts/BatteryPopout.qml`, `services/Battery.qml` |

**Calendar** (hover the clock)

| ID | Feature | How it's reached | File |
|---|---|---|---|
| P14 | Month grid, Monday first, today highlighted, weekday and time below. Previous and next month arrows; click the title to return to this month. No events. See U2 | **MOUSE ONLY** | `modules/bar/popouts/CalendarPopout.qml` |

**Wi-Fi** (hover the Wi-Fi icon; uses `iwd` only)

| ID | Feature | How it's reached | File |
|---|---|---|---|
| P15 | Current network name, IP address, band | **Partial**: launcher Wi-Fi shows the name and "Connected"; IP and band are mouse only | `modules/bar/popouts/WifiPopout.qml`, `services/Network.qml` |
| P16 | Scanned network list with signal icons; click a saved network to connect. Unsaved networks are not clickable here | Mouse, or launcher Wi-Fi | `modules/bar/popouts/WifiPopout.qml` |
| P17 | Disconnect button | Mouse, or launcher Wi-Fi | `modules/bar/popouts/WifiPopout.qml` |
| P18 | Rescan button with spinner; also scans on open | Mouse; opening launcher Wi-Fi also scans | `modules/bar/popouts/WifiPopout.qml` |
| P19 | "Open Impala" terminal app, where new networks and passwords are handled | Mouse, or Enter on an unsaved network in launcher Wi-Fi | `modules/bar/popouts/WifiPopout.qml` |

There is no Wi-Fi on/off switch and no wired or VPN status.

**Bluetooth** (hover the Bluetooth icon)

| ID | Feature | How it's reached | File |
|---|---|---|---|
| P20 | First connected device's name and battery percent | Mouse, or launcher Bluetooth | `modules/bar/popouts/BluetoothPopout.qml`, `services/Bluetooth.qml` |
| P21 | Device list sorted connected, paired, rest, with type icon and status. Click to connect; an unpaired device pairs first | Mouse, or launcher Bluetooth | `modules/bar/popouts/BluetoothPopout.qml` |
| P22 | Disconnect button, for the first connected device only. Clicking a connected row does nothing | Mouse, or launcher Bluetooth (any device) | `modules/bar/popouts/BluetoothPopout.qml` |
| P23 | Scan for new devices (5 s) | **MOUSE ONLY**. The launcher only re-reads known devices | `modules/bar/popouts/BluetoothPopout.qml`, `services/Bluetooth.qml` |
| P24 | Adapter power toggle | **Partial**: launcher can turn it on, only the mouse can turn it off | `modules/bar/popouts/BluetoothPopout.qml` |
| P25 | "Open bluetui" terminal app | **MOUSE ONLY** | `modules/bar/popouts/BluetoothPopout.qml` |

**Power** (hover the power icon)

| ID | Feature | How it's reached | File |
|---|---|---|---|
| P26 | Shut Down, Restart, Sleep, Lock Screen, Log Out. One click acts, with no confirmation | Mouse, or L25 and Super+L | `modules/bar/popouts/PowerPopout.qml` |

**Tray menus** (hover a tray icon)

| ID | Feature | How it's reached | File |
|---|---|---|---|
| P27 | App's own menu, with icons, checkboxes and radio items. Clicking an item leaves the popout open | Mouse, or launcher Tray | `modules/bar/popouts/TrayMenuPopout.qml` |
| P28 | Nested submenus with a Back button | Mouse, or launcher Tray with Enter and Esc | `modules/bar/popouts/TrayMenuPopout.qml` |

Tray icons have no click or right-click action. An app's primary action (normally a left click) exists only as a launcher row; see L14.

## Launcher

An island at the bottom centre of the focused monitor, with the search box below the results. It is the shell's one keyboard surface.

| ID | Feature | How it's reached | File |
|---|---|---|---|
| L1 | Open and close. Takes keyboard focus while open; a click outside closes it | Super+Space; Esc closes from the top level | `services/Launcher.qml`, `modules/drawers/Drawers.qml` |
| L2 | List movement: Down or Tab, Up or Shift+Tab, Enter runs, Esc goes back one level. No wrap-around, Page keys or Home/End. Rows also take a click | Keyboard or mouse | `modules/launcher/LauncherPanel.qml` |
| L3 | Home list with no query: Keybinds, Clipboard, Notifications, Wi-Fi, Bluetooth, Audio Output, Tray (only if there are items), Themes, Wallpapers, Do Not Disturb, Upkeep, Display, About, Windows VM. Wi-Fi and Bluetooth rows show the current network and device | Open the launcher | `services/LauncherProviders.qml` |
| L4 | App search over name, description and categories. Terminal apps open in Ghostty. Windows land on the workspace that was active at launch | Type, Enter | `services/Launcher.qml` |
| L5 | Open-window search by title and class; Enter focuses that window. No dedicated window list | Type, Enter | `services/Launcher.qml` |
| L6 | Combined search across apps, windows, keybinds, actions, submenu names and clipboard; top 20 by score | Type | `services/Launcher.qml` |
| L7 | Calculator: start with `=`, e.g. `=2^10`. Digits and `+ - * / ( ) % ^` only; other characters are dropped silently. Enter copies the result | Type `=`, Enter | `services/Launcher.qml` |
| L8 | Keybinds list: 31 rows showing key and name; Enter runs the action. Filterable. Hand-kept copy of the Hyprland binds; see U6 | Launcher, "Keybinds" | `services/LauncherProviders.qml` |
| L9 | Clipboard history from `cliphist`, latest 100 text and image entries (images as a text label, no preview). Enter copies back to the clipboard and does not paste. No delete or pin | Launcher, "Clipboard" | `services/Launcher.qml` |
| L10 | Clipboard entries also appear in combined search, ranked low | Type | `services/Launcher.qml` |
| L11 | Wi-Fi list: scans on open, signal icons, Connected, Saved, or security label. Enter on connected disconnects, on saved connects, on unsaved opens Impala. No confirmation | Launcher, "Wi-Fi" | `services/Launcher.qml` |
| L12 | Bluetooth list with battery percent. Enter toggles connect, pairing first if needed. When off, shows one "Turn on" row | Launcher, "Bluetooth" | `services/Launcher.qml` |
| L13 | Audio Output list, active marked; Enter switches. There is no matching input list | Launcher, "Audio Output" | `services/Launcher.qml` |
| L14 | Tray list, then each app's menu with nested levels. Esc pops one level. An "Activate" row gives the app's primary action. An app without a menu activates directly on Enter | Launcher, "Tray" | `services/Launcher.qml` |
| L15 | Open any submenu by name from search, e.g. `wifi` then Enter | Type, Enter | `services/Launcher.qml` |
| L16 | Filter inside the open submenu. Every word must match | Type | `services/Launcher.qml` |
| L17 | Do Not Disturb toggle; row shows "On" | Launcher | `services/LauncherProviders.qml` |
| L18 | Upkeep: runs the `upkeep` maintenance tool in Ghostty | Launcher | `services/LauncherProviders.qml` |
| L19 | Display: runs `hyprpier mgr` in Ghostty | Launcher | `services/LauncherProviders.qml` |
| L20 | About: runs `fastfetch` in Ghostty | Launcher | `services/LauncherProviders.qml` |
| L21 | Process Manager: runs `btop` in Ghostty. In search only, not on the home list | Type, Enter | `services/LauncherProviders.qml` |
| L22 | Windows VM: runs `win-vm` | Launcher | `services/LauncherProviders.qml` |
| L23 | Screenshots and colour picker as rows. The full-screen row waits 0.4 s so the launcher isn't captured | Launcher, Keybinds or search | `services/LauncherProviders.qml` |
| L24 | Window actions as rows: close, float, fullscreen, pin, swap, resize, workspace moves, scratchpad, lock, bar mode. Runs on the focused window | Launcher, Keybinds or search | `services/LauncherProviders.qml` |
| L25 | Logout, Suspend, Reboot, Shutdown rows. These have no key of their own, and run at once with no confirmation | Launcher, Keybinds or search | `services/LauncherProviders.qml` |

## Notifications

The shell is the notification daemon. Cards stack at the top right.

| ID | Feature | How it's reached | File |
|---|---|---|---|
| N1 | Cards with image or app icon, app name, summary (2 lines), body (3 lines) | Automatic | `modules/notifications/NotificationCard.qml`, `services/Notifications.qml` |
| N2 | Critical notifications get a red stripe | Automatic | `modules/notifications/NotificationCard.qml` |
| N3 | Auto-dismiss after 5 s or the sender's timeout. See U4 | Automatic | `services/Notifications.qml` |
| N4 | Hovering a card pauses its timer | **MOUSE ONLY** | `modules/notifications/NotificationCard.qml` |
| N5 | Close button on the card | Mouse, or N7 for the newest card | `modules/notifications/NotificationCard.qml` |
| N6 | Action buttons from the sender, e.g. Open on a screenshot. Clicking the card body does nothing | **MOUSE ONLY** | `modules/notifications/NotificationCard.qml` |
| N7 | Dismiss the newest card | Super+, | `shell.qml`, `services/Notifications.qml` |
| N8 | Dismiss all cards | Super+Shift+, | `shell.qml`, `services/Notifications.qml` |
| N9 | At most 5 cards; older ones are dropped but stay in history | Automatic | `services/Notifications.qml` |
| N10 | Cards appear on every monitor at once | Automatic | `modules/drawers/Drawers.qml` |
| N11 | Do Not Disturb: non-critical notifications show no card but are kept in history; critical ones still show. Survives live reloads, cleared on full restart | Launcher (L17); bar shows B17 | `services/Notifications.qml` |
| N12 | History: last 50 with app name and age, critical marked. Enter copies summary and body. Text only, with no actions. Filterable; not in combined search. Survives live reloads, cleared on full restart | Launcher, "Notifications" | `services/Launcher.qml`, `services/Notifications.qml` |

There is no separate notification centre panel. The launcher list is the only history view.

## OSD

A small click-through island, bottom centre, on every monitor, for about 1.4 s.

| ID | Feature | How it's reached | File |
|---|---|---|---|
| O1 | Volume: icon, bar, percent or "Muted". Also fires on bar scroll and on device changes | Volume and mute keys | `modules/osd/OsdOverlay.qml`, `services/Osd.qml` |
| O2 | Brightness: icon, bar, percent | Brightness keys | `modules/osd/OsdOverlay.qml`, `services/Osd.qml` |
| O3 | Mic: "Microphone muted" or "Microphone on", no bar | Mic mute key | `modules/osd/OsdOverlay.qml`, `services/Osd.qml` |
| O4 | Media: play or pause icon, title, artist, or "Nothing playing" | Play/Pause, Next, Previous keys | `modules/osd/OsdOverlay.qml`, `shell.qml` |
| O5 | Stays hidden while the matching popout is open, and for the first 2 s after shell start | Automatic | `services/Osd.qml` |
| O6 | Shows over fullscreen windows | Automatic | `modules/drawers/Drawers.qml` |

## Lock screen

| ID | Feature | How it's reached | File |
|---|---|---|---|
| K1 | Lock the session | Super+L; launcher; power popout; after 10 min idle; before sleep | `shell.qml`, `services/LockScreen.qml`, `dot_config/hypr/hypridle.conf` |
| K2 | Idle view: large clock, am/pm and date | Automatic on lock | `modules/lockscreen/LockSurface.qml` |
| K3 | Background: blurred, darkened current wallpaper (first image of a set) with a vignette, slowly drifting colour blobs and faint rings. Solid colour if there's no wallpaper | Automatic | `modules/lockscreen/LockSurface.qml` |
| K4 | Password entry: any key or click swaps the clock for a password pill. Enter submits through PAM, using hyprlock's PAM config | Keyboard or mouse | `modules/lockscreen/LockSurface.qml`, `services/LockScreen.qml` |
| K5 | Each typed character shows in plain text for 120 ms before turning into a dot | Automatic | `modules/lockscreen/LockSurface.qml` |
| K6 | Status line: Locked, Enter password, Authenticating | Automatic | `modules/lockscreen/LockSurface.qml` |
| K7 | Failed attempt: pill shakes, dots and rings go red, message for 2 s (incorrect password, too many attempts, or the PAM error) | Automatic | `modules/lockscreen/LockSurface.qml`, `services/LockScreen.qml` |
| K8 | Caps Lock warning under the pill, including when it was already on before locking | Automatic | `modules/lockscreen/LockSurface.qml`, `services/LockScreen.qml` |
| K9 | Back to the clock: Esc clears the input, or 15 s with empty input | Esc, or automatic | `modules/lockscreen/LockSurface.qml` |
| K10 | Mouse cursor hides after 3 s still | Automatic | `modules/lockscreen/LockSurface.qml` |
| K11 | Fade-out animation on unlock | Automatic | `modules/lockscreen/LockSurface.qml` |

No media, notification or battery information appears on the lock screen, and it has no power buttons.

## Wallpapers

| ID | Feature | How it's reached | File |
|---|---|---|---|
| W1 | Picker inside the launcher: two slanted thumbnail strips, "Wallpapers" and "Sets". Left, Right or Tab move; Up and Down change strip; Enter applies and stays open; Esc goes back. No Shift+Tab or search. Mouse hover selects, click applies | Launcher, "Wallpapers" | `modules/wallpaper/WallpaperPicker.qml`, `modules/wallpaper/WallpaperBand.qml` |
| W2 | Picker shows only wallpapers tagged for the active theme, including wildcards | Automatic | `services/Wallpaper.qml` |
| W3 | Sets: one image per monitor, assigned left to right, repeating if monitors outnumber images. The config currently lists 15 singles and 7 sets | Picker | `services/Wallpaper.qml`, `dot_config/wallpapers/wallpapers.json` |
| W4 | Current wallpaper marked with an accent strip; selected thumbnail shows its name | Picker | `modules/wallpaper/WallpaperBand.qml` |
| W5 | Applied with a 1 s centre-out transition through `awww` | Automatic | `services/Wallpaper.qml` |
| W6 | Last choice restored at shell start | Automatic | `services/Wallpaper.qml` |
| W7 | Changing theme switches to that theme's configured default wallpaper | Automatic | `services/Wallpaper.qml` |
| W8 | A set is re-applied when monitors change | Automatic | `services/Wallpaper.qml` |
| W9 | Edits to `wallpapers.json` show up live | Automatic | `services/Wallpaper.qml` |

## Themes

| ID | Feature | How it's reached | File |
|---|---|---|---|
| T1 | Theme list with colour swatches and the active one marked. Enter applies and stays open. Ten palettes: Catppuccin Mocha, Macchiato, Frappé, Latte; Everforest and Everforest Light; Nord; Rosé Pine, Moon, Dawn | Launcher, "Themes" | `services/Launcher.qml`, `dot_local/bin/executable_theme-switch` |
| T2 | The whole shell animates to new colours over 400 ms with no restart. The lock screen adapts for light themes | Automatic | `utils/Theme.qml` |
| T3 | Translucent surfaces with frosted blur behind them | Automatic | `utils/Theme.qml`, `dot_config/hypr/hyprland.lua.tmpl` |

The same switch also recolours other apps (GTK, Ghostty, Zed, btop and others) through `theme-switch`, outside the shell.

## Screenshot, battery and idle behaviour

| ID | Feature | How it's reached | File |
|---|---|---|---|
| S1 | Screenshot saved to `~/Pictures/Screenshots` and copied to the clipboard, then a card with a thumbnail. Cancelling a region selection stays silent | Print, Shift+Print, or L23 | `dot_local/bin/executable_screenshot` |
| S2 | Screenshot card's Open button | **MOUSE ONLY** | `dot_local/bin/executable_screenshot` |
| S3 | Screenshot failures show as critical cards | Automatic | `dot_local/bin/executable_screenshot` |
| S4 | Low battery card at 15%, critical card at 5%, once each until the level recovers | Automatic | `services/Battery.qml` |
| S5 | Screens turn off after 30 min idle. No automatic suspend, removed on purpose because of a GPU driver crash | Automatic | `dot_config/hypr/hypridle.conf`, `dot_config/hypr/README.md` |
| S6 | Bar's workspace assignment updates when monitors are added or removed and when config reloads | Automatic | `services/Hypr.qml` |

## Mouse-only summary

**No keyboard route at all**

- All popout behaviour, including closing a popout (P1)
- System facts and live stats (P2, P3, P4)
- Seek within a track (P7)
- Choosing the microphone input device (P10)
- Battery details (P12) and power profile (P13)
- Calendar (P14)
- Bluetooth scan for new devices (P23) and "Open bluetui" (P25)
- Pausing a notification's timer (N4)
- Notification action buttons (N6), including the screenshot Open button (S2)

**Only partly reachable by keyboard**

- Now Playing: art and times (P6)
- Wi-Fi: IP address and band (P15)
- Bluetooth: turning the adapter off (P24)

## Looks unfinished, stubbed or unused

- **U1. Tray "overflow".** The component is named `TrayOverflow`, but it shows every item and has no overflow behaviour.
- **U2. Calendar days.** Day cells show a hover highlight and a hand cursor, but clicking them does nothing.
- **U3. "Scroll or drag to adjust" hint.** The volume and brightness popouts show this, but the only scroll handlers are on the bar icons. Scrolling on the popout appears to do nothing.
- **U4. Notifications that ask to stay.** The server advertises persistence, but a sender timeout of 0 or none gets the default 5 s, and critical cards expire too. The backlog accepts this for critical cards.
- **U5. GPU figures on Intel.** GPU temperature is the CPU temperature, by design per a code comment. Usage reads an i915-style file and computes 100% if the file is missing. `dot_config/hypr/README.md` says this machine uses the `xe` driver, so usage may be stuck at 100%. Can't tell without running it.
- **U6. Keybinds list drift.** The launcher table is a hand-kept copy, flagged as a hazard in `docs/ux-backlog.md`. It omits Super+digit, Super+Shift+digit, arrow focus, Super+P, Super+J, Super+Shift+S and all hardware keys. Its Terminal and Editor rows run slightly different commands from the real binds (`ghostty` against `ghostty +new-window`, `zeditor` against `zeditor --wait`).
- **U7. hyprlock.** A themed `hyprlock.conf.tmpl` exists and the README calls it a fallback, but no key or idle rule starts it. Only its PAM config is used.
- **U8. `nm-applet` at autostart.** Hyprland autostarts it, but the shell's network features use `iwd`, and `docs/iwd_impala.md` says to disable NetworkManager when moving to iwd. Possibly a leftover, or a stray tray icon.
- **U9. Unused code, no visible effect:** `Brightness.increment` and `decrement`, `Audio.toggleSourceMute`, `Hypr.workspaceIdsFor`, `Network.label`, `Battery.label`. These are the ones spotted; this isn't an exhaustive search.
- **U10. "Notification center."** The dotfiles' `CLAUDE.md` uses this name, but no such panel exists; see N12.

## Couldn't tell from reading alone

- **C1. Empty workspace row.** The row shows only workspaces with a monitor rule from Hyprland. `hyprland.lua.tmpl` and the default monitors script define none, so rules presumably come from `hyprpier`. A monitor without rules would show an empty row, and a workspace without a rule would not appear.
- **C2. Fullscreen.** The launcher, popouts and notification cards share a window on the Top layer, and project comments say Hyprland draws fullscreen windows above that layer. So cards may be hidden during fullscreen, and the launcher may take keyboard focus while hidden.
- **C3. OSD over the lock screen.** Volume and media keys work while locked, but whether the OSD is visible above the lock surface isn't clear.
- **C4. Lock on several monitors.** Each monitor gets its own lock surface, and typed dots are tracked per surface. What the other monitors show while typing isn't clear.
- **C5. Media OSD icon.** It reads the player state right after the key press, so it may show the state before the change takes effect.
- **C6. Replaced notifications.** Behaviour when a sender updates an existing notification isn't handled visibly in shell code. It depends on Quickshell's server.
- **C7. Tray contents.** Which apps populate the tray, and whether items with custom icon paths resolve correctly, depends on the running system.
- **C8. Whether backlog items were later confirmed.** See "Never confirmed by the owner" below.

## Unresolved wishes from the backlog docs

Both `docs/ux-backlog.md` and `docs/design-review-backlog.md` describe themselves as complete. Neither lists an open feature request. What remains:

**Never confirmed by the owner.** The docs mark these "owner-verify" and don't record an outcome:

- Connect and disconnect Wi-Fi through the launcher
- Bluetooth connect through the launcher with real earbuds
- Switching audio output with something plugged in. WirePlumber refused to switch to unavailable ports on this machine, in the popout as well
- Caps Lock hint on a real lock
- Clock hover affordance
- Real mic mute key
- A real discharge past 15%
- Real Print and Shift+Print keys, and the Open button
- Scroll-to-adjust feel on the bar icons

**Known problems left as they are**

- Critical cards still auto-expire (accepted)
- A full shell restart clears DND and notification history (accepted)
- With the launcher open, the DND row's subtitle stays stale until reopened (accepted)
- A popout open on one monitor suppresses the matching OSD on all monitors (known cosmetic)
- Device switches flash the volume OSD (accepted as a feature)
- A shell reload with the cursor exactly at screen centre opens the calendar popout (found, not fixed)
- `chezmoi apply` doesn't reliably trigger a live reload of the shell (worked around by touching `shell.qml`)
- The launcher keybinds table can drift from the Hyprland config (noted hazard; see U6)

**Deferred**

- Splitting the lock screen file; no visible effect, deferred because a regression there could lock the owner out
- Moving wallpapers out of git; the owner chose to keep them there for now
- Restoring automatic suspend once the `xe` driver is stable, with a re-test procedure in `dot_config/hypr/README.md` (from that README, not the backlogs)

**Decided against**

- A notification when the bar mode changes
- Tooltips on bar icons
- Keyboard focus inside popouts; keyboard access goes through the launcher instead

## Coverage

All 59 files under `dot_config/quickshell/` were read or checked, except that the small popout components and two utility files were only searched for input handling. `docs/ux-backlog.md`, `docs/design-review-backlog.md`, the Hyprland binds, `hypridle.conf`, and the `toggle-bar-mode` and `screenshot` scripts were read. `theme-switch` was only searched. Encrypted files and `dot_config/age`, `dot_config/private_1Password` were not read.
