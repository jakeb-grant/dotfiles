# Shell UX Backlog

**Date:** 2026-07-02 · **Scope:** Quickshell shell + Hyprland keybind feedback · **Method:** two parallel UX-focused exploration passes (component inventory + keybind→feedback map), gaps verified against the source (no OSD, no wheel handlers on bar, no mic tracking in Audio.qml, no battery notifications, no media-key binds).

Effort: **S** < 1h · **M** ≈ half-day · **L** = multi-day.
Working loop (same as the design review): implement chunk → verify live → ≤2 terse review agents → fix/reject findings → update this doc → commit.

---

## Session log

*(newest first)*

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

## Chunk 3 — Safety nets · M

- [ ] **UX-3a: Low-battery warnings.** Notification at 15% (normal) and 5% (critical) while discharging; fires once per threshold per discharge cycle; resets on AC. Matters extra since hypridle auto-suspend was dropped (xe crash).
- [ ] **UX-3b: Mic-mute feedback.** `Audio.qml` gains default-source tracking; `XF86AudioMicMute` gets OSD feedback; persistent bar indicator while the mic is muted.

## Chunk 4 — Notification UX · M

- [ ] **UX-4a: Do Not Disturb.** Toggle (power popout or launcher action) that suppresses cards (critical still shown); bar indicator while active.
- [ ] **UX-4b: Notification history.** Dismissed/expired notifications land in a "last N" list browsable from the launcher (like clipboard).

## Chunk 5 — Lock screen + discoverability polish · S

- [ ] **UX-5a: Caps-lock indicator** on the lock screen password entry.
- [ ] **UX-5b: Clock→calendar affordance.** Hover state on the bar clock hinting it's clickable.

## Chunk 6 — Keyboard navigation (largest, last) · L

- [ ] **UX-6a: Popout list keyboard nav.** Arrow/Enter navigation for WiFi networks, Bluetooth devices, audio output devices.
- [ ] **UX-6b: Tray menu keyboard nav.**

## Rejected / not doing

- **Bar-mode-toggle toast** — the bar visibly relocating *is* the feedback.
- **Tooltips on bar icons** — hover already opens popouts; a tooltip would fight them.
