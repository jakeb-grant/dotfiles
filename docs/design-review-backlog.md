# Design Review Backlog

**Date:** 2026-07-01 · **Scope:** whole repo (theme system, Quickshell, chezmoi structure, Hyprland, bin scripts) · **Method:** four parallel deep-review passes, findings verified against the live system where possible (`chezmoi diff`, `chezmoi status`, byte-diffs, schema diffs across all 11 palettes).

Severity: **P0** = broken/wrong today · **P1** = structural, high leverage · **P2** = worthwhile cleanup · **P3** = nits.
Effort: **S** < 1h · **M** ≈ half-day · **L** = multi-day.

---

## Session log

**Session 10 (2026-07-02) — final Wave 4 batch: HYP-1/2, BIN-1 leftovers, BIN-3/4, CHZ-4/5/6 leftovers, DOC-2. Backlog complete.** HYP-1: `pcall(require, "monitors")` now captures its result; failure prints to the Hyprland log and fires a critical notify-send via `hl.exec_cmd` (single-quote escaping of the Lua error verified against a real syntax-error message; success path silent; rendered config luac-clean; live `hyprctl reload` OK). HYP-2: screenshot `sh -c` one-liner deduped into `screenshot(grab)` (output asserted byte-identical to both old binds); stale "Generated from theme template" header fixed. BIN-3: wallpaper-split requires jq up front (smoke test surfaced that jq isn't even installed on this machine), `mktemp` + EXIT trap replaces the fixed /tmp path, `magick identify`/center-crop guarded with error+continue — corrupt image in a batch now reported and skipped, batch exit 0. BIN-4: no-op `--skip-existing` removed, f-string nit fixed. BIN-1 leftovers: win-vm gets `set -euo pipefail` (notify-send `|| true` so headless survives), `connect()` dedup ×3, and open/restart now check docker/VM state like stop/status (all subcommands smoke-tested with docker inactive). CHZ-4: greetd script renamed to drop `.tmpl` with contents byte-identical — chezmoi keys run_once state on content hash, so no re-run/sudo prompt (verified 100% rename similarity + `chezmoi status` clean); start-hyprland dep, /etc-heredoc drift, and interactive-sudo caveats documented in README; theme-switch's Chromium ACL warning made actionable (re-run the setup script) — moving check-and-fix into theme-switch rejected (needs root). CHZ-5: `dot_config/age/recipients` (zero consumers) and legacy `dot_config/sddm-theme/` deleted from source; dead `.chezmoi.toml` .gitignore entry dropped; deployed `~/.config/age` + `~/.config/sddm-theme` left on disk (unmanaged) for manual removal. CHZ-6 leftovers + DOC-2: README Dependencies section lists the arch-quickstart-implied runtime deps (uv, jq+magick, fnm, setfacl, tuigreet/greeter/start-hyprland) plus install notes (sudo prompts, /etc drift, `~/knowledge` vault ordering); sddm-theme dropped from the tree. Reviews (2 agents): correctness — 1 finding fixed (`is_running`'s `grep -q` could SIGPIPE docker compose under the new pipefail and misreport a running VM; grep now consumes all input), everything else verified clean incl. gsub-in-concat truncation, set -e interactions, rename hash stability; docs — 1 finding fixed (GPU-symlinks script is `run_onchange`, not `run_once`), all dependency claims verified against code. **Every backlog item is now fixed, deferred by owner decision (CHZ-1 wallpapers-in-git, LockSurface split), or rejected with rationale. Review complete.**

**Session 9 (2026-07-02) — Wave 4 Quickshell batch: QS-7..12 complete.** QS-7: Network.qml detects the station device via `iwctl device list` (wlan0 fallback until detection lands, self-corrects next poll); all five commands reference `root.device`; SSID parsing switched to right-anchored regexes (rsplit semantics — verified against live iwctl output including a real spaced SSID "Steve Home" and synthetic 2+-space/`-59`-suffix cases), including the status awk which previously truncated connected SSIDs to their last word (`$NF`); the state-flap auto-scan is debounced by a 15s Timer (status poll untouched, so nothing stalls). QS-8: `Bluetooth._syncDevices`→`refresh()`, `Launcher._submenu`→`submenu` (+`onSubmenuChanged` handlers); `Launcher.activeScreen` unified with Popout's convention — now a ShellScreen object (`Hyprland.focusedMonitor?.screen`), Drawers compares `=== scope.modelData`; new `Audio.setVolume()` replaces VolumePopout's direct `sink.audio.volume` write. QS-9: new `services/SystemInfo.qml` (kernel/hostname/shell fetched once per shell start as one combined process; uptime + pacman counts re-fetched via `refresh()` on popout open) — SystemPopout's six embedded Processes deleted; PowerPopout's per-delegate Process and Wifi/BT's impala/bluetui Processes → `Quickshell.execDetached`; `Battery.refreshProfile()` re-polls the power profile on BatteryPopout open (external keybind/TLP changes were never reflected). QS-10: dead `syncPassModel()` deleted; the two `Connections { target: LockScreen }` blocks merged at root level (the survivors had already drifted — only one reset `oldText`); unused `PersistentProperties` dropped from Drawers. QS-11: phantom `popoutWidthNarrow` token removed from DEVGUIDE; active/connected guidance switched `blue`→`accent` (code was already uniform on accent); `layer.enabled: true`→`visible` at PopoutWrapper/Drawers (both have visible bindings that only drop when fully hidden — code aligned to guide rather than vice versa); "never hardcode" rule re-scoped honestly (colors strict, one-off internal geometry may stay inline); Wifi's Nerd-Font glyph exception documented. QS-12: `_tt` merged into `animDuration` (both 400); empty-state guard item moot since QS-1 (both popouts express it via `PopoutListView.emptyText`); LockSurface file split **deferred** — pure organization, and a lockscreen regression locks the owner out. Verified: live reload clean (one known mid-apply scanner race, self-resolved), headless smoke instance of all 8 popouts + LockSurface zero warnings exit 0, regexes tested against real iwctl output. Reviews (2 agents): correctness CLEAN (rename completeness, device-binding liveness, ShellScreen identity comparison, SystemInfo registration, LockSurface id scoping, setVolume parity all verified); docs reviewer found 3 stale `blue`-as-active mentions elsewhere in DEVGUIDE (fixed: When-to-Use table, Common Mistakes, import example). **Wave 4 Quickshell track done; remaining: HYP-1/2, BIN-3/4, CHZ-4/5, DOC-2.**

**Session 8 (2026-07-02) — THM-5 complete: btop + pane-fm themes generated from palettes.** The 20 hand-maintained files (10 btop `.theme`, 10 pane-fm `.css`) replaced by two chezmoi templates reading `active.json`: `btop/themes/palette.theme.tmpl` (the upstream Catppuccin role mapping applied to whichever palette is active — renders **byte-identical** to the four deleted Catppuccin themes; everforest/nord/rosé-pine intentionally shift from their upstream artistic btop themes, some of whose colors weren't even in the palettes, to the uniform role-mapped look) and `pane-fm/themes/palette.css.tmpl` (the 10 old files were already one uniform role mapping — verified identical across all 10 palettes modulo hex case and `0.7`→`0.70`; `--accent` = `_accent`, `--accent-hover` = sapphire). Both apps now point at the generated theme statically — `color_theme = "palette"` in btop.conf, `theme = "palette"` in pane-fm's config, which became `config.toml.tmpl` so `light_icons` follows `{{ eq $p._variant "light" }}` (verified `true` under latte). `_btop_theme`/`_pane_fm_theme` deleted from all 10 palettes + their validation checks; `update_btop`/`update_pane_fm` deleted from theme-switch. **Drive-by bug found & fixed: THM-2 had silently broken `update_zed`** — it copied the raw `settings.json.tmpl` text (now containing `{{ }}` tokens post-conversion) over live Zed settings every switch, then apply's rename "fixed" it, killing the inode watch the function existed to protect. Replaced by `sync_rendered_in_place()` (renders via `chezmoi cat`, writes in place pre-apply) over `INODE_WATCHED_TARGETS` = Zed settings + pane-fm `palette.css` — pane-fm's theme watcher is an inode-level `notify` watch too (confirmed in its Rust source: `watcher.watch(&file)`), and with `theme = "palette"` now constant, the config-watcher reload path that used to mask this is gone. Verified: parity as above (4/4 catppuccin btop identical, 10/10 pane-fm), `theme-switch rose-pine` → `catppuccin-mocha` roundtrip (correct colors in both generated files, Zed live settings properly *rendered*, `light_icons` flip, `chezmoi status` clean, `--list` works, py_compile passes); stale deployed per-palette theme files removed from `~/.config`. Reviews (2 agents): correctness CLEAN (ordering active.json→cat→apply, `~` expansion, TOML validity, all role refs exist, no dangling references repo-wide; 1 nit fixed — `rewrite_config_keys`' `uncomment` param went dead with `update_pane_fm`); docs CLEAN (1 wording nit fixed). Net −1000 lines. Adding a palette is now: palette JSON + hand-made Zed theme + `_ghostty_theme` check — btop/pane-fm come free. **Wave 3 Track A complete.**

**Session 7 (2026-07-02) — THM-2 complete: Jinja pipeline deleted.** Converted the last five templates (gtk-3.0, gtk-4.0, phylax, zed `settings.json`, obsidian `theme.css`) to chezmoi-native templates and removed the entire Jinja stage. Key moves: only **two** new helpers were needed — `.chezmoitemplates/rgba` and `rgb_values` (hex→decimal via sprig `int "0x.."`, which parses base-0 like Go's `ParseInt` — no digit-map needed; `hex`/`hex_alpha`/`rgb`/`strip` were unused by the remaining templates and were not ported). The derived `_accent`/`_accent_h/_s/_l` keys moved from render-time-only to **persisted in `active.json`** (computation hoisted above the write in `main()`), so gtk/obsidian templates read them like any role; Python remains the sole HSL computer (no template math, byte-parity free). Obsidian's `TEMPLATE_OUTPUT_OVERRIDES` special case dissolved — its template is now a normal source file `knowledge/dot_obsidian/themes/Palette/theme.css.tmpl` (that path was inside the chezmoi source tree all along). theme-switch: `process_templates`, `create_jinja_env`, all 8 filters, `TEMPLATE_DIR`/`TEMPLATE_OUTPUT_OVERRIDES`, jinja2 imports and the PEP 723 dependency deleted (script now has zero third-party deps); `dot_config/theme-templates/` removed; `.chezmoiignore` entry dropped. Drive-by fix: a stray `●` byte (U+25CF paste artifact) at the top of phylax's CSS, deployed verbatim until now, dropped during conversion. Verified: byte-parity of all 5 templates × all 10 palettes (old Jinja render vs `chezmoi cat`, ● asserted as the only delta), then a full deployed-binary `theme-switch rose-pine` → `catppuccin-mocha` roundtrip — all five targets themed correctly (incl. obsidian accent HSL 267 under rose-pine), `chezmoi status` clean, `--list` works, py_compile passes. Reviews (2 agents): no correctness bugs — helpers verified on uppercase hex + integer opacities, all conversions diffed 1:1 vs deleted sources, no dangling Jinja references repo-wide. Six doc-level findings fixed (four stale "Generated from theme template" header comments, README mis-listing Zed as direct-write, an impossible `e6` alpha byte in a README example); one false positive rejected (claimed stale `~/.config/theme-templates` on deployed machines — the dir was always `.chezmoiignore`d and never deployed). CLAUDE.md + README rewritten to the single-pipeline story. **Wave 3 Track A: THM-2 done; THM-5 next.**

**Session 6 (2026-07-02) — branch merged + THM-2 pilot (yazi + hyprlock on chezmoi-native templates).** `floating-bar-popouts` fast-forwarded into main (19 commits, whole floating-island line), pushed, branch deleted local+remote; DOC-1 done (FLOATING_ISLAND_PLAN.md deleted post-merge). THM-2 pilot on branch `thm2-native-templates`: `yazi/theme.toml.tmpl` (bare substitution) and `hypr/hyprlock.conf.tmpl` (filter helpers) converted to real chezmoi templates — each starts `{{- $p := include "dot_config/palette/active.json" | fromJson -}}`; new `.chezmoitemplates/hypr_rgb` + `hypr_rgba` replicate the Jinja filters (alpha truncation semantics match: python `int(o*255)` ≡ sprig `int (mulf 255.0 o)`, both truncate float64). Their `.theme` sources deleted — `process_templates` globs `*.theme` so no theme-switch code change needed; the pattern is the `hyprland.lua.tmpl` precedent (no `.theme` → the `.tmpl` is the edited source). Verified: byte-parity of both templates across **all 10 palettes** (old Jinja render via imported theme-switch env vs `chezmoi cat` with each palette temporarily as source active.json), plus full `theme-switch rose-pine` → `catppuccin-mocha` roundtrip — correct colors in both targets, `chezmoi diff`/`status` clean. Hygiene: `**/__pycache__` added to `.chezmoiignore` (tooling created it in source twice now). CLAUDE.md theme-system section documents the split state (migrated: yazi, hyprlock; still Jinja: gtk×2, phylax, zed, obsidian). Review agent: no correctness bugs — verified alpha truncation byte-identical for 0.05–1.0 incl. 1.0→`ff`, `include`/`.chezmoitemplates` mechanics correct, missing-role failure loud (`missingkey=error` + theme-switch checks apply exit), CLAUDE.md accurate; two follow-ups taken (`__pycache__/` → `.gitignore`, stale hyprlock line in HYPRLAND_0.55_MIGRATION.md fixed). One accepted semantic shift it flagged: validation now gates only theme-switch — a hand-edited source `active.json` flows through bare `chezmoi apply` unvalidated (old pipeline structurally couldn't render post-validation-bypass; acceptable, noted). Remaining THM-2 work: gtk/phylax/zed/obsidian conversion (needs `rgba`/`hex_alpha`/`rgb_values` helpers incl. hex→decimal digit-map, and a decision on obsidian's non-standard output path), then strip theme-switch's Jinja stage entirely.

**Session 5 (2026-07-02) — QS-4 complete (launcher cleanup, Wave 3 Track B done).** Launcher.qml 582→477 plus new `services/LauncherProviders.qml` (83 — static keybind/action/main-menu tables extracted; renamed `keybinds`/`actions`/`mainItems`/`keybindItems`, referenced lazily so no singleton init-order hazard). The four ladder loops (`_filterApps/Windows/Keybinds/Actions`) collapsed into one `_score(terms, primary, secondary, weights)`; secondary fields are space-joined (safe — terms are whitespace-split so they can't span the join boundary). `_filterClipboard` stays a boolean `terms.every()` filter by design (fixed score 1, no ladder — matches HEAD including the empty-terms edge). `_scanThemes` no longer builds inline python3: `theme-switch` gained a `--list` subcommand (same `file|name|swatches` format, `.get`-default accent semantics, per-file exception swallowing preserved after review) dispatched before `asyncio.run(main())` — no side effects. Intentional delta: `--list` reads the chezmoi source palette dir instead of `~/.config/palette` (matches what `theme-switch <name>` can actually load); byte-diffed equal. Also fixed in session 4's aftermath (committed 186f8fd): Zed theme hot-reload — chezmoi's atomic-rename apply killed Zed's inotify watch after the first switch; theme-switch now syncs Zed settings in place before apply so the inode never changes. Verified: `--list` byte-parity vs the old inline python; HEAD-vs-new headless diff harness over 12 term sets × keybinds/actions + clipboard/calc edge cases → identical output; live reload clean. Review: parity agent found 1 genuine break (exception scope narrowed — one malformed palette would kill the whole listing instead of skipping itself; fixed by wrapping the full per-file body), rest clean including byte-identical tables and exact weights/tiers/penalties; correctness agent CLEAN (same single finding; self-import/init-order, block-binding, `--list` side effects, PATH all verified sound).

**Session 4 (2026-07-01) — QS-3 + QS-5 + QS-6 complete (bar dedup, Wave 3 Track B).** BarContent.qml 361→231: the duplicated side/top layouts (every item ×2, entrance boilerplate ×12) replaced by one flow-switched GridLayout with inline `BarItem { step; popout }` (entrance shift+fade, orientation-aware alignment, sizes to first child, optional hover-popout wiring) and `Spacer { size; fill }` components — the same GridLayout-flow idiom Workspaces/StatusIcons/TrayOverflow already used. `Services.Popout` gained `showFrom(item, name, screen)` (the old ×3-duplicated `_showPopout`) and `barItemExited()` (the old ×12 inline `barItemHovered = false; requestClose()`); all call sites migrated. Icon ladders centralized following the Battery pattern: `Audio.icon`, `Brightness.icon`, `Network.signalIcon` + `signalIconFor(level)` (glyph array was duplicated ×3); Bluetooth's ladders deliberately left local (bar and popout genuinely differ). One design subtlety: the tray BarItem duplicates TrayOverflow's `visible` condition on the instance because QML `visible` reads *effective* visibility — binding parent to child would latch false forever once hidden. Net −161 lines. Verified: live reload clean, headless smoke instance (BarContent + all 8 popouts) zero warnings exit 0. Review: parity agent CLEAN (item order/spacers/entrance params/clock variants/ladder thresholds/glyph codepoints/protocol semantics all byte-equivalent; also confirmed the refactor halves live object count — HEAD ran hidden duplicates of Workspaces/TrayOverflow/StatusIcons); correctness agent NO DEFECTS (verified default-alias child routing, sizing reactivity, and `columns: -1` empirically in a Qt 6 runtime; 2 observations — click-swallowing MouseAreas, unclamped negative signal level — both inherited from HEAD, rejected under parity). DEVGUIDE bar-item-hover section updated to the new API.

**Session 3 (2026-07-01) — QS-1 complete (popout component library, Wave 3 Track B start).** Built `modules/bar/popouts/components/` — 12 shared primitives (PopoutColumn width-spacer base, Separator, SectionLabel, SectionHeader w/ spinning refresh, ConnectionHeader crossfade w/ icon slot, IconButton, PillButton, ListRow hover row w/ default-alias content, PopoutListView w/ empty state, FlowBar masked flowing gradient, FlowSlider display-only slider emitting pressStarted/moved/released, EmptyLabel) — and rewrote all 9 popouts + PopoutWrapper onto them. Popouts 3314 → 2635 total lines (net −679; VolumePopout 592→302, Wifi 370→133, BT 416→165). PopoutWrapper's tray Loader collapsed into the shared `component Popout` via new `recreateOnOpen` flag. DEVGUIDE "Popout Patterns" converted from copy-paste prose to component docs. Verified three ways: live shell reloads clean (one mid-`chezmoi apply` scanner race, self-resolved), headless second-instance smoke test instantiating all popouts (zero warnings, exit 0), and user-driven interactive test on the live bar (zero new log lines). Review: parity agent CLEAN (6/6 areas; one sub-pixel note on transport-row height accepted); component agent raised 6 — 2 fixed (2-color FlowBar gradient now shifts a full pattern period per loop, fixing a pre-existing battery-bar snap; IconButton bounce gated on `enabled`), 3 rejected as parity-with-original (seek-bar drag coupling, 8px spacer gap, crossfade width share — all match the old code byte-for-byte), 1 false positive (nested layouts default `Layout.fillWidth: true`, headers stretch as before).

**Session 2 (2026-07-01) — Wave 2 complete (theme-system integrity).** Fixed: THM-1 (ghostty/btop/pane-fm direct-writes retargeted to the chezmoi source, run before `chezmoi apply`; ghostty+btop added to `themed_targets`; acceptance: `chezmoi diff`/`status` fully clean after a switch), THM-8 (shared `rewrite_config_keys` helper replaces the ×3 copy-paste; single palette load; chromium warning fix; `CHEZMOI_ROOT` via `chezmoi source-path`), THM-6 (atomic active.json via temp+rename; chezmoi exit code checked → critical notify + exit 1; success toast only on real success), THM-4 (`StrictUndefined` + `validate_palette`: 26 roles/hex/btop+pane-fm file existence/zed names; all 10 palettes pass, negative tests rejected), THM-7 remainder (accent added to 3 catppuccin darks = their blue; real `_zed_theme_dark` for 3 light palettes; rose-pine "inversion" re-checked — moon inverts too, consistent upstream overlay→base mapping, intentional; `islandShadowColor` already documented in Theme.qml). Two review agents: verifier 6/6 pass; code reviewer found no blocking bugs + 3 minor items — 2 fixed (btop now killed *before* apply so its exit-save can't clobber the theme; missing-key insertion warns), 1 accepted as-is (chromium PermissionError still non-fatal — cosmetic wash). Ghostty source header tidied. Re-ran `theme-switch catppuccin-mocha` end-to-end: clean.

**Session 1 (2026-07-01) — Wave 1 complete.** Fixed: CHZ-2 (ignore gaps; HYPRLAND docs moved to `docs/`; stray `~/HYPRLAND_*.md`, `~/LICENSE`, `~/references/`, `~/.config/theme-templates/` deleted), CHZ-3 (phantom prompts removed; README graphics list synced), BIN-1 partial (compose ports → 127.0.0.1; "restart" message fixed), BIN-2 (toggle-bar-mode writes both copies), THM-7 partial (hyprlock bg → `path = screenshot` + palette color fallback; `_wallpaper` key deleted from all 11 palettes), QS-2 (IconCache singleton), CHZ-6 partial (fnm guard), THM-3 (deleted duplicate `hyprland.lua.theme`; CLAUDE.md/README updated), HYP-2 partial (hypridle doc sentence fixed; migration docs archived to `docs/`). Regenerated via `theme-switch catppuccin-mocha` + targeted `chezmoi apply`; two review agents on the diff → 1 real finding (stale README:164 reference, fixed), 1 false positive rejected (reviewer claimed ghostty chezmoi-diff was clean — re-verified: **THM-1 still reproduces**, apply would delete Ghostty's theme lines). Icon-cache startup-window race accepted as-is (self-heals per open; optional `rev` hardening declined).

---

## 0. TL;DR — the five findings that matter most

1. ~~**`chezmoi apply` un-themes the system.**~~ ✅ session 2 — direct-writes now target the chezmoi source and propagate via `chezmoi apply`; diff/status verified clean. → [THM-1](#thm-1)
2. **The Jinja stage is largely vestigial.** Most generated `.tmpl` files contain zero Go template syntax; `hyprland.lua.theme` → `.tmpl` is a byte-identical copy. Chezmoi-native templates reading `active.json` via `fromJson` would eliminate the second template language, the committed-generated-file class, and the "edit the wrong file" trap. → [THM-2](#thm-2)
3. ~~**The repo is 630 MB**~~ deferred session 9 — wallpapers deliberately stay in git (owner's call); revisit only if churn makes the repo painful. → [CHZ-1](#chz-1)
4. **Repo docs are deployed into `$HOME`.** `.chezmoiignore` gaps mean `~/HYPRLAND_0.55_*.md`, `~/LICENSE`, `~/references/`, and inert `~/.config/theme-templates/` exist right now. → [CHZ-2](#chz-2)
5. ~~**Quickshell popouts have no shared component library.**~~ ✅ session 3 — 12-component library in `modules/bar/popouts/components/`, all popouts rewritten, net −679 lines. → [QS-1](#qs-1)

Plus one security item: **win-vm exposes RDP + web UI on 0.0.0.0 with default creds** ([BIN-1](#bin-1)).

---

## 1. Theme system

### THM-1 · P0 · M — Direct-write apps break under plain `chezmoi apply` ✅ session 2 <a name="thm-1"></a>

- [x] Fixed: ghostty/btop/pane-fm writes now target `CHEZMOI_SOURCE_DIR`, run **before** `chezmoi apply`, and `~/.config/ghostty` + `~/.config/btop` were added to `themed_targets`. Acceptance verified: `chezmoi diff` for ghostty/btop/pane-fm/palette is empty after `theme-switch catppuccin-mocha`; `chezmoi status` fully clean.

### THM-2 · P1 · L — Replace the Jinja stage with chezmoi-native templates ✅ sessions 6–7 <a name="thm-2"></a>

- [x] **Pilot (session 6):** yazi + hyprlock converted; `.chezmoitemplates/hypr_rgb` + `hypr_rgba` helpers; byte-parity ×10 palettes + theme-switch roundtrip verified. Mechanism proven.
- [x] **Remaining conversions (session 7):** gtk-3.0, gtk-4.0, phylax, zed `settings.json`, obsidian `theme.css` all converted. Only two new helpers were actually needed (`rgba`, `rgb_values` — hex→decimal via sprig `int "0x.."` base-0 parse; `hex`/`hex_alpha`/`rgb`/`strip` were unused by the remaining templates). Obsidian's `TEMPLATE_OUTPUT_OVERRIDES` write became a normal source file `knowledge/dot_obsidian/themes/Palette/theme.css.tmpl`. The derived `_accent`/`_accent_h/_s/_l` keys now persist into `active.json` (computed before the write) so templates can read them.
- [x] **Jinja stage deleted (session 7):** `process_templates`, `create_jinja_env`, all 8 filters, `TEMPLATE_DIR`/`TEMPLATE_OUTPUT_OVERRIDES`, the jinja2 imports and PEP 723 dependency removed from theme-switch; `dot_config/theme-templates/` deleted; `.chezmoiignore` entry dropped; CLAUDE.md + README rewritten to the single-pipeline story.
- Original finding: `grep '{{'` across all generated `.tmpl`s matches only `hyprland.lua.tmpl` (machine `graphics` conditionals) — the rest are fully-rendered files wearing a `.tmpl` extension, and chezmoi still Go-templates them, so any future literal `{{` breaks apply.
- **Alternative:** `{{ $p := include "dot_config/palette/active.json" | fromJson }}` in each template, with the 8 custom Jinja filters (`executable_theme-switch:74-110` — `rgba`, `hypr_rgba`, etc.) as small `.chezmoitemplates` helpers. Then only `active.json` needs committing; `theme-switch` shrinks to *copy palette → chezmoi apply → source-writes → reloads*; theme switches stop producing multi-file generated-color diffs in history (cf. 889ffaa, 6673e69); the fresh-clone story is preserved.
- **Cost:** Go's clumsier filter syntax. Latency unchanged — theme-switch already runs `chezmoi apply`.
- Also collapses the current **five output modalities** (Jinja→`.tmpl`→Go · Jinja→final-in-source for Obsidian via `TEMPLATE_OUTPUT_OVERRIDES` `:45-47` · direct-write-to-live · generated `palette.lua` · `/etc` Chromium policy) down to two.

### THM-3 · P0 · S — `hyprland.lua.theme` ↔ `.tmpl` are byte-identical; delete the `.theme` ✅ session 1

- [x] Verified: `dot_config/theme-templates/hypr/hyprland.lua.theme` and `dot_config/hypr/hyprland.lua.tmpl` are identical (13,037 bytes, 298 lines). Since ec0a596 the file has zero `{< >}` tokens (colors come via `require("palette")`), so the Jinja render is an identity copy — double diffs on every edit, and editing the `.tmpl` directly gets silently clobbered. The "Generated from theme template" header (`.theme:3`) is false in the source itself.
- **Fix:** delete the `.theme`, make `dot_config/hypr/hyprland.lua.tmpl` the single edited source, skip it in `process_templates` (`executable_theme-switch:176-194`). Update CLAUDE.md. (Subsumed by THM-2 if that lands first.)

### THM-4 · P1 · S — No validation anywhere; Jinja renders missing keys as empty strings ✅ session 2

- [x] Fixed: `StrictUndefined` in the Jinja env (render errors notify-critical + exit 1 with the template name) and `validate_palette()` runs before anything is written: 26 required roles present + hex format, `_btop_theme`/`_pane_fm_theme` files exist (checks removed in session 8 — the keys are gone, themes are generated), zed theme names checked against `dot_config/zed/themes/*.json`, the active variant's zed theme must be nonempty. All 10 palettes pass; negative tests (missing role, bad hex, bogus refs, undefined token) all rejected. `_ghostty_theme` stays nonempty-only — built-in Ghostty themes have no cheap existence check.

### THM-5 · P1 · M — Adding a palette = 5 artifacts, 4 naming conventions; generate the generatable ones ✅ session 8

- [x] ✅ session 8 — btop and pane-fm themes are now single chezmoi templates (`palette.theme.tmpl` / `palette.css.tmpl`) rendered from `active.json`; the 20 hand-maintained files and the `_btop_theme`/`_pane_fm_theme` keys (two of the four naming conventions) are gone. Configs point at `"palette"` statically. Zed themes stay hand-made as planned. New-palette cost: palette JSON + Zed theme + `_ghostty_theme` check.

### THM-6 · P1 · S — theme-switch has no failure handling ✅ session 2

- [x] `chezmoi apply` exit code now checked → notify-critical + exit 1; success toast only fires after everything succeeded.
- [x] `active.json` writes are atomic (`write_json_atomic`: temp + rename) — Quickshell can never observe a partial file.
- [x] Validation failures (THM-4) abort *before* active.json is touched. active.json-first ordering kept deliberately (instant Quickshell feedback); a mid-run death is now loudly reported instead of silently half-applied, and re-running remains idempotent.

### THM-7 · P2 · S — Palette schema drift + dead keys ✅ session 2

- [x] ✅ session 2 — `_quickshell.accent` added to mocha/frappe/macchiato, set to each palette's `blue` (identical to the existing fallback, so rendering is unchanged; accent is a deliberate per-palette choice elsewhere — e.g. Everforest green).
- [x] ✅ session 2 — `islandShadowColor` verified intentional and already documented at `utils/Theme.qml:145` ("defaults to crust; light variants override to overlay0"). No change.
- [x] ✅ session 1 — `_wallpaper` key deleted from all 11 palettes; hyprlock background now `path = screenshot` (blurred desktop) with `color = {< base | hypr_rgb >}` fallback.
- [x] ✅ session 2 — rose-pine inversion re-checked: **rose-pine-moon inverts too** (`surface0 #2a283e` < `base #393552`), so the original finding's premise ("every other palette follows") was wrong. Both dark Rosé Pines consistently map upstream *overlay* → `base` and *surface* → `surface0` (a deliberate brightening of the very dark upstream base). Intentional; no change.
- [x] ✅ session 2 — light palettes now set real `_zed_theme_dark` counterparts: latte → "Catppuccin Mocha", everforest-light → "Everforest", rose-pine-dawn → "Rosé Pine" (all verified installed in `zed/themes/*.json`).

### THM-8 · P2 · S — theme-switch code cleanup ✅ session 2

- [x] Shared `rewrite_config_keys(path, {key: line}, uncomment=False)` helper replaces the ×3 copy-paste; preserves original semantics (replace all matches, insert missing at top, pane-fm uncomment mode); tested against key-prefix collisions (`theme_background` vs `theme`).
- [x] Palette loaded once; `barMode` merged into `palette_data` before the active.json writes; computed `_accent*` keys added only after, so they're never persisted.
- [x] `update_chromium` now distinguishes "no policy dirs exist" from "dir exists but no write permission".
- [x] `CHEZMOI_ROOT` resolved via `chezmoi source-path` (5s timeout, hardcoded fallback).

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

### QS-1 · P1 · L — Popout component library ✅ session 3 <a name="qs-1"></a>

- [x] Built `modules/bar/popouts/components/` (12 components: `PopoutColumn`, `Separator`, `SectionLabel`, `SectionHeader`, `ConnectionHeader`, `IconButton`, `PillButton`, `ListRow`, `PopoutListView`, `FlowBar`, `FlowSlider`, `EmptyLabel`) and rewrote all 9 popouts onto it. Popouts 3314 → 2099 lines + 536 lines of components = **net −679** (in the 600–800 estimate). VolumePopout 592→302, Wifi 370→133, Bluetooth 416→165.
- [x] PopoutWrapper tray Loader dedup: the inline `component Popout` gained `recreateOnOpen`; the tray Repeater now instantiates `Popout` directly (−52 lines of verbatim states/transitions).
- [x] DEVGUIDE "Popout Patterns" rewritten from copy-paste prose to a component table + import examples; new module added to Import Convention.
- Intentional micro-deltas: Battery "Capacity"/"Power Profile" labels unified to `Font.Medium` (SectionLabel); BT header subtitle gained elide+fillWidth. Volume seek bar keeps `thumbBounce: false` to preserve its original static thumb.
- Verified: live shell reload clean, headless second-instance smoke test instantiating all 9 popouts (zero warnings), interactive hover/drag session on the live bar produced zero log output.

### QS-2 · P0 · S — TrayMenuPopout walks `/usr/share/icons` on every open ✅ session 1

- [x] Done: `services/IconCache.qml` singleton populated once at startup; TrayMenuPopout reads `Services.IconCache.icons`. Known accepted edge: a tray menu opened in the first ~1s after shell start may miss icons for that open only (delegates recreate per open, so it self-heals).

### QS-3 · P1 · M — BarContent duplicates every bar item ×2 layouts ✅ session 4

- [x] Done: one flow-switched GridLayout with inline `BarItem { step; popout }` + `Spacer { size; fill }` components; 361→231 lines, single live copy of Workspaces/TrayOverflow/StatusIcons (HEAD ran a hidden duplicate of each). Clock keeps both orientation variants (visibility-switched) with per-orientation implicit-size override; tray visibility condition duplicated on the BarItem instance (effective-visibility latch prevents binding to the child).

### QS-4 · P2 · M — Launcher.qml (582) mixes five concerns ✅ session 5

- [x] Four ladder loops → one generic `_score(terms, primary, secondary, weights)`; clipboard stays a boolean `terms.every()` filter (genuinely different semantics: fixed score, no ladder).
- [x] Static tables extracted to `services/LauncherProviders.qml` (keybinds/actions/mainItems/keybindItems); state machine + dispatch remain in Launcher.qml.
- [x] Inline python3 dropped: `theme-switch --list` emits the same `file|name|swatches` lines (palette knowledge now lives only in theme-switch; reads the chezmoi source dir, matching what `theme-switch <name>` loads).
- Note: `_evalCalc`'s `eval()` is regex-sanitized first — acceptable, documented here for the record.

### QS-5 · P2 · S — Icon ladders duplicated between bar and popouts ✅ session 4

- [x] Done: `Services.Audio.icon`, `Services.Brightness.icon`, `Services.Network.signalIcon` + `signalIconFor(level)` (glyph array now lives once in Network.qml); all bar + popout sites migrated, thresholds verified identical. Bluetooth ladders deliberately stay local — bar (`bluetooth_disabled`/`connected`/`bluetooth`) and popout (`connected`/`bluetooth`) genuinely differ.

### QS-6 · P2 · S — Bar-item exit protocol duplicated at ~12 call sites ✅ session 4

- [x] Done: `Services.Popout.barItemExited()` (symmetric counterpart to `show()`'s internal `barItemHovered = true`) and `Services.Popout.showFrom(item, name, screen)` (absorbs the duplicated `_showPopout` helpers); all 12 call sites across BarContent/StatusIcons/TrayOverflow migrated. Popout.qml now imports `qs.utils` (no cycle — Theme imports no `qs.*`).

### QS-7 · P2 · S — Network.qml hardening ✅ session 9

- [x] `wlan0` hardcoded in 5 commands (`Network.qml:45,116,159,239,279`) → detect the station name once via `iwctl device list` into a property.
- [x] Column-split on `/\s{2,}/` + SSID reconstruction via `join("  ")` (`:141,188,200`) is lossy for SSIDs with runs of spaces → treat last-two-columns as authoritative (rsplit-style). (Text parsing itself is forced — no Quickshell iwd module, iwctl has no JSON output.)
- [x] `onStateChanged` auto-`scan()` (`:88-94`) re-runs three processes per 3s poll cycle under connection flapping — debounce or gate on state transitions.

### QS-8 · P2 · S — API hygiene ✅ session 9

- [x] Private members used cross-module: `Services.Bluetooth._syncDevices()` (from `BluetoothPopout.qml:15`), `Services.Launcher._submenu` read by Drawers/LauncherPanel/WallpaperPicker incl. an `on_SubmenuChanged` handler → rename `refresh()` / `submenu`.
- [x] Screen identity typed inconsistently: `Popout.activeScreen` is a `ShellScreen` object; `Launcher.activeScreen` is a monitor-name string — pick one convention.
- [x] `VolumePopout.qml:196` writes `Services.Audio.sink.audio.volume` directly; add `Audio.setVolume()` beside `toggleMute`/`setSink`.

### QS-9 · P2 · S — Data acquisition in view code ✅ session 9

- [x] `SystemPopout.qml` embeds 6 one-shot Processes (kernel/uptime/hostname/shell/pacman×2, `:45-188`), re-running all six per open; kernel/hostname/shell are static per boot → `SystemInfo` service with cached statics.
- [x] PowerPopout creates a `Process` per Repeater delegate (`:116-118`); Wifi/Bluetooth embed `impalaProc`/`bluetuiProc` → use `Quickshell.execDetached` (the convention `Launcher.qml:310` already establishes).
- [x] `Battery.qml:62` reads the power profile once at startup — external changes (keybind, TLP) never reflected → watch `/sys/firmware/acpi/platform_profile` or re-poll on popout open.

### QS-10 · P2 · S — Dead code ✅ session 9

- [x] `LockSurface.syncPassModel()` (`LockSurface.qml:128-138`) — never called; `onTextChanged` (`:375-399`) reimplements it inline.
- [x] Two `Connections` blocks both handling `onClearInput` (`LockSurface.qml:142-155` and `:479-490`) — already drifted from each other (only the second resets `hiddenInput.oldText`). Merge.
- [x] `PersistentProperties { property bool bar: true }` (`Drawers.qml:187-190`) referenced nowhere.

### QS-11 · P2 · S — DEVGUIDE drift ✅ session 9

- [x] Token `popoutWidthNarrow: 180` (DEVGUIDE:109,183) doesn't exist in Theme.qml.
- [x] DEVGUIDE:39 says use `blue` for active/connected; code uniformly uses the `accent` role, which the roles list omits.
- [x] DEVGUIDE:303 prefers `layer.enabled: visible`; `PopoutWrapper.qml:223` and `Drawers.qml:137` use `layer.enabled: true` — align code or guidance.
- [x] "Never hardcode sizes" is heavily violated outside popouts (LockSurface wall-to-wall magic numbers `:214-217,256,314`; LauncherPanel durations; BarContent literals; Workspaces slot math) — either tokenize the recurring values or scope the rule to bar/popout surfaces in DEVGUIDE.
- [x] Wifi's Nerd-Font-glyph exception to MaterialIcon is deliberate but undocumented.

### QS-12 · P3 · S — Minor ✅ session 9 (LockSurface split deferred)

- [x] `Theme.qml`: `_tt: 400` duplicates `animDuration: 400` (`:35,230`) — merge tokens.
- [x] LockSurface natural split: **deferred session 9** — pure organization with lockout risk if a regression slips in; revisit only if the file grows.
- [x] Empty-state null-guard style differs between Wifi/Bluetooth popouts.

---

## 3. Chezmoi structure & bootstrap

### CHZ-1 · P1 · M — Repo is 630 MB of mostly regenerable wallpaper PNGs <a name="chz-1"></a> ⏸ deferred session 9

- [ ] `dot_config/wallpapers/` is 558 MB in the working tree (27 PNGs; `mars-race3.png` 25 MB); `git count-objects` size-pack is **630.71 MiB** — history also contains a deleted earlier generation of per-palette wallpaper trees. These are upscaled (`wallpaper-upscale` EDSR 4×) artifacts, i.e., regenerable.
- **Fix:** move wallpapers out of git — `.chezmoiexternal.toml` pointing at a release archive/separate repo, or git-lfs; `git filter-repo` to purge history; store pre-upscale JPG sources, keep `wallpapers.json` in-repo. (History rewrite — coordinate with any other clones.)
- **Deferred (session 9, owner decision): wallpapers deliberately stay in git** — a current version in the dots repo is wanted. Costs accepted: 630 MB clones and monotonic pack growth (history keeps every swapped-out PNG forever; one dead generation is already in the pack). Revisit if churn makes the repo painful — preferred shape then is a separate wallpapers git repo pulled via `.chezmoiexternal.toml` (still versioned, dots drop to ~5 MB), plus a one-time `git filter-repo` purge.

### CHZ-2 · P0 · S — `.chezmoiignore` gaps: repo docs deployed into `$HOME` <a name="chz-2"></a> ✅ session 1

- [x] Verified deployed with chezmoi-managed timestamps: `~/HYPRLAND_0.55_LUA_REFERENCE.md`, `~/HYPRLAND_0.55_MIGRATION.md`, `~/LICENSE`, `~/references/` (AGENTS.md, fastapi-structure-guide.md, dell-xps16-audio-issue.md, fix-sdca-modules.sh), and inert `~/.config/theme-templates/**` (templates are only ever read from the chezmoi source).
- `knowledge/` is **not** a gap — intentional Obsidian-vault deploy (README.md:93-96).
- **Fix:** add `HYPRLAND_0.55_*.md`, `LICENSE`, `references/`, `.config/theme-templates/` to `.chezmoiignore`; `chezmoi apply` removes the strays. Better: move the two 29 KB Hyprland notes into `docs/` (already ignored) and relocate the non-dotfiles content of `references/` (fastapi guide, AGENTS.md) to the knowledge vault.

### CHZ-3 · P0 · S — Commented-out prompts in `.chezmoi.toml.tmpl` still execute ✅ session 1

- [x] `.chezmoi.toml.tmpl:9-10`: `#`-commented `promptStringOnce` lines for email/name still run as template actions — fresh `chezmoi init` prompts for both, discards the answers into comments, and re-prompts on every future init (values never land in `[data]`). Delete or uncomment.
- README.md:239 lists graphics options `amd, prime, nvidia` but the template offers `amd, intel, prime, nvidia` — sync.
- (The rest of the file is good: `promptChoiceOnce`, lspci-autodetected PCI defaults.)

### CHZ-4 · P2 · S — run-script hygiene ✅ session 10

- [x] ✅ session 10 — renamed to `run_once_setup-greetd.sh` with contents byte-identical (chezmoi keys run_once state on the content hash, so the rename never re-runs it / never sudo-prompts). `start-hyprland` dependency and the /etc-heredoc-drift trade-off documented in README's Dependencies section instead of in the script — keeping the hash stable.
- [x] ✅ session 10 — check-and-fix inside theme-switch **rejected**: setfacl needs root, and sudo prompts inside a theme switcher is the wrong trade. Instead the PermissionError warning now names the fix: re-run the script via `bash "$(chezmoi source-path)/run_once_setup-chromium-policies.sh"` (idempotent).
- [ ] `run_onchange_setup-gpu-symlinks.sh.tmpl` and `run_once_before_create-default-monitors-lua.sh`: correct lifecycles, idempotent — no action.
- [x] ✅ session 10 — README Install notes now state the setup scripts need interactive sudo (unattended init --apply stops and prompts).

### CHZ-5 · P2 · S — Vestigial and legacy pieces ✅ session 10

- [x] ✅ session 10 — deleted from source (zero consumers confirmed again). Deployed `~/.config/age` left on disk, now unmanaged — remove by hand if unwanted.
- [x] ✅ session 10 — removed from source + README tree (git history preserves it). Deployed `~/.config/sddm-theme` left on disk, now unmanaged — remove by hand.
- [x] ✅ session 10 — deleted.

### CHZ-6 · P2 · S — Bootstrap gaps (fresh-machine story) ✅ session 10

- [x] ✅ session 1 — `dot_bashrc:22` `eval "$(fnm env)"` is unguarded — every interactive shell errors on a machine without fnm. Guard: `command -v fnm >/dev/null && eval "$(fnm env)"`.
- [x] ✅ session 10 — README Dependencies section now lists uv, jq + ImageMagick, fnm, setfacl, tuigreet/greeter/start-hyprland with what needs each.
- [x] ✅ session 10 — documented in README Install notes.
- [x] ~~Nothing enforces `.theme` ↔ `.tmpl` sync~~ — moot since THM-2 (session 7): `.theme` sources no longer exist; `.tmpl` files are the only sources.

---

## 4. Hyprland

### HYP-1 · P2 · S — `pcall(require, "monitors")` swallows errors silently ✅ session 10

- [x] ✅ session 10 — pcall result captured; on failure the error is printed to the Hyprland log **and** raised as a critical notify-send via `hl.exec_cmd` (single-quote escaping of the Lua error message tested against a real syntax-error string; success path verified silent).

### HYP-2 · P3 · S — Doc drift ✅ session 10

- [x] ✅ session 1 — both `HYPRLAND_0.55_*.md` files archived into `docs/`.
- [x] ✅ session 1 — CLAUDE.md hypridle sentence fixed.
- [x] ✅ session 10 — deduped into a local `screenshot(grab)` helper; output asserted byte-identical to both old command strings. Stale "Generated from theme template" file header also fixed (hand-edited chezmoi template).

*(Positive: the dropped-auto-suspend cleanup is exemplary — `hypridle.conf` comments point to `dot_config/hypr/README.md`, which documents the xe crash, the removed listener verbatim, and a re-test procedure. Keybind organization, table-driven animations, and in-place quirk comments are all clean.)*

---

## 5. Bin scripts

### BIN-1 · P0 · S — win-vm exposes RDP/web UI on all interfaces with default creds <a name="bin-1"></a> ✅ sessions 1+10

- [x] ✅ session 1 — compose ports now bound to `127.0.0.1` (takes effect on next `docker compose up`, i.e. container recreate).
- [x] ✅ session 10 — `set -euo pipefail` added; `notify-send || true` so headless runs survive; all subcommand paths smoke-tested with docker inactive.
- [x] ✅ session 10 — `connect()` function (includes the "Connecting to VM..." toast; `open` gains it too).
- [x] ✅ session 1 — `:18` message now says "log out and back in".
- [x] ✅ session 10 — `open` exits 1 with a hint when docker/VM is down; `restart` notifies "VM is not running." and exits 0, matching `stop`.

### BIN-2 · P0 · S — toggle-bar-mode causes chezmoi-source drift <a name="bin-2"></a> ✅ session 1

- [x] Done: writes both live and chezmoi-source `active.json`, matching theme-switch's format exactly (`indent=2`, no trailing newline — intentional, to avoid diff churn against theme-switch's writes).

### BIN-3 · P2 · S — wallpaper-split robustness ✅ session 10

- [x] ✅ session 10 — `magick identify` and the center-crop both guarded with `[error] … — skipping` + continue (verified: corrupt PNG in a batch is reported and skipped, batch completes exit 0).
- [x] ✅ session 10 — `mktemp --suffix=.$FORMAT` + EXIT trap (no leftover temp files after run).
- [x] ✅ session 10 — required up front with a clear error; the per-image `if command -v jq` branch removed. (Surfaced by the smoke test: jq isn't currently installed on this machine — `pacman -S jq` before the next split run.)
- (Otherwise the best-hygiene script of the set.)

### BIN-4 · P3 · S — wallpaper-upscale nits ✅ session 10

- [x] ✅ session 10 — removed; `--force` help text now notes skipping is the default.
- [x] ✅ session 10 — plain string.

*(The two wallpaper scripts are sequential pipeline stages in different domains — don't merge them.)*

---

## 6. Docs & meta

- [x] **DOC-1 · P3** — `FLOATING_ISLAND_PLAN.md` deleted after the `floating-bar-popouts` merge (session 6); git history preserves it.
- [x] **DOC-2 · P3** ✅ session 10 — everything had already landed incrementally (single-pipeline story session 7, direct-write list session 8, graphics list + hypridle session 1); this session added the Dependencies/Install-notes section and dropped sddm-theme from the tree. Nothing left.

---

## Suggested sequencing

**Wave 1 — quick wins, active bugs (all S):** ✅ done session 1.

**Wave 2 — theme-system integrity (S/M):** ✅ done session 2 (THM-1, THM-4, THM-6, THM-7, THM-8).

**Wave 3 — structural (M/L, independent tracks):**
- Track A: ~~THM-2 (chezmoi-native templates)~~ ✅ sessions 6–7 → ~~THM-5 (generate btop/pane-fm)~~ ✅ session 8. **Track A complete.**
- Track B: ~~QS-1 (popout components)~~ ✅ session 3 → ~~QS-3 (BarItem) / QS-5/QS-6 (ladders, exit protocol)~~ ✅ session 4 → ~~QS-4 (launcher scorer)~~ ✅ session 5. **Track B complete.**
- Track C: ~~CHZ-1 (wallpaper degit + history purge)~~ ⏸ deferred session 9 — wallpapers stay in git by owner decision. **All Wave 3 tracks closed.**

**Wave 4 — polish:** ~~QS-7/8/9/10/11/12~~ ✅ session 9 · ~~DOC-1~~ ✅ session 6 · ~~HYP-1/2, BIN-3/4, CHZ-4/5, DOC-2~~ ✅ session 10 (+ BIN-1/CHZ-6 leftovers). **Backlog complete — every item fixed, deferred by owner decision (CHZ-1, LockSurface split), or rejected with rationale.**
