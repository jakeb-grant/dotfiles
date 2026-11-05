# What Strand offers a shell author

A catalogue for choosing features, read from Strand at `main` a18cfdeb (2026-10-31).
Included only if ticked in `docs/features.md` or documented in `docs/reference/`, with
code checked where the docs were unclear. Nothing here was run.

- **[Strand]** marks what a typical shell toolkit would not give you.
- Paths are relative to the Strand repo. "From the code" means I read it and found no test
  or doc saying so.
- Language rule of thumb: one typed language, no imports, every prop a live expression, and
  a shell is `.strand` files in a directory.

## Contents

1. Surfaces and windows
2. Keyboard (the gaps are in 2.8)
3. Motion
4. Services
5. Theming
6. Tools
7. Performance
8. Escape hatches
9. Known limits, including running beside another shell (9.1) and partial features (9.3)

---

## 1. Surfaces and windows

All in `docs/reference/elements.md` and `site/concepts/surfaces.md`.

| Surface | What it is | Default |
| --- | --- | --- |
| `bar` | Strip on an edge; `exclusive:` reserves space | Every monitor, `screen` in scope |
| `panel` | Launcher, dashboard, stack | Focused monitor, `top` layer; `screens: all` gives one per monitor |
| `osd` | Passing display | Focused monitor, `overlay` layer, click-through |
| `popup` | Anchored to its parent element; nests (submenus) | Below its element, 6 px away; mounts only while open |
| `window` | Real `xdg_toplevel`: tiles, floats, shows in task bars | Compositor sizes and focuses it; app id `strand-<Name>` |
| `lock` | `ext-session-lock` lock screen | Every monitor, one shared password |

Shared by every surface:

- `open:` (two-way `<->` lets Escape, click-away and focus loss close it), `anchor`, `layer`,
  `keyboard`, `screens`, `attach`, `scrim`, `inhibit_idle`, `on show`, `on hide`.
- **[Strand]** A bar or panel instance is keyed by the monitor's make, model and description.
  State survives a 30 s unplug and a move to another port (`surfaces.md`).
- **[Strand]** `attach: top` grows a panel or popup out of an edge with concave fillets.
- **[Strand]** `scrim:` dims behind a popup or panel with a single-pixel buffer, at no cost.
- `popup` extras: `trigger: hover` with `delay` and `grace`, `anchor: pointer` for context
  menus, `on dismiss`.
- `window` extras: `title`, `app_id`, `decorations`, `w.focused/maximized/fullscreen/tiled/decorated`,
  `w.move()`, `resize(edge)`, `minimize()`, `maximize()`, `fullscreen()`, `close()`.
  `screens`, `layer`, `anchor`, `margin`, `keyboard`, `attach` and `scrim` are load errors on one.
- `lock` **[Strand]**: a fault shows a built-in password field rather than the desktop; edits
  wait for the unlock; a fingerprint module works through PAM's conversation (`auth.message`).
- The same language also writes `polkit` (a password dialog in your own panel) and `greetd`
  (a login screen). See section 4.

Layout and widgets, briefly:

- Containers: `row`, `col` (both with `wrap`), `stack`, `grid { columns }`, `scroll` (`axis`, `snap`),
  `list` (virtualised, `snap`), `split` with `start/center/end`, `pages`, `spacer`, `place: absolute`.
- Widgets: `text`, `icon`, `image`, `button`, `slider`, `meter`, `arc`, `graph`, `segmented`, `input`,
  `tooltip`, `thumbnail`, `spectrum`, `svg`, `lottie`, `canvas`, `shader`.
- `when self.width < 300 { … }` is a container query with hysteresis.
- `drag:` and `on drop` handle drag and drop, including files, apps and text from other programs.

---

## 2. Keyboard

The short version: list-and-input panels (launchers, menus, pickers) are well served. Anything
else, such as grids, buttons, sliders and scrolling content, needs hand-written key handling,
and two things cannot be done at all: moving a `list`'s selection from code, and scrolling from code.

The routing below is `Router::key` in `crates/strand-render/src/input.rs:2249-2441`.

### 2.1 Global keys: how a key reaches the shell

Strand grabs no keys. The compositor keeps them and runs a `strand` command
(`site/start/running.md`). That covers everything global.

| Command | Does | Limits |
| --- | --- | --- |
| `strand toggle launcher.open` | Flips an exported `bool` state | Exported top-level values only |
| `strand set theme.look mocha` | Writes an exported `state`, a settings field, a token, or an `rw` service field | Value is text, read by the target's type |
| `strand set audio.sink.volume +5%` | A signed number on a service field is a step, never below 0 | Steps are for service fields |
| `strand call media.play_pause` | Calls a service-level action | See below |
| `strand get launcher.open` | Reads an export, setting or token | Service fields are not read |
| D-Bus `Toggle`, `Set`, `Call`, `Get` on `io.github.jakeb_grant.Strand` | The same commands | The name may change before 1.0 |

- `strand call` takes `<service>.<action>` only (`crates/strand/src/ipc/call.rs`). Useful targets:
  `workspaces.focus 4`, `media.next`, `keyboard.next_layout`, `session.lock`, `session.suspend`,
  `notifications.clear`, `clipboard.clear`, `network.scan`, and a config's own `from dbus` actions.
- **`strand call` cannot reach** item actions (`win.close()`, `ws.focus()`, `n.dismiss()`), `fn`s,
  or a top-level declared `action`. `auth`, `polkit` and `greetd` are refused.
- A global key cannot press a key inside a panel or move a selection. The workable pattern (not
  documented as an idiom, built from documented parts) is an exported state plus a handler:
  `export state next = false; on change next { … }`, bound to `strand toggle shell.next`.
- `wm.mode` shows the compositor's Hyprland submap or sway mode, so compositor-side leader keys
  can drive a mode indicator. Tested on the matrix (`modes_and_layouts_follow_the_compositor`).
- Locked keys are the compositor's flag (`{ locked = true }` on Hyprland; `running.md`).

### 2.2 `keyboard:` modes

| Value | Meaning | Note |
| --- | --- | --- |
| `none` | No keys (the default) | Panels you only look at |
| `on_demand` | Keys when clicked | Not reliable for keyboard-first opening; the doc says "when you click it" |
| `exclusive` | Keys while shown | What a launcher or menu needs |

- A `window` gets keys while the compositor focuses it. A `lock` always has them.
- A bar is a surface, so it takes `keyboard:` too. Layer surfaces reapply their keyboard mode when
  config changes (`crates/strand-surface/src/manager/layer.rs:9,354`), so
  `keyboard: nav_mode ? exclusive : none` looks possible, but that is from the code: no doc or
  test covers a changing value. Try it before designing around it.
- `keyboard.alt/ctrl/shift/logo` are readable only while a Strand surface holds the keyboard. An
  Alt+Tab switcher commits on `on change keyboard.alt` (`docs/guide/level-4.md`).

### 2.3 Which node has focus

- A surface that receives the keyboard focuses its first `focus: true` node, else the surface root
  (`input.rs:1680-1682`).
- **Only `input` and `list` can hold focus.** `focus:` exists on those two elements alone
  (`elements.md`), and Tab and clicks pick only them (`input.rs:2749`, `input.rs:1985`).
- **Moving focus from code:** yes, but only one way. `focus: cond` on an `input` or `list` moves
  focus there when it turns true while the surface has the keyboard (`focus: mode == search`). There
  is no `node.focus()`. Test: `crates/strand-compiler/tests/interaction.rs::focus_moves_when_focus_turns_true`.
- A surface closing lets its focus go; reopening refocuses and returns a `nav` list to its first row
  (`input.rs:1683-1696`).

### 2.4 Tab and Escape

- **Tab / Shift+Tab** cycle a surface's `input`s and `list`s in tree order, wrapping, skipping
  `opacity: 0` and exiting nodes (`input.rs:2738`; test `tab_moves_focus_between_inputs`).
- **Tab is lost to any `on key` around the focused node**, including one on the surface root
  (`hears_keys`, `input.rs:2767`). That handler then gets Tab and must move focus with `focus:`
  itself (test `tab_is_left_to_an_on_key_handler`). Ctrl, Alt or Super with Tab also go to handlers.
- **Escape** writes `open` false on a surface whose `open` is two-way, and fires `on dismiss` on a
  popup (`input.rs:2274`). A `window` ignores it.
- **Escape cannot be intercepted on a two-way surface.** A handler hears it, then the surface closes
  anyway. For "Escape goes back a level", use a one-way `open: x` and handle Escape in `on key`; you
  then also give up automatic close on click-away and focus loss.

### 2.5 Keys inside a panel: `on key`

- `on key(k)` exists on every element. `k` has `name`, `text`, `ctrl`, `shift`, `alt`, `logo`
  (`docs/reference/types.md`). Key repeat is handled by Strand (`crates/strand-surface/src/manager/seat.rs`).
- **A key can be handled inside a panel:** yes. It goes to the focused node and bubbles outward. With
  nothing focusable, the root hears it, so `panel P { keyboard: exclusive; on key(k) { … } }` works
  (the root is the default focus, `input.rs:2256`; `on key` on a `lock` root is in
  `crates/strand/src/run/tests.rs`).
- **It only hears keys on the focused node's path to the root.** A handler on a list row, or a
  sibling of the focused node, hears nothing.
- **There is no "handled" signal.** The handler runs and the default still happens
  (`input.rs:2266` queues the event, then the defaults follow). `j` in a focused `input` types a j,
  arrows still move the list, Return still activates. Only Tab is yielded to a handler.
- `propagate()` passes an event to the next enclosing handler. It is not a default-suppressor.
- No key-release event, no repeat flag, no key-binding table or chord syntax: `on key` is an `if` chain.
- `on key` is documented only in the reference; no guide or how-to page teaches it.

### 2.6 `list`, `nav:`, `selected`, `on activate`

| Key | On a focused `list` | On an `input` with `nav: results` |
| --- | --- | --- |
| Up, Down | Moves selection | Moves the list's selection |
| Page Up, Page Down | Moves by a view of rows | Same |
| Home, End | First, last row | Caret; Ctrl+Home and Ctrl+End go to the list's ends |
| Return, KP_Enter | Fires `on activate` on the selected row | Same |
| Right | Opens a popup the row holds (submenu) | Caret |
| Left | Closes a popup opened from a popup | Caret |

- The selected row scrolls into view by the least amount, including rows beyond the mounted window
  of a virtualised list (test `nav_selects_rows_beyond_the_mounted_window`).
- `when selected { … }` styles the row. `selected` is true only for a row of a `list`.
- `on activate` fires on click, on Return on a selected row, or on Return in an `input` with no `nav:`.
- `nav:` follows a list that mounts later or remounts in a page (`nav_follows_a_list_that_remounts`),
  so tabs of lists work.
- A row can report upward: `on change self.selected { if self.selected { current = h } }` (from the
  docs on `Node`, not shown in an example), for a preview pane that follows the selection.
- **`list` is vertical only:** no axis prop, and only Up and Down move it.

### 2.7 Other widgets by key

- `input`: typing, caret, selection, clipboard shortcuts; `type: password`. Good.
- `button`, `slider`, `segmented`, `scroll`, `grid`, `pages`, `box`: **no key handling at all**.
  `Router::key` handles only lists and inputs. Drive them with `on key` writing state.
- `popup` takes the keyboard (an `xdg_popup` grab) only when a click or key handler opened it within
  500 ms. **One opened by a timer, hover or `strand toggle` gets no keys** (`spec.md` 5.1). For
  something opened from a global key, use a `panel { keyboard: exclusive }`.
- Tray menus work by key once opened that way: `list { focus: true }` in a popup, Right and Left for
  submenus (`router_hooks_pointer_drag_and_submenu_keys`).

### 2.8 Gaps for a fully keyboard-driven shell

Each was checked against the schema and `input.rs`. Workarounds are my reading, not run.

| Need | Status | Workaround |
| --- | --- | --- |
| Navigate a `grid` with arrows | **Not built in** | Own `cursor` state, `on key` on an enclosing focused node or root, `when` to style. Needs your own row and column maths (`xs.index_of` exists; `for` gives no index) |
| Move a `list`'s selection from code (Ctrl+N, Ctrl+P, j, k) | **Impossible** | `selected` is read-only and has no setter. Replace it with your own cursor, which then loses scroll-into-view |
| Scroll from code or by key | **Impossible** | `scroll` has only `axis` and `snap`, and no position to read or write. Use `list`, or a clipped box with a spring on an inner `y:` (no virtualisation) |
| Focus a button, tile, or arbitrary node | **Not possible** | Treat the row as a `list`, or use a cursor state on the surface |
| Horizontal `list` (dock, workspace strip, tabs) | **Not built in** | `row` plus cursor state and `on key` |
| Suppress a default (typing, Return, Escape) | **Not possible** except Tab | One-way `open`; don't focus an `input` while in a command mode (`focus: mode == search`) |
| Keep Tab while using a root `on key` | **Conflict** | Handle Tab yourself and move focus with `focus:` conditions |
| Key-release events | **Not available** | Modifiers only, through `keyboard.alt` and friends |
| A keymap or chord syntax | **Not available** | `if`/`match` over `k.name`; or compositor submaps with `wm.mode` |
| Global keys handled by Strand itself | **By design, no** | Compositor binds, `strand` commands |
| Send a key or action into an open panel from outside | **No** | Exported state and `on change` |
| Activate a slider or button by key | **No built-in** | `on key` writes the value or runs the action |
| Move the keyboard between Strand surfaces | **No API** | Opening an `exclusive` surface takes it; which one wins is the compositor's call |
| Open a `popup` with keys from `strand toggle` | **No keys in it** | Use a panel |
| Keyboard tests on Hyprland | **Unproven** | Key routing is tested on a fake seat and sway; I found no key delivery in `compositor_matrix.rs`, which covers stores, modes and layouts |

---

## 3. Motion

Backed by `site/concepts/motion.md`, `docs/spec.md` 6.6, `docs/design.md` "Motion and visual effects",
and the "Effects catalogue" line in `features.md`.

**Core**

- Every visual prop springs by default: `$motion.spatial` for movement and size, `$motion.effects` for
  colour and opacity. You do not opt in.
- `~` per prop: `~ $motion.bouncy`, `~ spring(500, 0.5)`, `~ 200ms`, `~ ease(out_back, 300ms)`,
  `~ bezier(…)`, `~ instant`.
- **[Strand]** The curve is read with the value, so a prop can come and go at different speeds:
  `opacity: open ? 1 : 0 ~ (open ? 160ms : 1s)`.
- Retargeting mid-flight keeps velocity, so interrupted motion never jolts (`retargeting_keeps_velocity`).
- `reduced_motion` from the portal snaps everything and stops loops.

**Coming and going**

- `enter { … }` and `exit { … }` on surfaces, `if` branches, `for` copies, list rows, pages. Presets:
  `fade`, `slidefade`, `popin(0.8)`, `slide(top)`.
- Opening cascades; closing is one unit: only the removed root's `exit` plays.
- `stagger: 30ms` on a container, counting only children that have an `enter`.
- FLIP: siblings glide when a node is added, removed or reordered, by key.
- **[Strand]** Surface fades, scales and small moves go to the compositor (alpha modifier, viewporter,
  layer margins) where possible, with no repaint.

**Size**

- **[Strand]** Growth springs: a content-sized panel, OSD or popup springs its own box when content
  changes, keeping the anchored edge. `size: auto ~ $motion.bouncy` picks the curve.
- **[Strand]** Kept size: such a panel keeps its largest size so the compositor never animates a
  resize, across sessions (`design.md`; decisions.md kept-size).
- `site/how-to/island.md` builds a morphing island from one box this way.

**Shared and morphing**

- **[Strand]** `morph: "media"` on two nodes makes one grow into the other, across surfaces on one
  output (`a_shared_morph_crosses_surfaces_on_one_output`, `crates/strand-render/tests/effects.rs:2808`).
  Not to or from a `window`, which has no known screen position (`spec.md` 5.1).
- `shape: cookie` → `burst`: named shapes morph by spring (13 shapes in `types.md`).
- `transition: wipe(left) | disc | dissolve | pixelate` masks on `if`, `pages` and image swaps.
- `pages current: x` gives directional page transitions; hidden pages unmount and stop what they read.

**Driven motion**

- `keyframes shake { … }` plus `play shake` in a handler, for a shake on a wrong entry.
- Time signals `t`, `wave(1.6s)`, `noise(x)`: only that node repaints, only while visible.
- **[Strand]** `self.pointer` and `id.box` are live values, so a highlight can travel to a selected
  row's box on a spring: `x: item.box.x - row.box.x ~ $motion.spatial` (`types.md`, `Node`).
- `letters { … }` per-letter animation, `roll: true` rolling digits, `jelly`, `parallax`, `tilt`.
- `particles`, `effect lightning | sparks | shimmer | ripple | aurora`, `merge` (goo), `spectrum`.
- `lottie`, animated GIF, APNG, WebP, `svg` with bindable `#layers`, your own `shader "x.wgsl"`.
- 8 bundled GPU effects with CPU fallbacks: `filter: bloom()`, `crt()`, `chromatic()`, `wobble()`,
  `backdrop: glass()`, large particles, 3D tilt, aurora.
- Paint: gradients, animated gradient borders (only the ring repaints), `glow`, `rim`, `inner_shadow`,
  `grain`, `blend`, `mask`, `filter`, squircle corners.

---

## 4. Services

Each starts when first read and stops 5 s after the last visible reader. Full fields are in
`docs/reference/services.md` and `types.md`. **[Strand]** Many scan or sample only while something
visible reads them (`access_points`, `nearby`, `cpu`), so a closed menu costs nothing.

| Service | Data | Actions and writes |
| --- | --- | --- |
| `audio` | `sink`, `source`, `sinks`, `sources`, `streams` (per-app), `levels()`, `meters` (PipeWire) | `volume`, `muted` writable on devices and streams; `make_default()` |
| `network` | `connected`, `ssid`, `strength`, `kind`, `address`, `rx`, `tx`, `access_points`, `connections` | `wifi` writable; `disconnect()`, `scan()`, `ap.connect()`, `connect_with(pw)`, `conn.up()`, `down()`; `on network.failed` |
| `bluetooth` | `powered`, `devices`, `nearby`, `scanning`, `available`; per device `battery`, `connected` | `powered` writable; `connect()`, `disconnect()`, `pair()`, `forget()`; `on bluetooth.failed` |
| `notifications` | `popups`, `all` (newest 1,000, kept across restarts), `count`, hints, `progress`, `can_reply` | `dnd`, `remember` writable; `clear()`; per item `expire()`, `dismiss()`, `activate()`, `reply()`, `a.invoke()`; `on notifications.received` |
| `tray` | `items` with `icon`, `title`, `status`, `tooltip`, `menu.items` (DBusMenu) | `activate()`, `secondary()`, `scroll()`, `menu.open()`, `close()`, entry `activate()` |
| `media` | `title`, `artist`, `album`, `art` (remote art fetched), `position`, `elapsed`, `length`, `can_*`, `players` | `position` writable (seeks); `play_pause()`, `next()`, `previous()`, `p.select()` |
| `workspaces` | `all`, `focused`, `configured`, `on(screen)`, `slots(screen)` | `focus(int or name)`, `ws.focus()` |
| `windows` | `all`, `focused`; `title`, `app_id`, `icon`, `rect`, `workspace`, states, `app` | `focus()`, `close()`, `minimize()`, `maximize()`, `fullscreen()`, `move_to(ws)` |
| `thumbnail` (element) | Live window (`thumbnail w`, at most 15 frames/s) or a still of a screen | `blank` state. Not a service, listed for completeness |
| `clipboard` | `text`, `holds_image`, `history` (100 entries within 64 MiB, kept), `available` | `copy()`, `clear()`, `e.copy()`, `e.remove()`; secrets never read |
| `idle` | `after(300s)`, `timeouts`, `available` | Hold off with a surface's `inhibit_idle` |
| `auth` | `busy`, `failed`, `message`, `prompt` | `submit(pw)` for the `lock` |
| `session` | `can_suspend`, `can_hibernate`, `can_reboot`, `can_power_off` | `suspend()`, `hibernate()`, `reboot()`, `power_off()`, `lock()`, `log_out()`; `on session.lock_requested`, `on session.failed` |
| `battery` | `percent`, `charging`, `time_left`, `power`, `icon`, `devices` (peripherals) | `history(span)` from UPower, reaching back before the shell started |
| `brightness` | `level`, `available` | `level` writable through logind, no root |
| `keyboard` | `caps_lock`, `num_lock`, `layout`, `layout_code`, `layouts`, modifiers | `next_layout()`, `set_layout(i)` |
| `screens` | `all`, `focused`; `scale`, `width`, `height` | None |
| `outputs` | Every monitor on or off: modes, place, scale, transform, adaptive sync | `apply([OutputChange])`, `test(…)`; events. A display settings page |
| `apps` | `all`, with `actions`, `categories` | `search(q)` (fuzzy + frecency, ranges to highlight), `launch()`, `a.launch()` |
| `system` | `dark`, `accent`, `contrast`, `reduced_motion`, `hostname`, `kernel`, `uptime` | `replay` writable |
| `wm` | `name`, `mode` | `on wm.config_reloaded` |
| `video` | `streams` with `app`, `source`: camera or screencast indicator | None |
| `polkit` **[Strand]** | `request`, `waiting`, `busy`, `failed`, `available`, `error` | `respond(pw)`, `cancel()`, `choose(user)`: your own agent dialog |
| `greetd` **[Strand]** | `user`, `prompt`, `echo`, `message`, `busy`, `failed`, `error` | `login()`, `submit()`, `start([cmd])`, `cancel()`: your own login screen |
| `clock` | `now`, `today`, `format("%H:%M")` | Wakes only as often as the pattern changes |
| `calendar` | `days(month)` | None |
| `cpu` | `usage`, `cores`, `temperature` | Sampled while shown |
| `memory` | `usage`, `used`, `total`, `available`, `free`, `cached`, `swap_*` | Sampled while shown |
| `disk` | `usage`, `used`, `total`, `free`, `all` | Read every 10 s while shown |

Not a service:

- **Recording:** no service. `video.streams` and `audio.streams` show what is recording. Run a recorder
  with a declared action, and `rec.running`, `rec.stop()`, `rec.error` track it (section 8).
- **Screenshots:** `thumbnail screen` shows a still but saves nothing. Use `grim` through an action.
- **Keyboard-global state:** nothing tells Strand which modifiers are held while it lacks focus.

Other notable details:

- **[Strand]** A `graph` shows its history as soon as it mounts, because the history lives with the data.
- `network` falls back to iwd where NetworkManager does not run.
- Compositor data: Hyprland, sway, niri over their own IPC, with standard protocols otherwise.

---

## 5. Theming

`site/concepts/theming.md`, `spec.md` 9, `site/how-to/wallpaper-theme.md`.

**Model**

- Three tiers: palette roles (Material 3's, plus 13 hue roles), base tokens (`$space.2`, `$radius.lg`,
  `$font.ui`, `$motion.spatial`), and component tokens (`$Toast.radius`).
- **[Strand]** Tokens are live graph values. Derived tokens stay derived (`$fg.muted: $fg.alpha(0.65)`)
  and are exact at every frame of a swap.
- `set { $surface: … }` overrides tokens for a subtree. `override` is required to redefine, so a
  misspelt token is an error.

**Live switching**

- **[Strand]** A swap springs palette roots in OKLab, with nothing rebuilt: an open launcher keeps its
  query. Text keeps at least 3:1 contrast throughout, and where a light-dark swap makes that impossible,
  the surface crossfades from a snapshot.
- `segmented { options: Look; value: <-> theme.look }` is an in-shell switcher in one line.
- Follows the desktop live: `system.dark`, `system.accent`, `system.contrast` from the portal.
- The last palette is persisted, so boot does not flash default colours.

**Palette sources**

- `material(seed: #7aa2f7, variant: tonal_spot, dark:, contrast:)`, with 9 variants.
- `material(image: path, …)`: wallpaper-derived, quantised off-thread, cached by content. It is `Async`,
  so write `?? material(seed: …)` as the fallback. The old palette holds until the new one is ready.
- `import("catppuccin:mocha")`, `import("base16:scheme.yaml")`, `base24:`, `matugen:`, `w3c:`. File
  forms resolve against the config or `~/` (`crates/strand-theme/src/import.rs:78`).
- A source's own colours stay readable as `$palette.mauve`, `$palette.base0d`, with `??` for a fallback.

**Driving Strand from an outside theme switcher**, any of:

1. `strand set theme.look mocha`, for an enum state you declared.
2. `strand set prefs.wallpaper ~/Pictures/x.jpg`, or edit the settings TOML. Writes land in the file.
3. Replace the wallpaper file or swap its symlink. Both path and target are watched, so re-theming is
   automatic (`the_theme_follows_the_portal_the_wallpaper_and_strand_set`).
4. Have the switcher rewrite an imported file: `import("matugen:~/.cache/colors.json")`. Imported files
   are read again on change (`crates/strand-compiler/tests/theme.rs::imported_files_are_read_again_when_they_change`).
5. `strand set '$accent' '#ff5555'`: a token overlay, kept across restarts until `strand clear '$accent'`.
6. Change the portal's dark or accent setting.

**Driving other programs from Strand**

- `file "~/.cache/strand/colors.css" { template: "colors.css.tmpl"; run: ["reload-colors"] }` rewrites a
  file atomically on every swap and runs a command 200 ms later (`run` needs `permit exec`).
- `strand export json | base24 | --template <file>`, for scripts. Strand ships no per-app themes.

---

## 6. Tools

**Live reload** (`site/concepts/live-reload.md`)

- **[Strand]** A save is a state change, not a restart. Props patch and animate from where they are, and
  state stays: an open launcher keeps its query.
- **[Strand]** A broken save is held back and the last good version keeps running, including across a
  restart. Problems standing for 250 ms open a clickable overlay that opens your editor at the line.
- A runtime fault freezes only its component, outlined in red.
- `@reset` resets one cell. `strand reload --hard` drops non-persisted state. `strand watch [--json]`
  streams reloads, faults and notices.
- Handles vim-style rename saves and symlinks, by watching directories.

**`strand check`, `strand fmt`, `strand new`**

- `strand check [dir | file]`: type-checks without running. Errors carry file, line, caret and did-you-mean.
- **[Strand]** It lists every declared action's command, checks D-Bus services against the real object's
  introspection, and warns where a typed password flows anywhere unsafe (`check::secret_flow`).
- `strand fmt [--check]`. `strand new [dir]` writes a starter bar.

**Editor** (`site/tools/editor.md`)

- `strand-dev lsp`: diagnostics, completion, hover from the schemas, go to definition, rename across files,
  code actions (did-you-mean, missing key, extract component), formatting.
- A tree-sitter grammar, with setup for Helix and Neovim. No editor plugin ships.

**Inspector** (`site/tools/inspector.md`)

- **[Strand]** `strand-dev inspect`: pick an element on any monitor, then see identity, layout, token
  provenance, and kept-state badges. `f` turns on repaint flashing.
- **[Strand]** `set width 240` and `token accent #7aa2f7` write a literal back to your source file.

**Reporting and replay** (`site/tools/reporting.md`)

- `strand report` describes the running shell: globals, monitors, PSS, GPU status, each surface's backend
  and frame times.
- **[Strand]** `strand report the clock jumped` saves the last minute or so of input and service changes
  from a 256 KB in-memory ring, plus state, frames and the config. Typed text is never kept.
- **[Strand]** `strand replay` re-runs it in a sandbox and opens a viewer with a scrubbable timeline, saying
  VERIFIED or DRIFTED. It uses a stand-in compositor, so compositor-side behaviour will not show.
- **[Strand]** Clips for an agent: select a time span and elements, then copy or save a zip, or
  `strand replay clip --from -3.2s --node '#card'`.
- `strand-eval live`: a sandbox window on a virtual clock that plays, slows and steps a config (`features.md`).

**Running two at once:** `STRAND_SOCKET=… STRAND_STATE_DIR=… strand run dir` runs a second shell beside the
first (`spec.md` 13).

---

## 7. Performance

From `docs/benchmarks.md`, `design.md` and `site/concepts/performance.md`. GPU figures are the owner's laptop
(Intel PTL, Mesa ANV). All are measurements unless called a gate.

**Memory**

| What | Figure |
| --- | --- |
| Two-monitor bar, no GPU (PSS) | 41.9 to 42.0 MB; target 42 MiB, gate 48 MiB |
| Full shell, launcher open, no GPU (PSS) | 83 to 87 MB, 161 apps; over its 76 MiB target, gate 128 MiB |
| Same bar, GPU device warm, Intel (PSS) | About 65 MB |
| GPU device's own memory (not in PSS, real RAM on integrated) | 126 MiB (129,116 KiB); +10 MiB while animating; 0 with no render node |
| So a bar's real footprint on this laptop | About 190 MB (65 + 126; my sum) |
| Replay ring | 256 KB, on by default |

**Idle**

- The design bar over 10 s between minute ticks: no thread wakes, no frame (`the_design_bar_on_the_real_services_keeps_the_budget`).
- A larger config on four outputs: 8.1 to 8.7 wakes/s, all in `strand-services`, whether or not its surfaces
  are on the GPU (gpu-idle-wakes). A promoted surface draws one extra frame when the minute turns.
- A clock tick repaints at most 2,000 px² (`a_minute_tick_repaints_at_most_2000_px2`).

**Animation frames**, p95 ms on Intel, 1× and 1.5× scale, budget 8.33 ms (120 Hz):

| Scene | 1× | 1.5× |
| --- | --- | --- |
| Panel opening | 4.0 to 5.5 | 5.2 to 6.3 |
| Shared-element morph | 2.1 to 2.3 | 2.7 to 3.6 |
| List scroll | 2.3 to 2.4 | 2.9 to 3.1 |
| FLIP reorder | 2.5 to 2.9 | 3.0 to 3.3 |
| Stagger | 3.5 to 3.9 | 4.7 to 5.2 |
| Palette spring | 2.2 to 2.4 | 2.8 to 3.1 |
| Crossfade | 4.7 to 5.1 | 5.5 to 6.4 |
| Backdrop blur | 4.0 to 4.5 | 6.2 to 6.8 |
| Liquid glass | 2.6 to 3.5 | 3.1 to 3.9 |

- No scene's p95 is over budget on Intel. Without a GPU, several are: backdrop blur 40 to 44 ms at 1.5×,
  morph-card 14, crossfade 14.
- Liquid glass at 1× stays on the CPU in practice, since its frames are too small to promote: 11 to 12 ms.

**First showings** (perf-cold, 120 Hz, scale 1.5)

- Launcher open: at most one late frame, while it is nearly transparent.
- First theme swap of a session: drops two or three frames. Marked not fixed.

**Gates CI's `timing` job holds:** save to frame on screen 35 ms (token) and 50 ms (markup) at p95; theme swap
work under 5 ms (median).

**Other**

- Each output paces itself: 120 Hz and 60 Hz outputs run at their own rates (gpu-pace).
- Hyprland 0.57 nested, one animating panel: 61 frames/s at 60 Hz, 123 at 120 Hz; Hyprland 306 wakes/s, Strand 233 at
  60 Hz (gpu-mailbox, debug builds, headless monitors).
- A waveform on four monitors: 10 to 13% of one core (wave-cost).
- I found no figure for `strand toggle` latency from key to first frame. The launcher timings run frame to frame, so they leave out the command.

---

## 8. Escape hatches

`site/how-to/dbus-and-actions.md`, `spec.md` 5.6 and 5.7, `docs/guide/plugins.md`.

**D-Bus**

- `service ppd from dbus system "net.hadess.PowerProfiles" { profile: text rw = ActiveProfile; action hold(…) = HoldProfile }`.
- **[Strand]** Checked against the object's live introspection, so a misspelt method is a load error
  with did-you-mean. Writable fields also work with `<->` and `strand set`.

**Declared actions (running programs)**

- `permit exec "hyprctl", "wf-recorder"` lists allowed programs; an action using any other is a load error.
- `action dispatch(ws: int) ["hyprctl", "dispatch", "workspace", ws]`: no shell, each parameter one argument.
- `dispatch(3)` in a handler runs it detached. Actions are callable from handlers only, not `strand call`.
- **[Strand]** `action calc(q: text) -> text ["qalc", "-t", q]`: output is the typed value. It is an `Async`
  that reruns as arguments change and ends the superseded run; 10 s limit, 1 MiB of output.
- **[Strand]** `rec.running`, `rec.started`, `rec.error`, `rec.stop()`: a recorder toggle with no pid file.
  `stop()` sends SIGINT, then SIGTERM, then SIGKILL, so files are finished.

**Files and commands as data**

- `service x from file path { fields }`: re-read on change, typed.
- `service walls from dir "~/Pictures/walls" { files: [File] }`: live directory listing (wallpaper picker).
- `service x from listen ["cmd"] { … }`: lines a command prints, with `on x.line(doc)` for each one.
- `service x from poll ["cmd"] every 5s { … }`: at most every 100 ms for a command.
- `state prefs from "prefs.toml" { … }`: typed, two-way settings file, with comments preserved
  through `toml_edit`.
- `persist` keeps any state across restarts. `file { … }` writes files out.

**Drawing and code**

- `canvas { draw: (c) => … }`: shapes, paths, text. Redraws when its inputs change, never per frame.
- `shader "x.wgsl" { u_speed: 0.4 }`: checked with naga, hot-reloaded. Draws nothing without a GPU.
- Plugins: Rust services through `strand`'s library. **Git-only and marked unstable** (`spec.md` 5.6).
- No embedded JS or other second language, by decision (`design.md`, open questions).

**Being driven:** `strand get/set/toggle/call`, D-Bus, and `strand watch --json`. Note `watch` carries
reloads, faults and notices, not state changes. An external script reading live values should poll
`strand get` or have Strand write a `file`.

---

## 9. Known limits

### 9.1 Running beside another shell

Applies to running next to Quickshell or anything else that holds these names.

**`org.freedesktop.Notifications`** (`crates/strand-services/src/notifications.rs`):

- **Nothing happens unless the config reads `notifications`.** Only services a config reads start
  (`crates/strand/src/services/mod.rs:1571`, `only_the_services_a_config_reads_start`). A config that
  never reads it never asks for the name, so the other daemon keeps working.
- **If it does read it and the name is taken:** Strand asks with `DoNotQueue` (`:827-829`) and gets `Exists`
  (`:832-833`). It does not start a second server, does not queue, and does not try to replace the owner.
- It raises a notice naming the owner's pid and command with how to stop it (`:844`, text at `:715-758`).
  The notice appears on Strand's **error overlay** and in `strand watch` (`features.md:166`). The overlay's close
  button dismisses it until the list changes (`site/help/troubleshooting.md`).
- It then waits on `NameOwnerChanged`, with no polling and no retry (`:849`, `name_freed` at `:1035-1073`), and
  **takes the name the moment the owner lets go**, resolving the notice (`:829-830`, `:860`).
- While waiting: `popups` stays empty and `all` holds only restored history. Writes to `dnd` and `remember` work
  (`:1058-1068`). Other actions, such as `clear()`, are dropped (`:1069`).
- **The config cannot detect this:** the service has no `available` field. Only the overlay and `watch` show it.
- **If Strand got the name first:** the request has no `AllowReplacement` flag, so another server cannot replace
  it through the bus. It owns the name until its service stops.
- **The name is let go when the service stops,** 5 s after its last visible reader (`spec.md` 8.1). A toasts
  panel's `open:` holds it even while closed (`a_closed_surface_holds_what_its_open_binding_reads`), but a config
  reading notifications only inside a closed popup would drop the name (my inference from those two rules).
- Test: `crates/strand-services/tests/notifications.rs:660`, `another_notification_server_fails_clearly`.

**`org.kde.StatusNotifierWatcher`** (`crates/strand-services/src/tray.rs`):

- **No conflict. It coexists silently.** Strand asks for the name with `DoNotQueue` (`:1240-1244`). If it is taken
  it removes its own watcher object (`:1245-1249`), registers as a host with the session's watcher (`:1263-1273`), and
  reads its items (`:1274-1287`). No notice is raised; a refused registration only logs a warning (`:1272`).
- Its host name is unique per process, `org.kde.StatusNotifierHost-<pid>-<n>` (`:739-754`), so it does not clash.
- **If the other watcher leaves,** Strand restarts its session loop and becomes the watcher, or registers with the
  new one (`:1342-1349`).
- **If Strand is the watcher,** another host can use it: `RegisterStatusNotifierHost` is accepted and does nothing
  (`:674`), and `IsStatusNotifierHostRegistered` is always true (`:682`). Its items go if Strand's tray service stops.
- Tests: `crates/strand-services/tests/tray.rs:647` (`the_tray_hosts_for_the_sessions_watcher`), `:255`
  (`the_tray_is_the_watcher_when_there_is_none`).

**Others**

- `polkit`: leaves a session's existing agent alone, with `polkit.available` false and `polkit.error` saying why.
- `lock`: the session-lock protocol allows one locker, so whichever shell locks first holds it.
- A second Strand needs its own `STRAND_SOCKET` and `STRAND_STATE_DIR`, or it runs with no IPC.
- Bars from two shells: reserved zones are the compositor's to stack.

### 9.2 Compositors

- **Tested on every push:** sway, Hyprland, niri, labwc, by `crates/strand/tests/compositor_matrix.rs` in an Arch
  container (`site/start/install.md`). It covers the `workspaces`, `windows` and `wm` stores, window actions, `win.rect`,
  `wm.mode` and layouts. The design bar runs under `strand run` on sway, niri and Hyprland, not labwc.
- **Everything else runs on one compositor:** the rest of the suite is on headless sway 1.9.
- **Required:** `wl_compositor`, `wl_shm`, `zwlr_layer_shell_v1`. `strand run` stops without them.
  `xdg_wm_base` for popups and windows.
- **Out of scope:** COSMIC, with `ext-foreign-toplevel-list` read-only as its last source (`features.md:158`).
- **Hyprland specifically:**
  - Blur needs `strand compositor-rules` pasted into its config; Strand never applies them. Support for the standard
    background-effect protocol is listed as unverified (`design.md`, risks). sway and labwc have no blur, so a tint shows.
  - A floating window's `rect` is stale after a move, since Hyprland does not report it.
  - Presenting tests use Hyprland nested in headless labwc: monitors are not DRM, and sleep is simulated
    (`benchmarks.md`, gpu-mailbox). A freeze found there was fixed on 2026-10-31, the commit under this catalogue, so it is new.
- `thumbnail w` needs `ext-image-copy-capture` of toplevels. The matrix allows only niri to skip that test
  (`compositor_matrix.rs:2789-2800`), so it should hold on Hyprland.
- Workspace-by-name creation: Hyprland and sway. Layout switching and `screens.focused`: Hyprland, sway, niri. On other
  compositors `focused` is the first monitor.

### 9.3 Partial: present, with pieces missing

| Feature | Works | Missing |
| --- | --- | --- |
| Springs | Every solid paint and geometry prop | `features.md:123` lists `mark_color`, gradients and some effect props as snapping. That note dates from M2 and is partly stale (glow springs: `a_lone_radius_glow_springs_in_the_nodes_colour`). Test any you depend on |
| Shared `morph` | Across surfaces on one output | Not to or from a `window`. I found no claim of morphs across outputs |
| `network` over iwd | Wi-Fi state, joining known networks | `connections` empty; `up()` and `down()` fail; `frequency` may be null |
| `network` enterprise Wi-Fi | Joins through a saved profile | Refused without one |
| `bluetooth` | First adapter; pairing most devices | No PIN or passkey prompt; a device insisting on one fails unless a system agent runs |
| Restored notifications | Listed in `all` after restart | No buttons; `activate()` only dismisses |
| `media` | Transport, seek, multiple players | No player volume, shuffle or loop fields. Reach for `from dbus` |
| `keyboard` | Layouts; modifiers while focused | Modifiers false without focus; layouts only on Hyprland, sway, niri |
| `clipboard` | Text and image history | `copy()` is text only; needs data control |
| `win.rect` | Hyprland, sway, floating niri | None for tiled niri or standard protocols |
| GPU promotion | Large animations promote at once | Small slow animations stay on the CPU (deferred, decisions.md perf); no way back to the CPU once promoted, so later frames redraw the whole surface |
| Cold first frames | Launcher open is fine | First theme swap drops 2 or 3 frames; crossfade's first frame at 1.5× is 13 to 34 ms |

### 9.4 Cannot do

- Everything in 2.8.
- Left out of v1 by design: video wallpapers, Rive, wallpaper subject separation, mesh-warp minimise effects (`design.md`).
- Screen capture for blur: never, blur is declared to the compositor.
- A `shader` node draws nothing without a Vulkan device.
- Global key grabs, or knowing held modifiers while unfocused.
- `strand get` on a service field; `strand call` on items or declared actions (2.1).
- Multiple `lock`s per config.

### 9.5 Unproven or still moving

- **Version 0.1.0:** tagged 2026-10-30. The compatibility policy in `spec.md` 14 applies from 1.x. The D-Bus name may
  change before 1.0, and plugins are unstable.
- **Lock screen:** tested only in a VM with injected faults, by rule never on a live session. Your first real lock is
  the first on your hardware. Keep a TTY route out.
- **Long sessions and real daily use:** the benchmarks are short runs. The newest GPU presenting work is a day old.
- **Docs on `on key`:** only the generated reference covers it, so its behaviour in section 2 comes from reading the
  code, and I ran nothing.
