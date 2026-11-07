# Script Pipeline Review — Working Doc

Deep review of `~/.local/bin` scripts (2026-07-05), follow-up to the UX backlog.
Sources: two independent review agents + manual read, findings adversarially
re-verified before fixing. Live checks where possible.

## Fix list

### wallpaper-split
- [x] **SP-1: Registration reverted by `chezmoi apply`.** Sets are written only to
  the live `~/.config/wallpapers/wallpapers.json`, never the chezmoi source —
  breaks the repo's "write both copies" convention (`theme-switch`,
  `toggle-bar-mode`). A full `chezmoi apply` deletes registered sets, and the
  `[skip]` check (slice files exist) prevents re-registration without `-f`.
  Slice images also never land in the source dir, so new sets aren't tracked
  in the repo. *Fix: write slices + JSON to both live and source (resolve via
  `chezmoi source-path`).*
- [x] **SP-2: `-o` to a non-wallpaper dir registers broken sets.** Bare filenames
  are registered regardless of output dir, but Wallpaper.qml resolves images
  relative to `~/.config/wallpapers`. *Fix: skip registration + warn when
  output dir isn't the wallpaper dir.*
- [x] **SP-3: One slice failure aborts the whole batch.** Per-slice `magick`
  calls are bare under `set -e` (unlike identify/crop which skip-and-continue);
  partial slices stay on disk, no set registered, and the `[skip]` check hides
  the half-split image from re-runs. *Fix: skip-and-continue + clean partial
  slices for that image.*

### wallpaper-upscale
- [x] **UP-1: Tile overlap pasted, not trimmed.** Each upscaled tile is pasted
  full-size, so a later tile's border (the EDSR edge-artifact region the 32px
  overlap exists to discard) overwrites the previous tile's good interior.
  Seams possible at every boundary. *Fix: trim `OVERLAP/2 × SCALE` margins on
  non-edge sides before pasting.*

### toggle-bar-mode
- [x] **TB-1: Non-atomic write to the Quickshell-watched `active.json`.**
  Truncate-then-write; FileView can observe partial JSON, and an interrupted
  write corrupts the file (theme-switch then silently drops barMode via its
  JSONDecodeError fallback). *Fix: temp + rename, like `write_json_atomic`.*
- [x] **TB-2: Coherence + robustness.** Hardcodes the chezmoi source path
  (theme-switch asks `chezmoi source-path`); raw traceback on missing/corrupt
  active.json — invisible from the Super+Shift+T keybind. *Fix: resolve source
  path properly; notify-send on failure.*

### theme-switch
- [x] **TS-1: btop exit-save race not actually closed.** `pkill -x btop` awaits
  pkill, not btop; btop writes `btop.conf` on SIGTERM shutdown, which can land
  after `chezmoi apply` — verification downgraded the consequence: the theme
  file itself is safe (btop never writes it), only btop.conf's incidental
  settings can drift from source. *Fix: wait-until-gone loop (pgrep poll,
  short timeout) after the kill.*
- [x] **TS-2: `_quickshell.accent` unvalidated.** Malformed accent hex crashes
  `hex_to_hsl` with a raw ValueError instead of the notify+exit path every
  other bad input gets. *Fix: validate accent in `validate_palette`.*

### win-vm
- [x] **WV-1: Silent connect failures.** Readiness probe (`/dev/tcp/…:3389`)
  succeeds against docker-proxy before Windows RDP actually listens (worst on
  first boot), and backgrounded `sdl-freerdp3` is never checked — a failed
  connect shows "Connecting…" then nothing. *Fix: detect early freerdp death
  and notify with a hint; check the binary exists. Full verification needs a
  real VM boot → owner-verify.*
- [x] **WV-2 (follow-up): No visual feedback during boot, worst on first boot.**
  First boot = 20-45 min of ISO download + install with one failure
  notification then silence; warm boot waited on the fake TCP probe. *Fix:
  real readiness probe (`sdl-freerdp3 +auth-only` — authenticates against
  Windows' actual RDP stack, immune to docker-proxy); first-boot detection
  via `~/Windows/data.img` absence → opens dockurr's live noVNC console
  (http://localhost:8006, shows the real install screen), waits up to 60 min,
  auto-connects when done; warm boot waits up to 6 min on the real probe;
  `open` pre-checks readiness and says "still booting" instead of launching a
  doomed freerdp.* Gotcha found live: auth-only exit codes are useless —
  1 on auth SUCCESS (it cancels the connection by design), 134 on logon
  failure, 141 when nothing answers — so the probe matches the
  "Authentication only, exit status SUCCESS" log marker instead. Warm boot
  observed at 3-5 min after a container recreate, hence the 6 min timeout.

## Checked and cleared (no action)
- **screenshot `-A`/`--wait` hang** — refuted live: timed run returned in 5s
  (notification expiry releases the wait), zero orphaned processes on the
  system, and the DND path in `Notifications.qml` explicitly `expire()`s
  suppressed notifications to release blocking senders.
- **wallpaper-split bootstrap JSON lacking `defaults`** — Wallpaper.qml does
  `_config.defaults ?? {}`; shape is tolerated.
- slurp-cancel exit-status handling in `screenshot`; `rewrite_config_keys`
  prefix matching vs. current ghostty keys; barMode default agreement
  (`"side"` both sides); in-place writes to inode-watched targets (documented,
  unavoidable under the inode constraint).
- **Escape Velocity images orphaned in repo** — deliberate delist (`5eb4bcc`),
  same pattern as the 2026-07-05 sunset delist; not evidence of SP-1.

## Verification log
- Adversarial verify pass (independent agent, line-cited): SP-1/2/3, UP-1,
  TB-1/2, TS-2, WV-1 all CONFIRMED; TS-1 mechanism confirmed, consequence
  downgraded (btop.conf drift, not theme clobber).
- All fixes verified live (2026-07-05):
  - toggle-bar-mode: top→side→top round trip, live+source in lockstep, no
    .tmp leftovers, Quickshell followed both flips.
  - wallpaper-split: scratch batch registered in BOTH configs with slices
    mirrored to the source dir; [skip] on re-run; `-o` elsewhere printed the
    note and registered nothing. Test sets/slices fully cleaned up after
    (live == source == git HEAD).
  - theme-switch accent: palette with `"accent": "#zzz111"` → notify+exit(1)
    validation error before any writes, no traceback.
  - theme-switch btop wait: mock btop with a 1s SIGTERM exit-save —
    reload_btop blocked 1.17s until gone, save completed before return
    (old code returned in ~10ms).
  - wallpaper-upscale: 400x300 white image (2x2 tiles incl. clamped-overlap
    path) → 1600x1200 output, channel min 253 — no unwritten regions from
    the trim math.
  - win-vm: bash -n + `status` smoke test (docker down path). Connect-failure
    notification needs a real VM boot → owner-verify.
- screenshot: `timeout 30 screenshot full` → exit 0 in 5s; `pgrep -af screenshot` empty

## Owner-verify
- win-vm: real *first* boot (WV-2 path) — wipe/absent `~/Windows/data.img` →
  console auto-opens, install visible, auto-connect at the end. Warm boot was
  verified live 2026-07-05.
- wallpaper-upscale: visual seam check on a real upscale after UP-1.
