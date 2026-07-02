# Shell UX Backlog

**Date:** 2026-07-02 · **Scope:** Quickshell shell + Hyprland keybind feedback · **Method:** two parallel UX-focused exploration passes (component inventory + keybind→feedback map), gaps verified against the source (no OSD, no wheel handlers on bar, no mic tracking in Audio.qml, no battery notifications, no media-key binds).

Effort: **S** < 1h · **M** ≈ half-day · **L** = multi-day.
Working loop (same as the design review): implement chunk → verify live → ≤2 terse review agents → fix/reject findings → update this doc → commit.

---

## Session log

*(newest first)*

**Session 4 (2026-07-02) — Chunk 4 complete: UX-4a/b.** DND + history live on the Notifications service, both in a `PersistentProperties` block so they survive theme-switch live reloads. **Gotcha worth remembering: PersistentProperties can't carry JS arrays across reload engines** — a `property var` comes back `undefined` ("JSValue can't be reassigned to another engine"); history is stored as a JSON string with the parsed array as a derived binding (now a DEVGUIDE section). DND: non-critical notifications are `expire()`d immediately (releases `notify-send --wait/-A` senders — verified, exits fast under DND) and skip the popup path entirely; critical bypasses; accent `notifications_off` StatusIcons indicator while active (indicator-only — chosen state, not a hazard, so accent not red); toggle is a launcher action ("Do Not Disturb", live On subtitle) via a `_special: "dnd"` dispatch that calls the service instead of exec'ing a command. History: plain-data snapshots (app/summary/body/critical/time) captured at *arrival* — one code path covers dismiss/expire/cap-drop/DND-suppress — ring-buffered at 50; "Notifications" launcher submenu like clipboard, `!` icon for critical, `app · Nm ago` subtitles, Enter copies summary+body, placeholder row when empty. Verified live via a temporary IPC harness on the deployed Launcher.qml: suppression (popups 0, history +1), critical bypass card with red stripe during DND, indicator on/off screenshots, submenu screenshot, reload persistence of both, launcher-action toggle, copy-on-Enter. Review (1 agent): 3 real bugs fixed + re-verified — (1) notification text reached `wl-copy` as parseable argv: a summary of `-c` *cleared the clipboard*; now `wl-copy --` (same pre-existing bug fixed in the calc path — `=3-8` could never copy); (2) launcher row `Text` defaulted to AutoText, so tag-like summaries rendered as markup or vanished; name/subtitle now `Text.PlainText` (also hardens pre-existing clipboard rows), and the body markup-strip regex was dropped — it corrupted text like "5 < 10"; (3) unbounded summary/body made every later arrival re-stringify a multi-MB history and broke copy on argv limits; snapshot now caps fields at 4 KiB (verified with a 100 KB body). Accepted: full qs restarts clear DND+history; open launcher shows stale DND subtitle until reopened; history not in unified search (submenu-only — stale notification text scoring against apps is noise).

**Session 3 (2026-07-02) — Chunk 3 complete: UX-3a/b.** Battery warnings live in `Battery.qml`: notify-send (the shell is its own daemon) at 15% and critical at 5% while discharging, one per threshold per discharge cycle. Mic: `Audio.qml` tracks `Pipewire.defaultAudioSource` (`sourceMuted`/`micIcon`/`toggleSourceMute`); the existing `XF86AudioMicMute` wpctl bind already toggles the default source, so the OSD just watches state like volume — no keybind change. New "mic" OSD mode (icon + "Microphone muted/on", no fill bar) and a red `mic_off` StatusIcons indicator while muted (indicator-only; red because a muted mic mid-call is the "why can't they hear me" trap). Verified live: mic OSD both directions + bar indicator appear/vanish (screenshots); battery latch walked through an injected IPC harness on the deployed file — 20→15 warn, flaps at 14/13/12 silent, 5 critical, flap at 4 silent, recover-to-20 re-arms, re-drop re-warns. Review (1 agent): 3 real bugs fixed pre-commit — (1) device hotplug flips the derived `sourceMuted` (unplugging a muted headset flashed "Microphone on"); Osd now tracks source identity and only shows for same-source mute changes; (2) latch reset keyed off `charging` (includes PendingCharge) would re-fire on weak-charger flap; reset now keys off *recovery* above the threshold — a deliberate deviation from the "resets on AC" spec; (3) UPower properties bind async/unordered, so a missing `onIsLaptopChanged` re-check could defer the login-time warning. Note: critical cards still auto-expire (no urgency exemption in the daemon) — accepted, the pulsing red bar icon is the persistent signal. Owner-verify: real XF86AudioMicMute key; a real discharge past 15%.

**Session 2b (2026-07-02) — chunk 2 follow-ups: launcher menu path.** Owner report: menu-launched screenshots gave no notification and full captures included the fading launcher island. Two real causes: (1) the hand-maintained keybinds table in `LauncherProviders.qml` still carried the old inline `sh -c` one-liner — updated to call the script (drift hazard noted: the table duplicates `hyprland.lua.tmpl` bind commands by hand); (2) **`chezmoi apply` does not reliably trigger a quickshell live reload** — atomic-rename inode replacement can miss the watcher, and a stale trailing "Configuration Loaded" in `qs log` is indistinguishable from success, so the running instance kept executing the old in-memory table while the deployed file was correct. Protocol now: after any apply touching quickshell files, `touch shell.qml` and confirm a *fresh* reload pair. The launcher artifact: grim fired during the launcher's 300ms close animation — menu entry now runs `sleep 0.4; screenshot full` (keybind path stays instant).

**Session 2 (2026-07-02) — Chunk 2 complete: UX-2a/b.** The inline `sh -c` one-liner in `hyprland.lua.tmpl` became a proper script, `dot_local/bin/executable_screenshot` (`screenshot region|full`); the binds are now `exec_cmd("screenshot region/full")` (~/.local/bin is already on Hyprland's PATH). Success → notification with the capture as thumbnail (`image-path` hint — the card resolves absolute paths directly), filename in the body, and an **Open** action button (`notify-send -A` implies `--wait`; the pressed action id comes back on stdout → `xdg-open`). Failure → critical card: grim failure, wl-copy failure ("saved, clipboard copy failed"), mkdir failure, slurp exit ≠ 1. Slurp cancel (Escape, exit 1) stays silent — cancel is deliberate. Verified live: success card with desktop thumbnail + Open button (screenshot), critical failure card via a failing-grim PATH shim (screenshot), clipboard `image/png`, slurp cancel/error branches via exit-1/exit-127 shims. Review (1 agent): 1 minor bug fixed — the filename was stamped at launch, so a second invocation queued behind an open slurp selection reused the same second and overwrote; now stamped after selection settles. Also from review: mkdir failure surfaced, slurp cancel distinguished from slurp error by exit code, `# no -e` deviation from sibling scripts documented inline. Checked and cleared: `notify-send -A` doesn't accumulate blocked processes — the shell's notification service dismisses on expiry, which releases the wait (pgrep clean after multiple runs). Owner-verify: real Print / Shift+Print keypresses and the Open button.

**Session 1b (2026-07-02) — regression fix: OSD window map race.** Owner report: OSDs stopped showing after the review-pass changes. Debug instrumentation on the deployed files traced the full chain healthy (`show()` fired, `Osd.visible` true, overlay opacity 1) but caught the overlay window mapping at **0×0** — `visible: osd.visible` mapped the layer surface on demand, and the compositor's configure (which delivers the real 348px size) arrived only after map. When the configure loses the race it can miss the entire 1.4s display window, so the OSD showed for synthetic tests and not for real keypresses. Fix: the OSD window stays mapped permanently (transparent + click-through, idle cost ~nil); the overlay's opacity animation alone drives show/hide. Verified post-fix by live screenshot; instrumentation stripped via `chezmoi apply --force`.

**Session 1 (2026-07-02) — Chunk 1 complete: UX-1a/b/c.** New `services/Osd.qml` (decides *when*: watches `Audio.volumePercent`/`muted` and `Brightness.percent`, 1.4s auto-hide, suppressed while the matching popout is open, 2s startup grace so the async login value-sync doesn't flash it) + `modules/osd/OsdOverlay.qml` (renders *what*: bottom-center island — icon, fill bar, fixed-width % label so the bar doesn't wiggle, "Muted" state, track title/artist in media mode with a "Nothing playing" fallback). Media keys: `XF86AudioPlay/Pause/Next/Prev` → `quickshell:media-*` global shortcuts → the existing MPRIS `Players` service (no playerctl dep); play+pause both map to toggle (one keysym per press, so no double-fire; separate-key boards get toggle-on-either). Wheel handlers on the bar volume/brightness icons. All three OSD modes verified live by screenshot (+ owner eyes); shortcuts confirmed registered in `hyprctl globalshortcuts`; rendered lua luac-clean. Review (1 agent): 1 real bug fixed pre-commit — naive per-event wheel stepping would slam 5%/micro-event on touchpads and treat `angleDelta.y === 0` as scroll-down; now accumulates and steps per ±120. Convention nit fixed (`Osd.qml` qualifies siblings via `import qs.services as Services` per DEVGUIDE). Acted on the review's fullscreen observation: OSD moved out of the drawers window (WlrLayer.Top — fullscreen occludes it, which is the OSD's prime scenario) into its own per-screen `WlrLayer.Overlay` PanelWindow with an empty input mask (click-through) that maps only while showing. Rejected: swallow-first-change startup latch (eats the user's first real keypress whenever the value binds before the singleton instantiates — a rare cosmetic login flash is the better trade; rationale in Osd.qml). Accepted as feature: device switches (headphones plug, BT connect) flash the volume OSD. Known cosmetic: suppression is global while overlays are per-screen — popout on monitor A suppresses monitor B's OSD. DEVGUIDE: island enumeration + wheel-accumulation rule + OSD pattern section. Owner-verify: scroll-to-adjust on the bar icons (wheel events can't be synthesized headlessly).

---

## Guiding observations

The shell has two feedback channels today: the bar (icons + hover popouts) and notify-send toasts (theme-switch, win-vm). The gap is **moment-of-action feedback for keyboard-initiated state changes** — volume/brightness/mute keys only nudge a 36px peripheral icon; screenshots, mic mute, and media keys give nothing at all. The unifying fix is a transient OSD island reusing the existing island styling, plus toasts where the notification card is the natural surface (screenshots).

---

## Chunk 1 — System keys feel responsive (OSD core) · M · ✅ session 1

- [x] **UX-1a: Volume/brightness OSD.** ✅ session 1 — bottom-center overlay-layer island (survives fullscreen), 1.4s auto-hide, muted state, popout + startup suppression.
- [x] **UX-1b: Media key binds.** ✅ session 1 — `quickshell:media-*` globals → MPRIS `Players` service; OSD flashes track info.
- [x] **UX-1c: Scroll-to-adjust on bar icons.** ✅ session 1 — wheel handlers with ±120 accumulation (owner to confirm feel on real hardware).

## Chunk 2 — Screenshot feedback · S · ✅ session 2

- [x] **UX-2a: Capture confirmation.** ✅ session 2 — thumbnail card + Open action via `~/.local/bin/screenshot`; slurp cancel stays silent.
- [x] **UX-2b: Failure surfaced.** ✅ session 2 — grim/wl-copy/mkdir/slurp-error → critical notification.

## Chunk 3 — Safety nets · M · ✅ session 3

- [x] **UX-3a: Low-battery warnings.** ✅ session 3 — 15% card + 5% critical while discharging, latched per threshold; reset keys off recovery above the threshold (not raw AC state — charger flap immunity).
- [x] **UX-3b: Mic-mute feedback.** ✅ session 3 — `Audio.qml` default-source tracking, "mic" OSD mode (hotplug-guarded), red `mic_off` bar indicator while muted.

## Chunk 4 — Notification UX · M · ✅ session 4

- [x] **UX-4a: Do Not Disturb.** ✅ session 4 — launcher-action toggle, critical bypasses, suppressed notifs expired (releases `--wait` senders) but kept in history, accent bar indicator; survives live reloads via PersistentProperties.
- [x] **UX-4b: Notification history.** ✅ session 4 — last-50 ring buffer snapshotted at arrival, "Notifications" launcher submenu (Enter copies summary+body), persisted as JSON string across reloads.

## Chunk 5 — Lock screen + discoverability polish · S

- [ ] **UX-5a: Caps-lock indicator** on the lock screen password entry.
- [ ] **UX-5b: Clock→calendar affordance.** Hover state on the bar clock hinting it's clickable.

## Chunk 6 — Keyboard navigation (largest, last) · L

- [ ] **UX-6a: Popout list keyboard nav.** Arrow/Enter navigation for WiFi networks, Bluetooth devices, audio output devices.
- [ ] **UX-6b: Tray menu keyboard nav.**

## Rejected / not doing

- **Bar-mode-toggle toast** — the bar visibly relocating *is* the feedback.
- **Tooltips on bar icons** — hover already opens popouts; a tooltip would fight them.
