# Shell UX Backlog

**Date:** 2026-07-02 · **Scope:** Quickshell shell + Hyprland keybind feedback · **Method:** two parallel UX-focused exploration passes (component inventory + keybind→feedback map), gaps verified against the source (no OSD, no wheel handlers on bar, no mic tracking in Audio.qml, no battery notifications, no media-key binds).

Effort: **S** < 1h · **M** ≈ half-day · **L** = multi-day.
Working loop (same as the design review): implement chunk → verify live → ≤2 terse review agents → fix/reject findings → update this doc → commit.

---

## Session log

*(newest first)*

---

## Guiding observations

The shell has two feedback channels today: the bar (icons + hover popouts) and notify-send toasts (theme-switch, win-vm). The gap is **moment-of-action feedback for keyboard-initiated state changes** — volume/brightness/mute keys only nudge a 36px peripheral icon; screenshots, mic mute, and media keys give nothing at all. The unifying fix is a transient OSD island reusing the existing island styling, plus toasts where the notification card is the natural surface (screenshots).

---

## Chunk 1 — System keys feel responsive (OSD core) · M

- [ ] **UX-1a: Volume/brightness OSD.** Transient island (icon + fill bar + %) near the bar edge on volume/brightness change; ~1.2s auto-hide; distinct muted state (not just a number); suppressed while the corresponding popout is open and on shell-startup initial value sync. New `modules/osd/`, driven by the existing `Audio`/`Brightness` services.
- [ ] **UX-1b: Media key binds.** `XF86AudioPlay/Next/Prev` → Quickshell global shortcuts handled by the existing `Players` (MPRIS) service — no playerctl dependency. OSD flashes track title/artist on skip.
- [ ] **UX-1c: Scroll-to-adjust on bar icons.** Wheel handlers on the volume and brightness status icons (the popout hint already promises "scroll … to adjust"; make the bar icons honor it too).

## Chunk 2 — Screenshot feedback · S

- [ ] **UX-2a: Capture confirmation.** After Print/Shift+Print: notification with the screenshot thumbnail as its icon. Slurp cancel (region mode) stays silent — cancel is deliberate.
- [ ] **UX-2b: Failure surfaced.** grim/wl-copy failure → critical notification instead of today's total silence.

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
