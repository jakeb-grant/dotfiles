# Design Review Backlog

**Date:** 2026-07-01 · **Scope:** whole repo (theme system, Quickshell, chezmoi structure, Hyprland, bin scripts) · **Method:** four parallel deep-review passes, findings verified against the live system where possible (`chezmoi diff`, `chezmoi status`, byte-diffs, schema diffs across all 11 palettes).

Severity: **P0** = broken/wrong today · **P1** = structural, high leverage · **P2** = worthwhile cleanup · **P3** = nits.
Effort: **S** < 1h · **M** ≈ half-day · **L** = multi-day.

---

## Session log

**Session 1 (2026-07-01) — Wave 1 complete.** Fixed: CHZ-2 (ignore gaps; HYPRLAND docs moved to `docs/`; stray `~/HYPRLAND_*.md`, `~/LICENSE`, `~/references/`, `~/.config/theme-templates/` deleted), CHZ-3 (phantom prompts removed; README graphics list synced), BIN-1 partial (compose ports → 127.0.0.1; "restart" message fixed), BIN-2 (toggle-bar-mode writes both copies), THM-7 partial (hyprlock bg → `path = screenshot` + palette color fallback; `_wallpaper` key deleted from all 11 palettes), QS-2 (IconCache singleton), CHZ-6 partial (fnm guard), THM-3 (deleted duplicate `hyprland.lua.theme`; CLAUDE.md/README updated), HYP-2 partial (hypridle doc sentence fixed; migration docs archived to `docs/`). Regenerated via `theme-switch catppuccin-mocha` + targeted `chezmoi apply`; two review agents on the diff → 1 real finding (stale README:164 reference, fixed), 1 false positive rejected (reviewer claimed ghostty chezmoi-diff was clean — re-verified: **THM-1 still reproduces**, apply would delete Ghostty's theme lines). Icon-cache startup-window race accepted as-is (self-heals per open; optional `rev` hardening declined).

---

## 0. TL;DR — the five findings that matter most

1. **`chezmoi apply` un-themes the system.** Direct-write apps (ghostty/btop/pane-fm) are mutated in the *live* config while the chezmoi *source* holds stale content. Verified: `chezmoi diff` today would **delete** Ghostty's `theme =` and `background-opacity =` lines. → [THM-1](#thm-1)
2. **The Jinja stage is largely vestigial.** Most generated `.tmpl` files contain zero Go template syntax; `hyprland.lua.theme` → `.tmpl` is a byte-identical copy. Chezmoi-native templates reading `active.json` via `fromJson` would eliminate the second template language, the committed-generated-file class, and the "edit the wrong file" trap. → [THM-2](#thm-2)
3. **The repo is 630 MB** — 558 MB of upscaled wallpaper PNGs in the working tree plus a deleted prior generation still in pack history. → [CHZ-1](#chz-1)
4. **Repo docs are deployed into `$HOME`.** `.chezmoiignore` gaps mean `~/HYPRLAND_0.55_*.md`, `~/LICENSE`, `~/references/`, and inert `~/.config/theme-templates/` exist right now. → [CHZ-2](#chz-2)
5. **Quickshell popouts have no shared component library.** ~600–800 lines of copy-paste across 8 popouts (sliders, list rows, pill buttons, headers) that DEVGUIDE documents as prose templates instead of components. → [QS-1](#qs-1)

Plus one security item: **win-vm exposes RDP + web UI on 0.0.0.0 with default creds** ([BIN-1](#bin-1)).

---

## 1. Theme system

### THM-1 · P0 · M — Direct-write apps break under plain `chezmoi apply` <a name="thm-1"></a>

- [ ] `executable_theme-switch:237-342` writes `theme =` / `color_theme =` / `light_icons =` into the **live** `~/.config/{ghostty/config, btop/btop.conf, pane-fm/config.toml}`, while the chezmoi sources hold different content (`dot_config/ghostty/config` has only a "managed by theme-switch" comment; `dot_config/btop/btop.conf:4` and `dot_config/pane-fm/config.toml:8-9` hardcode mocha).
- **Verified live:** `chezmoi status` shows `MM` for ghostty/zed/obsidian; `chezmoi diff` would delete Ghostty's theme + opacity lines. btop/pane-fm only match because the active theme happens to be mocha — switch themes and they're permanently dirty, reverted by any external `chezmoi apply`.
- **Fix:** point the line-rewrite machinery at `CHEZMOI_SOURCE_DIR` instead of `Path.home()` (the pattern `palette.lua` generation at `:201-233` already uses), add these files to `themed_targets` (`:513`), and let `chezmoi apply` propagate. Also fixes [BIN-2](#bin-2)'s sibling problem.

### THM-2 · P1 · L — Replace the Jinja stage with chezmoi-native templates <a name="thm-2"></a>

- [ ] `grep '{{'` across all generated `.tmpl`s matches only `hyprland.lua.tmpl` (machine `graphics` conditionals). `zed/settings.json.tmpl`, `gtk-3.0/gtk.css.tmpl`, `gtk-4.0`, `yazi/theme.toml.tmpl`, `phylax/style.css.tmpl`, `hyprlock.conf.tmpl` are fully-rendered files wearing a `.tmpl` extension — and chezmoi still Go-templates them, so any future literal `{{` breaks apply.
- **Alternative:** `{{ $p := include "dot_config/palette/active.json" | fromJson }}` in each template, with the 8 custom Jinja filters (`executable_theme-switch:74-110` — `rgba`, `hypr_rgba`, etc.) as small `.chezmoitemplates` helpers. Then only `active.json` needs committing; `theme-switch` shrinks to *copy palette → chezmoi apply → source-writes → reloads*; theme switches stop producing multi-file generated-color diffs in history (cf. 889ffaa, 6673e69); the fresh-clone story is preserved.
- **Cost:** Go's clumsier filter syntax. Latency unchanged — theme-switch already runs `chezmoi apply`.
- Also collapses the current **five output modalities** (Jinja→`.tmpl`→Go · Jinja→final-in-source for Obsidian via `TEMPLATE_OUTPUT_OVERRIDES` `:45-47` · direct-write-to-live · generated `palette.lua` · `/etc` Chromium policy) down to two.

### THM-3 · P0 · S — `hyprland.lua.theme` ↔ `.tmpl` are byte-identical; delete the `.theme` ✅ session 1

- [x] Verified: `dot_config/theme-templates/hypr/hyprland.lua.theme` and `dot_config/hypr/hyprland.lua.tmpl` are identical (13,037 bytes, 298 lines). Since ec0a596 the file has zero `{< >}` tokens (colors come via `require("palette")`), so the Jinja render is an identity copy — double diffs on every edit, and editing the `.tmpl` directly gets silently clobbered. The "Generated from theme template" header (`.theme:3`) is false in the source itself.
- **Fix:** delete the `.theme`, make `dot_config/hypr/hyprland.lua.tmpl` the single edited source, skip it in `process_templates` (`executable_theme-switch:176-194`). Update CLAUDE.md. (Subsumed by THM-2 if that lands first.)

### THM-4 · P1 · S — No validation anywhere; Jinja renders missing keys as empty strings

- [ ] No schema check, no existence check for referenced per-app theme files, and `create_jinja_env` (`executable_theme-switch:139-160`) uses default `Undefined` — a typo'd role silently renders as `""` into live configs.
- **Fix:** `StrictUndefined` + a ~30-line validate step in theme-switch: required keys present, hex format, `_btop_theme`/`_zed_theme_*`/pane-fm CSS files exist, `_ghostty_theme` sanity.

### THM-5 · P1 · M — Adding a palette = 5 artifacts, 4 naming conventions; generate the generatable ones

- [ ] Current cost of a new palette "foo": palette JSON (12 meta + 26 roles + `_quickshell` block) · btop `.theme` (~2.3 KB) · pane-fm `.css` (15 lines) · Zed theme JSON (~14 KB — has its own 19.6 KB `THEME_GUIDE.md`) · verify `_ghostty_theme` names a Ghostty built-in. Naming must stay in sync across `catppuccin-mocha` / `catppuccin_mocha` / `"Catppuccin Mocha"` (in three places).
- Coverage today is 10/10/10/10 — discipline has held, but nothing enforces it.
- **Fix:** btop and pane-fm formats are flat `key = "#hex"` lists — generate them from the palette (template or generate-all-N) and delete 20 hand-maintained files. Zed genuinely earns hand-maintenance (per-role alpha nuance); keep it, but validate its existence (THM-4).

### THM-6 · P1 · S — theme-switch has no failure handling

- [ ] `active.json` is written (both copies, `:485-487`) **before** templates render or chezmoi applies — a mid-run death leaves Quickshell live-switched while everything else is stale.
- [ ] The `chezmoi apply` exit code is discarded (`:516-519`) and the "Switched to X" notification (`:531`) fires unconditionally — a failed apply looks like success.
- [ ] Writes are non-atomic; Quickshell's watcher can observe a partially-written `active.json`.
- **Fix:** temp-file + `os.replace` for active.json; check the chezmoi exit code and notify-critical + exit non-zero on failure. (Re-running is fully idempotent — good — but the success toast hides when a re-run is needed.)

### THM-7 · P2 · S — Palette schema drift + dead keys

- [ ] `catppuccin-mocha`, `-frappe`, `-macchiato` (and `active.json`) lack `_quickshell.accent`; the other 7 define it. Fallback to `blue` works (`Theme.qml:92`, `theme-switch:490`) but the inconsistency is accidental. Decide policy and normalize.
- [ ] `islandShadowColor` exists only in the 3 light palettes — if intentional, document; if not, normalize.
- [x] ✅ session 1 — `_wallpaper` key deleted from all 11 palettes; hyprlock background now `path = screenshot` (blurred desktop) with `color = {< base | hypr_rgb >}` fallback.
- [ ] `rose-pine.json`: `surface0 #21202e` is **darker than** `base #26233a`, inverting the elevation ordering every other palette follows — likely a mapping slip; check surface0-on-base contrast visually.
- [ ] Light palettes set `_zed_theme_dark: ""` → `"dark": ""` in generated settings.json. Harmless (mode is forced) but worth a real value.

### THM-8 · P2 · S — theme-switch code cleanup

- [ ] `update_ghostty` (`:240-272`) / `update_btop` (`:278-302`) / `update_pane_fm` (`:308-342`) are the same rewrite-keys loop ×3 → one `rewrite_config_keys(path, {key: value}, uncomment=False)` helper; makes THM-1 a one-liner per app.
- [ ] Palette loaded twice (`:464` and `:479-481`); only the second gets the `barMode` merge — currently harmless, latent trap.
- [ ] `update_chromium` (`:351-379`): after `PermissionError` it prints the per-dir warning *and then* "No Chromium/Chrome policy dirs found" (because `wrote` stays False) — misleading.
- [ ] `CHEZMOI_ROOT` hardcodes `~/.local/share/chezmoi` (`:39`); prefer `chezmoi source-path`.

---

## 2. Quickshell shell

### What's good — preserve

- `services/Popout.qml` single-owner popout state machine (currentName/hasCurrent/hover flags + debounced close) — coherent, documented, survives content through retraction.
- One `PanelWindow` per screen with a computed input `mask: Region` (`Drawers.qml:47-88`); popouts as lazy Loaders.
- PopoutWrapper's hard problems (binding-loop-free size propagation, switch-settle gate, last-known-size during close, bloom origin, hover bridge) are solved *and* commented.
- Native Quickshell APIs used everywhere they exist (Pipewire, UPower, Bluetooth, Mpris, Pam, NotificationServer, SystemTray, DesktopEntries); text parsing confined to genuinely module-less tools (iwd, brightnessctl, powerprofilesctl, sysfs).
- Theme live-reload (`FileView watchChanges` + `_rev` reparse + mocha fallbacks + 400ms color Behaviors) is robust against partial/malformed writes; `Wallpaper.qml` reuses the same idiom.
- `Notifications.qml` lifecycle handling and `SystemStats.qml` gating polling on popout visibility.
- Comment quality and DEVGUIDE.md generally.

### QS-1 · P1 · L — Popout component library <a name="qs-1"></a>

- [ ] Zero shared *content* components exist; DEVGUIDE's "Popout Patterns" (lines 172-272) documents code to copy-paste. Census of duplication:
  - Width-spacer `Item` ×8 (all popouts)
  - Separator `Rectangle` ×~14
  - Pill footer button ×3 (~55 lines each: `BluetoothPopout:359-415`, `WifiPopout:313-369`, `TrayMenuPopout:371-426`)
  - Hover list-row delegate ×5 (40–90 lines: WifiPopout, BluetoothPopout, VolumePopout, PowerPopout, TrayMenuPopout)
  - Header crossfade (connected ↔ disconnected + link_off button) ×2 near-identical ~100 lines (`WifiPopout:25-127` ≡ `BluetoothPopout:24-123`)
  - Section header + spinning refresh ×2 (~45 lines)
  - Flowing-gradient slider ×2 full + 1 seekbar variant (~140 lines: `VolumePopout:61-210`, `BrightnessPopout:61-184`, `VolumePopout:291-393`)
  - `_flowOffset` + infinite NumberAnimation ×4 · hover icon-button ×~12 · empty-state text ×2
- [ ] Within PopoutWrapper itself, the tray Repeater Loader duplicates the inline `component Popout`'s states/transitions verbatim (`PopoutWrapper.qml:290-318` vs `:349-382`).
- **Fix:** `modules/bar/popouts/components/` with `PopoutColumn`, `Separator`, `SectionHeader{refreshable,spinning}`, `PillButton`, `ListRow`, `FlowSlider`, `IconButton`. Est. 600–800 lines removed; VolumePopout 592→~250, Wifi/Bluetooth converge to ~150 each. Convert DEVGUIDE's prose templates into "import these" docs.

### QS-2 · P0 · S — TrayMenuPopout walks `/usr/share/icons` on every open ✅ session 1

- [x] Done: `services/IconCache.qml` singleton populated once at startup; TrayMenuPopout reads `Services.IconCache.icons`. Known accepted edge: a tray menu opened in the first ~1s after shell start may miss icons for that open only (delegates recreate per open, so it self-heals).

### QS-3 · P1 · M — BarContent duplicates every bar item ×2 layouts

- [ ] `BarContent.qml` (361 lines): `sideLayout` and `topLayout` each list every item, and the per-item entrance boilerplate (`_shift` + 2 Behaviors + opacity + transform) repeats ×12. Workspaces/StatusIcons/TrayOverflow already use the single-GridLayout-with-flow-switch pattern (`Workspaces.qml:153-188`, `StatusIcons.qml:27-35`) — BarContent is the one sibling not using its own codebase's solution.
- **Fix:** `BarItem { step }` component + one flow-switched layout. Roughly halves the file.

### QS-4 · P2 · M — Launcher.qml (582) mixes five concerns

- [ ] Five near-identical scoring loops `_filterApps/_filterWindows/_filterKeybinds/_filterActions/_filterClipboard` (`Launcher.qml:319-504`) differing only in field names/weights → one generic `_score(terms, fields, weights)` (~40 lines).
- [ ] Static provider data (70-line keybinds table `:29-65`, actions, mainItems) → extract to a `LauncherProviders` sibling; keep the state machine + dispatch as the service.
- [ ] `_scanThemes` shells to inline python3 (`:161-174`) just to parse palette JSONs — drop the python dependency (FileView per file, or a tiny helper script).
- Note: `_evalCalc`'s `eval()` (`:512`) is regex-sanitized first — acceptable, documented here for the record.

### QS-5 · P2 · S — Icon ladders duplicated between bar and popouts

- [ ] Battery centralizes `icon`/`iconColor` in the service (`Battery.qml:23-49`) — the right pattern. But: volume ladder duplicated (`StatusIcons.qml:48-54` ≡ `VolumePopout.qml:26-32`), brightness ladder duplicated (`StatusIcons.qml:89-98` ≡ `BrightnessPopout.qml:25-34`), and the Nerd-Font wifi glyph array `["󰤯","󰤟","󰤢","󰤥","󰤨"]` appears ×3 (`StatusIcons.qml:132-136`, `WifiPopout.qml:33-37`, `:240-243`).
- **Fix:** `Services.Audio.icon`, `Services.Brightness.icon`, `Services.Network.signalIcon`, following Battery.

### QS-6 · P2 · S — Bar-item exit protocol duplicated at ~12 call sites

- [ ] `Services.Popout.barItemHovered = false; Services.Popout.requestClose();` verbatim in `BarContent.qml:70,155,197,236,313,355`, `StatusIcons.qml` ×5, `TrayOverflow.qml:84-87`. And `show()` sets `barItemHovered = true` internally while callers clear it — asymmetric API.
- [ ] `_showPopout()` helper duplicated (`BarContent.qml:28-36` ≡ `StatusIcons.qml:17-25`).
- **Fix:** add `Popout.barItemExited()`; single shared `_showPopout`.

### QS-7 · P2 · S — Network.qml hardening

- [ ] `wlan0` hardcoded in 5 commands (`Network.qml:45,116,159,239,279`) → detect the station name once via `iwctl device list` into a property.
- [ ] Column-split on `/\s{2,}/` + SSID reconstruction via `join("  ")` (`:141,188,200`) is lossy for SSIDs with runs of spaces → treat last-two-columns as authoritative (rsplit-style). (Text parsing itself is forced — no Quickshell iwd module, iwctl has no JSON output.)
- [ ] `onStateChanged` auto-`scan()` (`:88-94`) re-runs three processes per 3s poll cycle under connection flapping — debounce or gate on state transitions.

### QS-8 · P2 · S — API hygiene

- [ ] Private members used cross-module: `Services.Bluetooth._syncDevices()` (from `BluetoothPopout.qml:15`), `Services.Launcher._submenu` read by Drawers/LauncherPanel/WallpaperPicker incl. an `on_SubmenuChanged` handler → rename `refresh()` / `submenu`.
- [ ] Screen identity typed inconsistently: `Popout.activeScreen` is a `ShellScreen` object; `Launcher.activeScreen` is a monitor-name string — pick one convention.
- [ ] `VolumePopout.qml:196` writes `Services.Audio.sink.audio.volume` directly; add `Audio.setVolume()` beside `toggleMute`/`setSink`.

### QS-9 · P2 · S — Data acquisition in view code

- [ ] `SystemPopout.qml` embeds 6 one-shot Processes (kernel/uptime/hostname/shell/pacman×2, `:45-188`), re-running all six per open; kernel/hostname/shell are static per boot → `SystemInfo` service with cached statics.
- [ ] PowerPopout creates a `Process` per Repeater delegate (`:116-118`); Wifi/Bluetooth embed `impalaProc`/`bluetuiProc` → use `Quickshell.execDetached` (the convention `Launcher.qml:310` already establishes).
- [ ] `Battery.qml:62` reads the power profile once at startup — external changes (keybind, TLP) never reflected → watch `/sys/firmware/acpi/platform_profile` or re-poll on popout open.

### QS-10 · P2 · S — Dead code

- [ ] `LockSurface.syncPassModel()` (`LockSurface.qml:128-138`) — never called; `onTextChanged` (`:375-399`) reimplements it inline.
- [ ] Two `Connections` blocks both handling `onClearInput` (`LockSurface.qml:142-155` and `:479-490`) — already drifted from each other (only the second resets `hiddenInput.oldText`). Merge.
- [ ] `PersistentProperties { property bool bar: true }` (`Drawers.qml:187-190`) referenced nowhere.

### QS-11 · P2 · S — DEVGUIDE drift

- [ ] Token `popoutWidthNarrow: 180` (DEVGUIDE:109,183) doesn't exist in Theme.qml.
- [ ] DEVGUIDE:39 says use `blue` for active/connected; code uniformly uses the `accent` role, which the roles list omits.
- [ ] DEVGUIDE:303 prefers `layer.enabled: visible`; `PopoutWrapper.qml:223` and `Drawers.qml:137` use `layer.enabled: true` — align code or guidance.
- [ ] "Never hardcode sizes" is heavily violated outside popouts (LockSurface wall-to-wall magic numbers `:214-217,256,314`; LauncherPanel durations; BarContent literals; Workspaces slot math) — either tokenize the recurring values or scope the rule to bar/popout surfaces in DEVGUIDE.
- [ ] Wifi's Nerd-Font-glyph exception to MaterialIcon is deliberate but undocumented.

### QS-12 · P3 · S — Minor

- [ ] `Theme.qml`: `_tt: 400` duplicates `animDuration: 400` (`:35,230`) — merge tokens.
- [ ] LockSurface natural split: `LockBackground.qml` (blobs/rings/vignette `:32-122`) + `PasswordPill.qml`.
- [ ] Empty-state null-guard style differs between Wifi/Bluetooth popouts.

---

## 3. Chezmoi structure & bootstrap

### CHZ-1 · P1 · M — Repo is 630 MB of mostly regenerable wallpaper PNGs <a name="chz-1"></a>

- [ ] `dot_config/wallpapers/` is 558 MB in the working tree (27 PNGs; `mars-race3.png` 25 MB); `git count-objects` size-pack is **630.71 MiB** — history also contains a deleted earlier generation of per-palette wallpaper trees. These are upscaled (`wallpaper-upscale` EDSR 4×) artifacts, i.e., regenerable.
- **Fix:** move wallpapers out of git — `.chezmoiexternal.toml` pointing at a release archive/separate repo, or git-lfs; `git filter-repo` to purge history; store pre-upscale JPG sources, keep `wallpapers.json` in-repo. (History rewrite — coordinate with any other clones.)

### CHZ-2 · P0 · S — `.chezmoiignore` gaps: repo docs deployed into `$HOME` <a name="chz-2"></a> ✅ session 1

- [x] Verified deployed with chezmoi-managed timestamps: `~/HYPRLAND_0.55_LUA_REFERENCE.md`, `~/HYPRLAND_0.55_MIGRATION.md`, `~/LICENSE`, `~/references/` (AGENTS.md, fastapi-structure-guide.md, dell-xps16-audio-issue.md, fix-sdca-modules.sh), and inert `~/.config/theme-templates/**` (templates are only ever read from the chezmoi source).
- `knowledge/` is **not** a gap — intentional Obsidian-vault deploy (README.md:93-96).
- **Fix:** add `HYPRLAND_0.55_*.md`, `LICENSE`, `references/`, `.config/theme-templates/` to `.chezmoiignore`; `chezmoi apply` removes the strays. Better: move the two 29 KB Hyprland notes into `docs/` (already ignored) and relocate the non-dotfiles content of `references/` (fastapi guide, AGENTS.md) to the knowledge vault.

### CHZ-3 · P0 · S — Commented-out prompts in `.chezmoi.toml.tmpl` still execute ✅ session 1

- [x] `.chezmoi.toml.tmpl:9-10`: `#`-commented `promptStringOnce` lines for email/name still run as template actions — fresh `chezmoi init` prompts for both, discards the answers into comments, and re-prompts on every future init (values never land in `[data]`). Delete or uncomment.
- README.md:239 lists graphics options `amd, prime, nvidia` but the template offers `amd, intel, prime, nvidia` — sync.
- (The rest of the file is good: `promptChoiceOnce`, lspci-autodetected PCI defaults.)

### CHZ-4 · P2 · S — run-script hygiene

- [ ] `run_once_setup-greetd.sh.tmpl` has **zero** template directives — the `.tmpl` suffix is a latent trap (any future `{{` in the heredoc'd PAM/greetd config would be parsed as a template action). Rename to drop `.tmpl`. Document the `start-hyprland` system-binary dependency (from arch-quickstart). Heredoc'd `/etc` config means out-of-band drift is invisible to `chezmoi diff` — accept + document, or manage via a diffable mechanism.
- [ ] `run_once_setup-chromium-policies.sh`: clean, but `run_once` never re-fixes lost ACLs (package reinstall, later Chrome install); theme-switch degrades to a warning. Consider a check-and-fix inside theme-switch instead.
- [ ] `run_onchange_setup-gpu-symlinks.sh.tmpl` and `run_once_before_create-default-monitors-lua.sh`: correct lifecycles, idempotent — no action.
- [ ] Three scripts need interactive sudo → unattended `chezmoi init --apply` blocks/fails. Fine for a personal repo; add a README note.

### CHZ-5 · P2 · S — Vestigial and legacy pieces

- [ ] `dot_config/age/recipients` (public key) has zero consumers — no `encrypted_` files, no `[age]` stanza, no script references. Wire it up or delete it so it stops implying encryption exists.
- [ ] `dot_config/sddm-theme/` is labeled "legacy, replaced by greetd" (README.md:88) yet still deploys to `~/.config/sddm-theme`. Remove or ignore.
- [ ] `.gitignore:26` `.chezmoi.toml` is a dead entry (rendered config lives in `~/.config/chezmoi/`). Harmless; delete.

### CHZ-6 · P2 · S — Bootstrap gaps (fresh-machine story)

- [x] ✅ session 1 — `dot_bashrc:22` `eval "$(fnm env)"` is unguarded — every interactive shell errors on a machine without fnm. Guard: `command -v fnm >/dev/null && eval "$(fnm env)"`.
- [ ] Implicit runtime deps assumed from arch-quickstart with no listing or checks: `uv` (theme-switch shebang), `setfacl`, `tuigreet` + `greeter` user, `start-hyprland`, `fnm`, jq (wallpaper-split). Add a deps section to README (or a doctor script).
- [ ] `~/knowledge` vault must be cloned separately or chezmoi creates a bare `.obsidian` skeleton in an empty dir — document ordering.
- [ ] Nothing enforces `.theme` ↔ `.tmpl` sync — a `.theme` edit without running `theme-switch` ships a stale `.tmpl` silently. `theme-switch --check` or a pre-commit hook. (Moot if THM-2 lands.)

---

## 4. Hyprland

### HYP-1 · P2 · S — `pcall(require, "monitors")` swallows errors silently

- [ ] `hyprland.lua.theme:51` (and the `.tmpl` copy): a syntax error in hand-edited `~/.config/hypr/monitors.lua` → no monitor config, no diagnostic. Capture the pcall result and surface it (`notify-send` via `hl.exec_cmd`, or print).

### HYP-2 · P3 · S — Doc drift

- [x] ✅ session 1 — both `HYPRLAND_0.55_*.md` files archived into `docs/`.
- [x] ✅ session 1 — CLAUDE.md hypridle sentence fixed.
- [ ] Trivial: screenshot `sh -c` one-liner duplicated (`hyprland.lua.theme:136-137`).

*(Positive: the dropped-auto-suspend cleanup is exemplary — `hypridle.conf` comments point to `dot_config/hypr/README.md`, which documents the xe crash, the removed listener verbatim, and a re-test procedure. Keybind organization, table-driven animations, and in-place quirk comments are all clean.)*

---

## 5. Bin scripts

### BIN-1 · P0 · S — win-vm exposes RDP/web UI on all interfaces with default creds <a name="bin-1"></a>

- [x] ✅ session 1 — compose ports now bound to `127.0.0.1` (takes effect on next `docker compose up`, i.e. container recreate).
- [ ] No `set -euo pipefail` — e.g. a failed `docker compose up -d` in `start-and-open` (`:105`) still toasts "Starting VM…" and spins the 60-iteration wait loop.
- [ ] `sdl-freerdp3` invocation duplicated ×3 (`:97,103,111`) → `connect()` function.
- [x] ✅ session 1 — `:18` message now says "log out and back in".
- [ ] `open`/`restart` don't check whether docker/VM is running; `stop`/`status` do — align.

### BIN-2 · P0 · S — toggle-bar-mode causes chezmoi-source drift <a name="bin-2"></a> ✅ session 1

- [x] Done: writes both live and chezmoi-source `active.json`, matching theme-switch's format exactly (`indent=2`, no trailing newline — intentional, to avoid diff churn against theme-switch's writes).

### BIN-3 · P2 · S — wallpaper-split robustness

- [ ] `:96-98` — under `set -e`, an unreadable image aborts the whole batch with stderr discarded → guard with `|| { echo "[error] …" >&2; continue; }`.
- [ ] Fixed temp path `/tmp/_wpp_cropped.${FORMAT}` (`:118,127,131,140`) — concurrent runs clobber; use `mktemp`.
- [ ] jq is a soft dependency but registering sets in `wallpapers.json` is half the script's purpose — require it up front.
- (Otherwise the best-hygiene script of the set.)

### BIN-4 · P3 · S — wallpaper-upscale nits

- [ ] `--skip-existing` (`:71-72`) is `store_true` with `default=True` — always-on no-op flag; remove it (behavior is already default), keep `--force`.
- [ ] `:81` f-string has no placeholders.

*(The two wallpaper scripts are sequential pipeline stages in different domains — don't merge them.)*

---

## 6. Docs & meta

- [ ] **DOC-1 · P3** — `dot_config/quickshell/FLOATING_ISLAND_PLAN.md`: all six phases ✅, line references target pre-redesign `main`, "Removed" section describes files that no longer exist; the durable design language already lives in DEVGUIDE. Delete once `floating-bar-popouts` merges (git history preserves it).
- [ ] **DOC-2 · P3** — Update CLAUDE.md/README as THM-1/2/3 and CHZ items land (the two-template-language explanation, the direct-write list, the graphics options list, the hypridle sentence).

---

## Suggested sequencing

**Wave 1 — quick wins, active bugs (all S):** ✅ done session 1.

**Wave 2 — theme-system integrity (S/M):**
THM-1 (direct-writes → source) with THM-8's `rewrite_config_keys` helper → THM-6 (failure handling) → THM-4 (validation + StrictUndefined) → THM-7 remainder (schema normalize, rose-pine check).

**Wave 3 — structural (M/L, independent tracks):**
- Track A: THM-2 (chezmoi-native templates) then THM-5 (generate btop/pane-fm) — decide THM-2 first since it changes where generation lives.
- Track B: QS-1 (popout components) → QS-3 (BarItem) → QS-5/QS-6 (ladders, exit protocol) → QS-4 (launcher scorer).
- Track C: CHZ-1 (wallpaper degit + history purge) — schedule deliberately; it's a history rewrite.

**Wave 4 — polish:** QS-7/8/9/10/11/12, HYP-1/2, BIN-3/4, CHZ-4/5, DOC-1/2.
