# Hyprland 0.55 — hyprlang → Lua migration

Per-section surface area + Lua API mapping for the 0.55 port. See `HYPRLAND_0.55_LUA_REFERENCE.md` for the full API surface. Check items as they land.

> **Status:** Tier 1 ported and verified via `Hyprland --verify-config` (zero errors). Pending user logout/login to take over from running hyprlang session, then Tier 3 (Quickshell IPC) sweep. Option C palette.lua deferred as polish; Jinja-embedded colors work as-is.

---

## 1. Architecture decisions

### Decided

- [x] **File extensions** — `*.conf.theme` → `*.lua.theme`, `*.conf.tmpl` → `*.lua.tmpl`. Chezmoi destination is `~/.config/hypr/hyprland.lua` (Hyprland 0.55 default per reference intro).
- [x] **Template-layer architecture** — **Option C (hybrid with A)**. theme-switch gains a `palette.lua` direct-writer alongside its existing direct-writes (Ghostty, btop, pane-fm, Chromium). `hyprland.lua` does `local p = require("palette")` and references `p.surface0`. The Jinja layer stays for all non-Lua targets (GTK, Phylax, Yazi, Zed, Obsidian, hyprlock — static-file consumers). chezmoi Go templating stays for GPU branching. Unlocks: (1) `hyprctl reload` applies palette changes without re-running chezmoi; (2) Hyprland's own `animation = border` curve drives color transitions because the value changes inside a single reloaded process. Net theme-switch change: +1 direct-writer, ~30 LOC.
  
  > **Cross-section note**: §3 snippets show inline Jinja tokens (`{< surface0 | hypr_rgba(0.93) >}`). Per Option C, replace those at port time with `p.surface0_rgba(0.93)`-style helpers. The `hypr_rgba`/`hypr_rgb` filters get re-implemented once as Lua functions inside the generated `palette.lua`. §3 examples remain in Jinja form so they're recognizable from the current `.theme` file.

### Resolved (from §8.4 evidence — 2026-05-11)

- [x] **monitors.conf format** → **monitors.lua + `pcall(require, "monitors")`**. Confirmed `require` works from `~/.config/hypr/` (shipped `/usr/share/hypr/hyprland.lua:10` advertises `require("myColors")`). Wrapped in `pcall` so a missing file doesn't abort config load.
- [x] **hypridle fate** → **keep external daemon, unchanged**. `HL.EventName` in `/usr/share/hypr/stubs/hl.meta.lua:5–33` enumerates 27 events; **no idle event**. Polling via `hl.timer` would be strictly worse than the daemon. Defer fold-in until upstream adds an idle event.
- [x] **Sibling tool versions** — installed: `hyprlock 0.9.5-2`, `hypridle 0.1.7-9`, `hyprcursor 0.1.13-6`. No `hyprpaper` (Quickshell handles wallpaper). hyprlock + hypridle stay hyprlang on independent cadence (their configs are not Lua in 0.55; they're separate daemons with their own grammars).

**Other evidence captured:**
- Running compositor: 0.54.3; on-disk binary: 0.55.0-3. Reboot required to test new config.
- `start-hyprland` survives at `/usr/bin/start-hyprland` (owned by `hyprland 0.55.0-3`). Greetd path intact; `run_once_setup-greetd.sh.tmpl:16` needs no change.
- `/usr/share/hypr/stubs/hl.meta.lua` (1250 lines) shipped — wire this into lua-language-server as `workspace.library`.
- `/usr/share/hypr/hyprland.lua` (356 lines) is the shipped canonical example — strong reference for syntax patterns.

---

## 2. Prerequisites (verification)

- [x] ~~Lua syntax reference~~ — captured in `HYPRLAND_0.55_LUA_REFERENCE.md`
- [x] ~~Read `/usr/share/hypr/stubs/`~~ — read `hl.meta.lua` (1250 lines); resolutions folded into §3 and §7.
- [x] ~~Verify installed Hyprland version~~ — confirmed 0.55.0 running.
- [ ] **Wire stubs into lua-language-server** — add `/usr/share/hypr/stubs/` to `workspace.library` in `.luarc.json` at the chezmoi repo root (or per-machine) so the editor gets completion/diagnostics on `hl.*` calls during the port.
- [ ] **Determine Lua runtime** — Lua 5.1, 5.4, or LuaJIT? Affects available features (`goto`, integer division `//`, bitops). `hl.version()` may tell you; failing that, `print(_VERSION)` from a small test require. *Low priority — shipped config doesn't use any version-sensitive features.*

**Discovered during evidence gathering**: Hyprland 0.55 still parses hyprlang grammar (the current `hyprland.conf` loaded with just three deprecation errors: `togglesplit` dispatcher removed, `dwindle:pseudotile` removed, `misc:vfr` moved to `debug.vfr`). The Lua migration is therefore voluntary, not forced. The branch continues as a clean architectural upgrade with rollback to `main` as a safe fallback.

---

## 3. Tier 1 — Config file ports

### `dot_config/theme-templates/hypr/hyprland.conf.theme` → `hyprland.lua.theme` (280 lines)

- [x] **Header / globals** (L1–14) — hyprlang `$var = ...` becomes Lua `local`:
  ```lua
  local terminal     = "ghostty +new-window"
  local editor       = "zeditor --wait"
  local file_manager = "ghostty -e yazi"
  local mod          = "SUPER"
  ```

- [x] **Env vars** (L17–42) — `env = K,V` → `hl.env("K", "V")`. Keep GPU-conditional in chezmoi Go template, or move to `machine.lua` per §1.
  ```lua
  hl.env("EDITOR", "zeditor")
  hl.env("HYPRCURSOR_SIZE", "24")
  {{ if eq .graphics "intel" -}}
  hl.env("LIBVA_DRIVER_NAME", "iHD")
  {{ end -}}
  ```

- [x] **Monitor source** (L48) — `source = $HOME/.config/hypr/monitors.conf` → `require("monitors")` (file rename: `monitors.conf` → `monitors.lua`).

- [x] **Autostart** (L53–61) — collapse 10 `exec-once` lines into one event handler. Reference §13 confirms `hl.exec_cmd` is async (no `& disown` needed).
  ```lua
  local autostart = {
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_ID XDG_SESSION_TYPE",
    "nm-applet --indicator",
    "phylax",
    "hyprctl setcursor Bibata-Modern-Classic 24",
    "awww-daemon",
    "wl-paste --watch cliphist store",
    "quickshell",
    "hypridle",
    "hyprpier daemon",
  }
  hl.on("hyprland.start", function()
    for _, cmd in ipairs(autostart) do hl.exec_cmd(cmd) end
  end)
  ```

- [x] **Keybinds** (L68–157) — four bind variants collapse to flags:

  | hyprlang | Lua flags |
  |---|---|
  | `bind`   | `nil` |
  | `binde`  | `{ repeating = true }` |
  | `bindm`  | `{ mouse = true }` |
  | `bindel` | `{ repeating = true, locked = true }` |

  Per-bind dispatcher mapping:
  - `bind = $mod, Space, global, quickshell:launcher` → `hl.bind("SUPER + Space", hl.dsp.global("quickshell:launcher"))`
  - `bind = $mod, Return, exec, $terminal` → `hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal))`
  - `bind = $mod, W, killactive,` → `hl.bind(mod .. " + W", hl.dsp.window.close())`
  - `bind = $mod, T, togglefloating,` → `hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }))` — verified shape from shipped reference `:262`
  - `bind = $mod, O, pin,` → `hl.bind(mod .. " + O", hl.dsp.window.pin())` — `pin()` exists in `HL.DspWindowNamespace`
  - `bind = $mod, P, pseudo,` → `hl.bind(mod .. " + P", hl.dsp.window.pseudo())`
  - `bind = $mod, J, togglesplit,` → `hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))` — verified shipped `:265`
  - `bind = $mod, F, fullscreen,` → `hl.bind(mod .. " + F", hl.dsp.window.fullscreen())`
  - `bind = $mod, L, global, quickshell:lock` → `hl.bind("SUPER + L", hl.dsp.global("quickshell:lock"))`
  - Workspace 1–10 + move-to-workspace: **collapse 20 lines into a loop** (§5).
  - movefocus / swapwindow direction: **collapse 8 lines into a loop** (§5).
  - `bindm = $mod, mouse:272, movewindow` → `hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })` — verified shipped `:290`
  - `bindm = $mod, mouse:273, resizewindow` → `hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })` — verified shipped `:291`
  - `bindel = , XF86MonBrightnessUp, exec, brightnessctl set +5%` → `hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true, locked = true })` — shipped reference `:298–299` uses bare keysym (no leading `" + "`) for empty-mod binds.
  - Screenshot binds (L148–150): consider extracting the inline `sh -c` to `~/.local/bin/screenshot` regardless (§5).

- [x] **`general` block** (L163–172) — `col` is a **nested table**, confirmed via shipped reference `:93–96` and stubs:
  ```lua
  hl.config({
    general = {
      gaps_in = 5,
      gaps_out = 10,
      border_size = 2,
      col = {
        active_border   = {< surface0 | hypr_rgba(0.93) >},
        inactive_border = {< surface1 | hypr_rgba(0.5) >},
      },
      resize_on_border = false,
      allow_tearing = false,
      layout = "dwindle",
    },
  })
  ```
  Gradient form (if needed): `{ colors = {"rgba(...)", "rgba(...)"}, angle = 45 }`.

- [x] **`decoration` block** (L177–196) — nested tables:
  ```lua
  hl.config({
    decoration = {
      rounding = 5,
      active_opacity = 1.0,
      inactive_opacity = 1.0,
      blur   = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
      shadow = { enabled = true, range = 4, render_power = 3,
                 color = {< crust | hypr_rgba(0.93) >} },
    },
  })
  ```

- [x] **`animations` block** (L201–226) — 5 beziers + 16 animations via `hl.curve` + `hl.animation`. Verified positional-name + table form via shipped reference `:136–161`.
  ```lua
  hl.curve("easeOutQuint",   { type = "bezier", points = {{0.23, 1},    {0.32, 1}} })
  hl.curve("easeInOutCubic", { type = "bezier", points = {{0.65, 0.05}, {0.36, 1}} })
  hl.curve("linear",         { type = "bezier", points = {{0, 0},       {1, 1}} })
  hl.curve("almostLinear",   { type = "bezier", points = {{0.5, 0.5},   {0.75, 1.0}} })
  hl.curve("quick",          { type = "bezier", points = {{0.15, 0},    {0.1, 1}} })

  hl.config({ animations = { enabled = true } })
  -- See §5 for the table-driven 16-animation loop.
  ```

- [x] **`dwindle` + `master`** (L231–238):
  ```lua
  hl.config({
    dwindle = { preserve_split = true },
    master  = { new_status     = "master" },
  })
  ```
  **❌ Drop `pseudotile`** — confirmed not present in reference §12 dwindle options. Pseudo state is per-window only (via `hl.dsp.window.pseudo()` dispatcher and `pseudo` window-rule effect). The current hyprlang config's `pseudotile = true` line had no effect by 0.55's grammar.

- [x] **`input` block** (L244–252):
  ```lua
  hl.config({
    input = {
      kb_layout = "us",
      follow_mouse = 1,
      sensitivity = 0,
      touchpad = { natural_scroll = true },
    },
  })
  ```

- [x] **Gesture** (L254) — `gesture = 3, horizontal, workspace`:
  ```lua
  hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
  ```

- [x] **`cursor` block** (L259–263) — only emitted on nvidia/prime hosts (the current hyprlang block is fully wrapped in a chezmoi Go conditional, with the non-nvidia branch contributing nothing). Note: `no_hardware_cursors` is `0/1/2` in 0.55, not bool.
  ```lua
  {{ if or (eq .graphics "nvidia") (eq .graphics "prime") -}}
  hl.config({ cursor = { no_hardware_cursors = 1 } })
  {{ end -}}
  ```

- [x] **`misc` block** (L268–273) — `vfr` **moved to `debug.vfr`** in 0.55 (stubs `:95, :968`; current hyprlang load errors with `<misc:vfr> does not exist`):
  ```lua
  hl.config({
    misc = {
      disable_hyprland_logo    = true,
      disable_splash_rendering = true,
      force_default_wallpaper  = -1,
    },
    debug = {
      vfr = true,
    },
  })
  ```

- [x] **Window rules** (L278–280) — `match` table + effect fields as siblings, confirmed via shipped reference `:317–356`:
  ```lua
  hl.window_rule({
    name           = "suppress-maximize",
    match          = { class = ".*" },
    suppress_event = "maximize",
  })
  hl.window_rule({
    name     = "fix-xwayland-drags",
    match    = { class = "^$", title = "^$", xwayland = true,
                 float = true, fullscreen = false, pin = false },
    no_focus = true,
  })
  hl.window_rule({
    name  = "phylax-pin",
    match = { class = "io.github.jakebgrant.phylax" },
    pin   = true,
  })
  ```
  `name` is optional but lets `:set_enabled(false)` toggle the rule at runtime.

### `dot_config/theme-templates/hypr/hyprlock.conf.theme` (59 lines)

- [ ] **Confirm hyprlock 0.55 release status** — independent release cadence; may stay hyprlang.
- [ ] If staying hyprlang: no changes.
- [ ] If moving to Lua: port `general`, `background`, `input-field`, two `label` blocks. Would need its own API reference.

### `dot_config/hypr/hypridle.conf` (19 lines)

- [ ] **Confirm hypridle 0.55 release status**, OR
- [ ] **Fold into `hyprland.lua`** via `hl.timer` + DPMS dispatcher (reference §15). Removes hypridle from autostart, simplifies the system. Pending confirmation that idle/lock events are exposed in 0.55 (not enumerated in reference §13).

### Generated artifacts

- [ ] Delete `dot_config/hypr/hyprland.conf.tmpl` (replaced by `hyprland.lua.tmpl`)
- [ ] Delete `dot_config/hypr/hyprlock.conf.tmpl` (or keep if hyprlock stays hyprlang)
- [ ] Regenerate via `theme-switch <current-theme>` after `.theme` files are ready

### `~/.config/hypr/monitors.lua` (out-of-repo, per-machine)

- [x] Decision: convert to `monitors.lua`, loaded from `hyprland.lua` via `pcall(require, "monitors")`.
- [x] Renamed `run_once_before_create-default-monitors-conf.sh` → `run_once_before_create-default-monitors-lua.sh`, body now emits:
  ```lua
  -- Default monitor configuration (auto-detect)
  hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
  ```
  `output = ""` is the documented catchall and is used directly in the shipped Hyprland default config.

---

## 4. Tier 2–5

### Tier 2 — Tooling
- [ ] `dot_local/bin/executable_theme-switch`:
  - L99 `filter_hypr_rgb` — output `rgb(hex)` likely still valid (reference §1 color types). **Verify** quoting: literal vs string.
  - L104 `filter_hypr_rgba` — same.
  - L364 `reload_hyprland()` → `hyprctl reload` still works (reference §20). ✓
  - L470 watched dir `~/.config/hypr` — unchanged. ✓
  - File extension changes — update output paths if §1 Option A.
- [ ] `run_once_before_create-default-monitors-conf.sh` — update emitted line per §3.
- [ ] `run_once_setup-greetd.sh.tmpl` — verify `start-hyprland` wrapper name unchanged.

### Tier 3 — Quickshell IPC consumers

Reference §20 confirms the `hyprctl dispatch '<name>'` *form* is preserved (shorthand for `eval 'hl.dispatch(...)'`). The risk is per-name resolution: §5 renames every dispatcher (`killactive → hl.dsp.window.close`, `togglefloating → hl.dsp.window.float`, `fullscreen → hl.dsp.window.fullscreen`, `pin → hl.dsp.window.pin`, `swapwindow → hl.dsp.window.swap`, `resizeactive → hl.dsp.window.resize`, `workspace → hl.dsp.focus({workspace})`, `togglespecialworkspace → hl.dsp.workspace.toggle_special`, `exit → hl.dsp.exit`, `focuswindow → hl.dsp.focus({window})`). Whether legacy string names still alias is **not** documented — assume they may not.

- [ ] **Smoke-test legacy strings first** on 0.55 before any rewrite. They might still work via a compat shim.
- [ ] `dot_config/quickshell/services/Launcher.qml` L33–57 — proactively rewrite the 20+ `hyprctl dispatch ...` strings to `hl.dsp.*` form. Example: `"hyprctl dispatch killactive"` → `"hyprctl dispatch 'hl.dsp.window.close()'"`. Affects: `killactive`, `togglefloating`, `fullscreen`, `pin`, `swapwindow {l|r|u|d}`, `resizeactive`, `workspace {e+1|e-1|previous}`, `togglespecialworkspace magic`, `global quickshell:*`, `exit`.
- [ ] `dot_config/quickshell/services/Launcher.qml`:254 — `Hyprland.dispatch("focuswindow address:" + result._data)` → `Hyprland.dispatch('hl.dsp.focus({ window = "address:' + result._data + '" })')` if alias breaks. **Note**: the address must be JS-interpolated by `+`, not Lua-concatenated by `..` — `Hyprland.dispatch(...)` ships the raw payload to Hyprland's Lua interpreter, where QML/JS variables don't exist.
- [ ] `dot_config/quickshell/modules/bar/popouts/PowerPopout.qml`:53 — switch `hyprctl dispatch exit` to `hyprshutdown` (reference §5 explicitly prefers this).
- [ ] `dot_config/quickshell/modules/bar/components/Workspaces.qml`:292 — `Services.Hypr.dispatch("workspace " + id)` → `Services.Hypr.dispatch('hl.dsp.focus({ workspace = ' + id + ' })')` if alias breaks.
- [ ] `dot_config/quickshell/services/Hypr.qml`:
  - L49 `hyprctl workspacerules -j` parse — subcommand preserved per §20; **verify JSON keys** (`rule.workspaceString`, `rule.monitor`) don't shift. Add defensive logging post-upgrade.
  - L72–93 `onRawEvent` subscribes to socket2 names (`workspace`, `workspacev2`, `focusedmon`, `activewindowv2`, `openwindow`, `closewindow`, `monitoraddedv2`, `configreloaded`, etc.) — these are **not** enumerated in reference §13 (which lists the Lua-API `hl.on` events). Socket2 wire-protocol compatibility is a known unknown; widen handler list if names drop.
- [ ] `dot_config/quickshell/services/Wallpaper.qml`:189 — `Hyprland.monitorFor(screens[i])` — Hyprland-side shape unchanged; Quickshell-side risk only.
- [ ] `dot_config/quickshell/services/LockScreen.qml`:34 — `config: "hyprlock"` — depends on hyprlock 0.55 status.
- [ ] `dot_config/quickshell/modules/drawers/Drawers.qml` / `shell.qml` — `Quickshell.Hyprland` imports.
- [ ] **Quickshell upstream tracking** — `Quickshell.Hyprland` is an external QML module. Compatibility with 0.55's IPC is gated on Quickshell shipping a 0.55-aware release. Treat as release-blocker; pin to a verified version before flipping the Hyprland upgrade live.

### Tier 4 — Docs
- [ ] `README.md` — title, format callout (L154), filter table (L172–173), file tree (L70)
- [ ] `CLAUDE.md` — only if filter names change

### Tier 5 — Incidental
- [ ] `dot_config/sddm-theme/Main.qml`:168 — cosmetic
- [ ] `dot_config/pane-fm/config.toml`:74 — commented-out example

---

## 5. Optimizations enabled by Lua

Doing these during the port is cheaper than as a follow-up.

- [x] **Workspace bind loop** — collapses 20 lines. Multi-mod is `+` between every mod, confirmed shipped reference `:278`.
  ```lua
  for digit = 0, 9 do
    local ws  = digit == 0 and 10 or digit
    local key = tostring(digit)
    hl.bind(mod .. " + " .. key,           hl.dsp.focus({ workspace = ws }))
    hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = ws }))
  end
  ```

- [x] **Directional bind loop** — collapses 8 focus+swap lines. Lowercase `left/right/up/down` keysyms are used in the shipped config `:268–271` for arrow keys.
  ```lua
  local dirs = { left = "l", right = "r", up = "u", down = "d" }
  for key, d in pairs(dirs) do
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ direction = d }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.swap({ direction = d }))
  end
  ```

- [x] **Animations as a data table** — drop 16 repetitive calls into a loop. **Field name is `bezier`** (not `curve`), confirmed via shipped reference `:145–161`. Full list from current `hyprland.conf.theme` L210–225:
  ```lua
  local anim = {
    { "global",        speed = 10 },
    { "border",        speed = 5.39, bezier = "easeOutQuint" },
    { "windows",       speed = 4.79, bezier = "easeOutQuint" },
    { "windowsIn",     speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" },
    { "windowsOut",    speed = 1.49, bezier = "linear",       style = "popin 87%" },
    { "fadeIn",        speed = 1.73, bezier = "almostLinear" },
    { "fadeOut",       speed = 1.46, bezier = "almostLinear" },
    { "fade",          speed = 3.03, bezier = "quick" },
    { "layers",        speed = 3.81, bezier = "easeOutQuint" },
    { "layersIn",      speed = 4,    bezier = "easeOutQuint", style = "fade" },
    { "layersOut",     speed = 1.5,  bezier = "linear",       style = "fade" },
    { "fadeLayersIn",  speed = 1.79, bezier = "almostLinear" },
    { "fadeLayersOut", speed = 1.39, bezier = "almostLinear" },
    { "workspaces",    speed = 1.94, bezier = "almostLinear", style = "fade" },
    { "workspacesIn",  speed = 1.21, bezier = "almostLinear", style = "fade" },
    { "workspacesOut", speed = 1.94, bezier = "almostLinear", style = "fade" },
  }
  for _, a in ipairs(anim) do
    hl.animation({ leaf = a[1], enabled = true, speed = a.speed,
                   bezier = a.bezier, style = a.style })
  end
  ```

- [x] **Autostart as a table** — already in §3 mapping.

- [ ] **Screenshot helper extraction** — move inline `sh -c` to `~/.local/bin/screenshot`. Independent of Lua migration but a good time.

- [x] **`mod` as a variable** — one-line Caps Lock / Hyper / Meta swap.

- [ ] **Fold hypridle into `hyprland.lua`** — pending §1 + idle-event confirmation.

- [ ] **Template-layer collapse** — §1 Option C. Biggest architectural win; separate from line-by-line port.

---

## 6. Execution order

1. ~~Spec gathering~~ ✓
2. **Architecture decisions** (§1)
3. **Pre-flight safety checks** (§8.1) — TTY/SSH fallback verified, backup config in place
4. **`hyprland.conf.theme` port** — section by section per §3 mappings, with §5 optimizations folded in. Use the per-section test loop in §8.2 and recommended subsystem order.
5. **Monitors decision + run-once script update**
6. **Hyprlock/hypridle ports** (parallelizable; gated on their own 0.55 status per §8.4)
7. **Checkpoint commit** before deleting legacy `.conf.tmpl` artifacts (§8.3)
8. **Regenerate `.tmpl` artifacts**, commit
9. **Quickshell IPC sweep** — only after Hyprland boots cleanly
10. **Docs pass** — README + CLAUDE.md
11. **Smoke test on second machine** (greetd path)

---

## 7. Open questions

Most resolved against `/usr/share/hypr/stubs/hl.meta.lua` and `/usr/share/hypr/hyprland.lua` on 2026-05-11. Remaining items are post-port verification.

### Resolved

- [x] **Empty-mod bind syntax** → bare keysym: `hl.bind("XF86MonBrightnessUp", ...)`. Shipped `:298–299`.
- [x] **Multi-modifier bind syntax** → `+` between every mod: `"SUPER + SHIFT + 1"`. Shipped `:278, :283`.
- [x] **Mouse-keysym + `{ mouse = true }` flag combo** → **both required**. Shipped `:290–291` uses keysym + flag together.
- [x] **`col.*` keys** → nested table: `col = { active_border = ..., inactive_border = ... }`. Shipped `:93–96`, stubs `:1027–1030`.
- [x] **`pin = true`** as window-rule effect → bare `true` (boolean) under the rule table. Shipped reference uses sibling-field pattern for effects.
- [x] **`dwindle.pseudotile`** → removed; pseudo is per-window only via `hl.dsp.window.pseudo()`.
- [x] **`misc.vfr`** → relocated to `debug.vfr` (boolean). Stubs `:95, :968`.
- [x] **`monitor` output catchall** → `output = ""` is valid. Shipped `:19`.
- [x] **Hyprlock / hypridle / hyprcursor** → independent cadence, stay hyprlang (hyprlock 0.9.5, hypridle 0.1.7, hyprcursor 0.1.13 installed; no hyprpaper, Quickshell handles wallpaper).
- [x] **Idle events** → not exposed in 0.55. `HL.EventName` has 27 entries, no idle. Keep external hypridle.
- [x] **`start-hyprland` wrapper** → still shipped by `hyprland 0.55.0-3` at `/usr/bin/start-hyprland`. Greetd path intact.

### Remaining (post-port verification)

- [ ] **`hyprctl dispatch <oldname>` string form alias**: does e.g. `killactive` still resolve, or only `hl.dsp.window.close()`? Affects Quickshell rewrite urgency. Test once we have a session running our `hyprland.lua`.
- [ ] **socket2 wire-protocol event names**: stubs enumerate Lua-API events (`window.open`, `workspace.active`, etc.); legacy socket2 names Quickshell subscribes to (`activewindowv2`, `openwindow`, `monitoraddedv2`, …) aren't in that list. Test by tailing the socket once 0.55 is live: `socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock -`.
- [ ] **`hyprctl <subcmd> -j` JSON shapes**: `workspacerules`, `monitors`, `clients`, `workspaces` — diff against current Quickshell parsing assumptions in `Hypr.qml`.
- [ ] **`Quickshell.Hyprland` module**: confirm upstream Quickshell release in use has 0.55 IPC support.

---

## 8. Safety, testing, rollback

### 8.1 Login-path safety (pre-flip checks)

A fundamental Lua syntax error in `hyprland.lua` aborts the compositor *before* binds load — the §21 emergency binds (`SUPER+Q/R/M`) won't fire because the binds-load stage isn't reached. The result at greetd: tuigreet respawns (login loop) or you land on a black screen with an error popup and no input.

Before flipping the migration live:

- [ ] `pacman -F start-hyprland && which start-hyprland` — confirm the greetd wrapper still ships with hyprland 0.55. If absent, patch `/etc/greetd/config.toml` and `run_once_setup-greetd.sh.tmpl` to invoke `Hyprland` directly or `uwsm start hyprland-uwsm.desktop`.
- [ ] **TTY fallback**: verify `Ctrl+Alt+F2` reaches a usable getty (`systemctl list-units --type=service | grep getty`).
- [ ] **SSH access from a second device** configured and tested — phone, laptop, anything. Lockout recovery path.
- [ ] **Backup hyprlang config**: keep `~/.config/hypr/hyprland.conf.bak` on disk pointing to the last-known-good rendered config. Test it via `HYPRLAND_CONFIG=~/.config/hypr/hyprland.conf.bak Hyprland`.
- [ ] **Dry-run parse** if 0.55 exposes one: `Hyprland -c ~/.config/hypr/hyprland.lua --verify-config` (or `--i-am-really-stupid` style flag). Check stub docs.

### 8.2 Per-section test loop

After porting each subsystem, before moving on:

1. Edit the `.theme` file (never the generated `.tmpl`).
2. `theme-switch <current-theme>` — regenerates `.tmpl`, applies chezmoi, runs `hyprctl reload`.
3. `hyprctl configerrors` — empty output means parse + type validation passed.
4. `hyprctl getoption <section.key> -j` — confirm the value landed (e.g. `general.gaps_in`, `decoration.rounding`). §14 note: scalar values may read back as canonicalized tables.
5. `hyprctl rollinglog -f` — tail the log; grep for `ERR`, `WARN`, `lua:`, `parse`.

**Recommended port order** (cheapest-to-verify first, riskiest last):

1. **Env vars + globals** — verify via `printenv` from a fresh terminal.
2. **`general` + `decoration`** — visually immediate (gaps, borders, rounding) and `hyprctl getoption`-checkable.
3. **`misc`, `input`, `cursor`** — `hyprctl getoption`; touchpad needs manual feel-test.
4. **Window/workspace/layer rules** — open a known target window, observe effect.
5. **`animations` + curves** — visual A/B.
6. **Keybinds** — interactive test; `hyprctl binds -j` lists them. Emergency binds protect you here.
7. **`hl.on`/autostart** — last, because it requires a full session restart (not just reload) to validate.

### 8.3 Rollback recipe

`main` still has the working hyprlang state. On the migration branch, follow a two-commit pattern to make rollback surgical:

1. **Add-only commit**: land `.lua.theme` + generated `.lua.tmpl` alongside (not replacing) the existing `.conf.tmpl`. Title: `Add Lua hyprland config alongside hyprlang`.
2. **Verify** boot + theme-switch end-to-end across at least one full week of daily use.
3. **Delete commit**: remove hyprlang artifacts. Title: `Remove hyprlang hyprland.conf artifacts`. This is the single revert target if 0.55+Lua misbehaves later.

Live rollback from a broken state:

```bash
git -C ~/.local/share/chezmoi checkout main
chezmoi apply ~/.config/hypr
rm -f ~/.config/hypr/hyprland.lua  # flush new artifact chezmoi won't delete
hyprctl reload  # or: drop to TTY and `Hyprland` to relaunch
```

`active.json` (palette source of truth) is format-agnostic — survives the rollback cleanly. The hyprlang `.theme` re-renders fine from the same JSON.

### 8.4 Hyprlock/hypridle decision framework

Evidence-gathering commands to run *today*:

```bash
pacman -Q hyprland hyprlock hypridle hyprpaper hyprcursor
pacman -Si hyprlock | grep -E '^Version|Depends'
hyprlock --version; hypridle --version
man hyprlock.conf 2>/dev/null | head -50   # section names reveal format
hyprctl descriptions -j | grep -i idle     # surfaces idle events if any
```

Then upstream release notes:
- https://github.com/hyprwm/hyprlock/releases — search for "lua" / "0.55"
- https://github.com/hyprwm/hypridle/releases — same

**Decision rule**: if upstream changelog mentions Lua, port them. Otherwise **keep external daemon, hyprlang config** as the conservative default.

If keeping external daemons:
- `hyprlock.conf.theme` stays Jinja-templated (unchanged).
- `hypridle.conf` stays static.
- Autostart in `hyprland.lua` keeps `"hypridle"` and lock-via-`quickshell:lock`.
- §3 hyprlock/hypridle checkboxes become "no-op, file format unchanged."

If folding hypridle into `hyprland.lua` (only viable with reference-side support):
- Reference §13 doesn't yet enumerate an idle event. `hl.timer` (§15) handles *delayed* DPMS but doesn't detect seat-idle.
- `hl.dsp.dpms()` and `hl.dsp.force_idle()` are *outputs* (§5), not inputs.
- Without an idle event, pure-Lua replacement requires polling — worse than the daemon. Skip until upstream adds an idle event.
