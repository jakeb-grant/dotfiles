# Feature list (draft for scoping)

## Decided so far (2026-10-31)

- One island, keyboard first and minimal. It replaces the bar and the hover popouts. (2026-11-04: three islands, then a full-width bar, plain, pill-shaped and glass, were tried and dropped; the owner preferred this one. They are in the history from `ce41a0f` to `47a7acc`.)
- The island never changes size. Its resting size has room for anything that goes in it.
- The launcher opens from the island, with keyboard navigation to every module worth keeping.
- Volume and brightness changes show on the island itself, not in a separate OSD.
- Layout: workspaces left, status and clock right.
- Theme: `theme-switch` stays in charge. A `from file` service reads `active.json` and `palette(...)` maps its names to Strand's roles, so every `$` token and built-in widget follows it and springs on a swap. Falls back to `from`'s colours if the file is missing or broken. Wallpaper still to come.
- Launcher (`strand/launcher.strand`): grows out of the island on the focused monitor: it widens, then drops down, and closes the other way round, rolling up and narrowing back into the island (a click away is the one close that just fades). Just the menu of pages when it opens (apps come up as you type, or under Apps), typing searches everything, `=` starts a sum for `qalc` (Enter copies the answer). Pages for apps, workspaces (each in use by number, with its apps' icons, its main window's title and your monitors as small tiles with its own lit; Enter goes there, typing finds a workspace by what is open on it, and a preview beside the list shows it as it is: its monitor in proportion with the wallpaper there and each window live where it sits, the focused one ringed, beside a list of its apps), Wi-Fi (join, leave, radio on and off; a secured network not saved asks its password in place of the search, Del forgets a saved one, a "Hidden network" row joins one by name), Bluetooth (connect, pair nearby, power; a device pairing that asks for a PIN, a passkey or a code to confirm opens the launcher here with the question in place of the search, Enter answers, Esc refuses), sound (output and microphone: each one's live wave, mute with Enter; every row, device or program, with its level as a figure and a bar set with the arrows (or a scroll on the output and microphone); the device in use first, in the accent, headphones and monitor speakers by their own symbol; each program playing or recording, with its icon, moved to the next device with Enter; a Bluetooth headset's microphone wakes on its own while an app records, and the row says so until then), clipboard history (Enter copies), notifications (below), drives (listed while one is plugged in: Enter mounts or unmounts a filesystem, a mounted one showing its path and how full it is; an Eject row makes the drive safe to pull, says "ejecting" meanwhile and "Safe to remove" in the hint row once it is), themes (theme-switch's list with six colours each, opening on the theme in use; the whole shell takes the colours of the theme you move over until Esc or Enter, and a preview beside the list shows the wallpaper it would bring and its palette) media (every player, the playing first, opening on the one the island follows: its art, title and player; a card beside the list with the art (16:9 for a video), title, artist and album, shuffle, 15 s back, previous, play or pause, next, 15 s on and repeat (shuffle and repeat only where the player has them), the time with a scrubber, and the art as a soft wash behind; Enter plays or pauses the selected one, pausing the others it would play over, and the island follows it; the arrows change track and with Shift skip 15 s; a row after them sets the leading player's own volume) and wallpapers (those `wallpapers.json` gives the theme in use, with thumbnails, and a preview of the selected one on your monitors as they're laid out; Enter puts one up with awww, a set one image per monitor left to right; a theme switched anywhere keeps the wallpaper if it suits the new theme, else puts up the one `wallpapers.json` names for it) tray (listed while an app has a tray item: each app with its icon, its tooltip and an orange dot while it wants you; Enter is its own click, → opens its menu right there as rows, check marks, radio buttons, shortcuts and a submenu one deep included, ← or Esc going back out; an app that is only a menu opens it here too) and power (the power profile as one row with a segmented control, the lit segment sliding, Enter or the arrows moving it; the battery with its last three hours as a graph, the time left and its charge; then lock, suspend, restart and shut down, the last three asking for Enter again within three seconds, a red line draining under the ask). Workspaces, clipboard, notifications, themes and wallpapers widen to show the selected row beside the list, on a card read from the top: a copied text or image whole with its size and time (Delete removes it from the history); a notification's app, time, whole message and its buttons (Alt+1 to 3, Del, or a click), and with none selected a line for each app with its count and newest summary; a theme's wallpaper on your monitors (named) and its palette as a ramp of neutrals and its accents. Wi-Fi and Bluetooth stay narrow and carry it in the rows: the network joined or the devices connected first, each with its signal or battery as a figure and a short bar, the page's state on its switch row ("on · Meniscus · 78%"). Names and prose are in IBM Plex Sans, figures, times and code in JetBrains Mono; the selection is a wash of the accent eased out from the left edge, with a glowing rail the row's height and a faint sheen drifting slowly across it, gliding from row to row under the list as the selection moves (the selected row steps right off the rail), and what's connected, on or in use takes the accent too. The hint row lists Enter, Esc and the page's own keys; each page's row on the home list ends in its Alt letter as keycaps, lit while Alt is held; on the other pages holding Alt crossfades the hint row into each page's icon and letter (Tray, Media and Drives only while they have something); Alt+A, W, N, B, S, C, I, T, L, R, M, D, K and P jump to them (a click on a letter too); Esc clears, goes back, then closes. The Keys page (Alt+K, `launcher.keys_key`) lists Hyprland's own binds, read from `hyprctl binds -j` so it never drifts from them: each bind's description in hyprland.lua, "Group: what it does", puts it in a group (Shell, Apps, Windows, Arrange, Workspaces, Sound, Screen; one without a description under Other), binds sharing a description are one line (1 to 0 as one range, the four arrows as one key), and the list holds the groups while the pane beside it shows the selected group's lines with their keys as keycaps; a search lists the lines that match, the pane showing the selected one's group with it lit. The mouse does the same: rows and the hint row's letters click, a click away closes it, and so does leaving it for a second when it was opened with a click and nothing typed since (opened from the keyboard, it stays). On the island anything but a workspace opens it; the Wi-Fi, Bluetooth, volume and drive symbols open their page, and a scroll on the volume symbol sets it.
- Built so far: the island, 640×34 (the launcher's width, so it only drops out of it) with 12 px squircle corners (the launcher and a notification keep the same corners as they grow out of it, so only the size changes, the shadow deepening as the launcher drops); that monitor's workspaces as numbered chips (each numbered slot the compositor gives it, empty ones dim) with the icons of the apps on each (each app once, largest window first, up to three, an order that stays put as focus moves; an app that comes widens the chip, its number staying where it is), one accent highlight gliding to the one on screen, a workspace asking for attention turning orange with one pop of its number, a click going there and a scroll stepping through them; a workspace that comes or goes grows or shrinks its chip on the highlight's own spring, so nothing jumps under it; status symbols (Wi-Fi, volume, battery, its figure when under 30 % or charging, plus, to their left so they never move them, a Bluetooth device connected, DND, muted mic, a drive plugged in and a tray app that wants you, by its own icon, while true; the muted mic opens the Sound page, the tray app the Tray page), the date and the clock (its digits rolling on the minute); while something plays and is heard, a live line in the accent, from the bass (left) to the highs (right), its ends fading out, laid over the island out of its flow so nothing moves for it, filling the room between the workspaces and the symbols (14 px short of each) and following them as they change, and shown only while the workspaces and symbols leave it room (only shown: a click goes through it to the island and opens the launcher; a track that comes on its own nudges it), and a track you skip to with the media keys (`strand toggle island.play_key`, `next_key`, `prev_key`) shows for a moment with its art, title and artist; and volume, the microphone's level, brightness and the keyboard's light on every monitor: when one changes, everything else fades away and the island shows a symbol, a centred bar and the level as a figure (`strand/island.strand`).
- Notifications (`strand/notify.strand`): Strand is the notification server. A notification is the island growing down into a card of its width (640) on the focused monitor: the sender's icon (a bell when it has none), the summary and one line of the body, in IBM Plex Sans. A new one takes the place of the one showing, so they never stack. Each goes after 5 s (the sender's time when shorter), an urgent one (a red edge) after 10 s, held while the pointer is on it, then the card settles back into the island. A click opens it, a right click clears it. It waits while the launcher is open. Until a notification is opened or cleared, the island shows a bell with a dot; a click on it opens the Notifications page, as do Alt+I and `launcher.notes_key`. `strand toggle notify.open_key` opens the one showing, `notify.clear_key` clears it, and `notify.clear_all_key` clears every one. The page has do not disturb (only urgent ones show; the island's bell is crossed out), Clear all, and every one kept, newest first, across restarts, each row with its summary and the start of its body (a red stripe on an urgent one): Enter opens one (or clears it when it has nothing to open), Delete clears it, Alt+1 to 3 press its buttons, which the selected row lists.
- Screen recording (`strand/record.strand`): records the focused monitor with wf-recorder, every frame Hyprland draws, into `~/Videos/strand-<date>-<time>.mp4`. Start and stop it with "Record screen" in the launcher (or type "rec"), a key bound to `strand toggle record.key`, or by clicking the red dot the island shows while it records. If wf-recorder fails, the launcher row says why.

The sections below are the scoping draft of 2026-10-31, written while Quickshell was still the
shell. The switch came on 2026-11-04 (`21cc7a8`), so they are now the record of how the choices were
made, with rows noting where a feature landed; the list above is what's current. IDs refer to
`catalogue-quickshell.md`. Strand facts come from `strand-offers.md`, which was written from reading
the code and docs, so anything marked "to try" there was not run.

## 1. What you have today

### Needed before Quickshell can be turned off

| Feature | Today | On Strand |
| --- | --- | --- |
| Launcher: apps, workspaces, combined search (L1, L4 to L6) | Super+Space | Built in: `apps.search` is fuzzy with frecency and highlights matches |
| Launcher submenus: Wi-Fi, Bluetooth, audio, tray, themes, wallpapers, clipboard, notifications (L3, L9 to L16) | Launcher | Built. Esc goes back (gap 2, closed) |
| Run actions from search: window actions, screenshots, power, tools (L18 to L25) | Launcher | Declared actions |
| Calculator (L7) | `=` in the launcher | Declared action with typed output, such as `qalc` |
| Bar: workspaces, clock, status icons, tray (B1, B5, B8 to B18) | Always there | Built in |
| Notifications: cards, DND, history, dismiss keys (N1 to N12) | Daemon in the shell | Built in; history kept across restarts |
| OSD: volume, brightness, mic, media (O1 to O6) | Keys | Built in |
| Lock screen (K1 to K11) | Super+L, idle, sleep | Built in (`strand/lock.strand`), passing in the lock VM (a wrong password refused, a password typed during a check sent after it, Caps Lock, Esc, a second lock). Tried on this laptop 2026-11-05 and held. Since Strand `073cce42` (2026-11-06) it opens on the blurred desktop, grows out of the island, rests round the time after 8 s alone and wakes on the first key, glows as you type and plays its way back into the bar as it unlocks. Super+L, the launcher's Lock, idle and sleep put it up through logind; hyprlock only while Strand isn't running (`hypr/README.md` has the hand-off). A wrong password reddens its edge and knocks it aside. The launcher's Lock closes the launcher first, so the lock's still of the screen is without it |
| Theme follows `theme-switch` (T1 to T3) | Watches `active.json` | Done. `theme-switch` stays in charge and needs no change. Anything drawn with `$` tokens follows it, the launcher included |
| Wallpaper picker and per-theme wallpaper (W1 to W9) | Launcher, `awww` | Built: `wallpapers.json` as a file service, `awww` as an action, a list with thumbnails and a preview on your monitors in place of the slanted strips |

### Open questions on what to carry over

| Feature | Question |
| --- | --- |
| Hover popouts (P1 to P28) | They're mouse-only today. Keep them as a mouse extra, or drop them in favour of the launcher? |
| Side or top bar switch (B2) | Do you still switch, or settle on one? |
| Stats and machine facts (P2 to P4) | Worth having on a key, or is `btop` enough? |
| Calendar (P14) | Do you use it? |
| Bar items dropping in at start (B4) | Keep? |
| Slanted wallpaper strips (W1) | Keep the look, or a simpler grid? |

### Problems worth not carrying over

- Power actions run at once with no confirmation (P26, L25).
- The lock screen shows each typed character in plain text for 120 ms (K5).
- Notifications that ask to stay still vanish after 5 s (U4).
- Notification action buttons and the screenshot Open button are mouse-only (N6, S2).
- The keybinds list is a hand-kept copy that drifts from the real binds (U6).
- GPU usage may read 100% on the `xe` driver (U5, not confirmed).
- The launcher and cards may hide under fullscreen windows (C2, not confirmed).

## 2. What Strand adds

### Functions you don't have today

| Feature | What it gives you |
| --- | --- |
| Window switcher with live thumbnails | `thumbnail w` plus `windows`; an Alt+Tab that commits on release through `keyboard.alt` |
| Per-app volume | `audio.streams`, plus microphone device switching and mute. In the launcher since 2026-11-04: programs playing and recording moved between devices, the microphone's device, mute and level, and a live wave of each (`spectrum`); per-program volume itself not yet |
| Wi-Fi inside the shell | Radio on or off, joining with a password, forgetting a saved network and joining a hidden one, on iwd too (Strand `a968880f`), where `impala` is needed today. In the launcher since 2026-11-04 |
| Bluetooth inside the shell | Pair, forget and device battery, and Strand as the pairing agent for PIN, passkey and confirm prompts (Strand `d6623f12`), where `bluetui` is needed today. The prompts are in the launcher since 2026-11-04 |
| Clipboard history without `cliphist` | Text and images, 100 entries, kept across restarts; remove an entry; secrets never read |
| Richer notifications | Inline reply, progress bars, invoking actions from a key, 1,000 kept across restarts |
| Camera and screencast indicator | `video.streams` |
| Battery detail | Time left, charge history as a graph, peripheral batteries |
| Graphs that have history when opened | `cpu`, `memory`, network and battery |
| Your own polkit dialog | `polkit`, in place of `phylax`: the island grows into the admin password prompt, takes the keyboard and stays until answered or cancelled. In the shell since 2026-11-05, and the only polkit agent since phylax stopped starting the same day; phylax's config left the repo on 2026-11-07 |
| Your own login screen | `greetd`, in place of `tuigreet` |
| Display settings | `outputs`, though `hyprpier` owns this today, so it may not belong here |
| Command line control | `strand toggle`, `set`, `get`, `call`. Quickshell has no IPC today |
| Your own D-Bus services, files and command output as typed data | Anything with no built-in service (power profiles are built in since Strand `d6623f12`) |
| Power profiles, drives and the keyboard's light | `power`, `drives` (mount, unmount, eject) and `brightness.keyboard` (Strand `d6623f12`): in the launcher's Power and Drives pages and the island since 2026-11-04 |

### Motion and look

- Every visual prop springs by default, and interrupted motion keeps its velocity.
- Shared elements: `morph` makes one element grow into another, across surfaces on one output.
- A panel grows from its anchored edge and never makes the compositor animate a resize.
- Theme swaps spring through OKLab with nothing rebuilt: an open launcher keeps its query.
- A selection highlight can travel to the selected row on a spring (`id.box`).
- Wallpaper-derived palettes (`material(image:)`), plus Catppuccin and base16 imports.
- `transition: wipe | disc | dissolve | pixelate`, `stagger`, per-letter text, rolling digits, particles, your own shaders.
- Blur comes from the compositor, so it needs a layer rule for Strand's namespaces.

### Working on the shell itself

- A save patches the running shell without losing state. A broken save is held back and the last good version keeps running.
- `strand check` type-checks without running, and checks D-Bus services against the real object.
- Inspector: pick an element on screen and write a change back to the source file.
- `strand report` and `strand replay`: capture a glitch and replay it.
- An editor language server.

## 3. Keyboard gaps in Strand

All closed by Strand's `keyboard` work (`docs/decisions.md` there), except key routing on Hyprland (8), which
has been run by hand on nested Hyprland and has no automated test. Kept as the record of what was missing.

| # | Gap | What it blocks | Without a fix |
| --- | --- | --- | --- |
| 1 | A `list`'s selection can't be moved from code | Ctrl+N, Ctrl+P, j, k, wrap-around | Own cursor, losing scroll-into-view |
| 2 | Escape can't be intercepted on a two-way `open`; no way to suppress any default | Esc-goes-back in submenus; command modes | One-way `open`, then handling click-away and focus loss by hand |
| 3 | No arrow navigation in `grid` or a horizontal row | Wallpaper picker, workspace strip, tiles | Own cursor and row maths |
| 4 | Scrolling can't be driven from code | Long previews, Page keys outside a `list` | A clipped box with a spring |
| 5 | Buttons, tiles and sliders can't hold focus | Focus moving through a control panel | Treat rows as a `list` |
| 6 | Tab stops working if any `on key` surrounds the focused node | Combining global panel keys with Tab | Handle Tab by hand |
| 7 | Keys that arrive before a panel has focus: unmeasured | Typing straight after the launcher key | Measure first |
| 8 | Key routing is not tested on Hyprland | Confidence on your compositor | Your session is the test |

## 4. What a switch would touch

Done on 2026-11-04 (`21cc7a8`); the line numbers are from before it. Kept as the record.

- `hyprland.lua.tmpl:71`: start `strand` in place of `quickshell`.
- Eight `quickshell:` global shortcut binds in `hyprland.lua.tmpl`, and one in `hypridle.conf:9`.
- The blur layer rule at `hyprland.lua.tmpl:305`.

`theme-switch`, the palettes and the other apps' themes don't change. The `_quickshell` block in the
palettes can keep its name.

## 5. Running beside Quickshell

- **Notifications:** only one program can hold the name. Strand shows a notice saying who holds it, waits, and takes it the moment Quickshell exits. A config that doesn't read `notifications` never asks.
- **Tray:** no conflict; both can show it.
- **Lock:** whichever shell locks first holds it.
- **Bars:** they stack, so test the bar with Quickshell closed.

## 6. Suggested build order

1. Theme following `active.json`, since everything else then looks right.
2. Launcher on a temporary key, with apps, windows and actions.
3. Launcher submenus, with the gaps above fixed in Strand as they come up.
4. OSD.
5. Bar, with Quickshell closed.
6. Notifications and tray.
7. Wallpaper.
8. Lock screen, with a TTY route out ready.
