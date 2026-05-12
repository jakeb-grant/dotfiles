# Floating Island Redesign

Branch: `floating-bar-popouts`

## Status

- ✅ Phase 0 — Theme tokens and palette seeding
- ✅ Phase 1 — Float the bar
- ✅ Phase 2 — Delete the frame
- ✅ Phase 3 — Rebuild popouts as floating islands
- ✅ Inter-phase cleanup pass
- ✅ Phase 4 — Bar-item active state
- ✅ Phase 5 — Float notifications and launcher
- ✅ Phase 6 — Cleanup and DEVGUIDE update

## Vision

Sexy minimalism. Sleek like an iPhone floating island.

The current shell wraps the screen in a themed frame and seams popouts into the bar with painted concave curves. It looks polished but feels architectural — you can sense the chrome. The redesign throws away the frame, detaches the bar from the screen edge, and makes every shell surface (bar, popouts, notifications, launcher) a self-contained floating object grounded by a soft drop shadow.

The result the user should feel:

- **More screen.** Three edges of the display are returned. Only the bar still has presence, and it floats with breathing room.
- **Objects, not chrome.** Each shell surface is a discrete island. They don't share edges, paint seams, or imply a containing frame. They're things sitting in space.
- **Bloom on demand.** Popouts spring into existence from the bar item you interacted with, with a spring-overshoot scale animation. The source item visibly activates while its popout is open — that's the new "connection" cue replacing the geometric seam.
- **Everything else preserved.** Theming, color animations, gradients, hover behavior, content QMLs, the satisfying overshoot on appearance — all untouched.

## Visual Language

Every floating island shares this language:

- **Heavy rounding.** Small popouts approach pill shape; larger surfaces use a deep rounded rect (~20–24px). No square corners anywhere.
- **Mantle fill.** Background stays `Theme.mantle` (consistent with current). No internal surface chrome — the rounded shadow *is* the chrome.
- **Soft drop shadow.** Each island has a subtle outward shadow (`crust` at low opacity, ~24px blur, ~4px Y offset). Grounds it without making it heavy.
- **Spring on appear.** `OutBack` overshoot, ~400ms (already in use for per-popout transitions). Same easing curves Theme.qml already defines.
- **Origin from source.** Popouts scale up from the source bar item's center via `Scale.origin.x/y`. This replaces the geometric seam.
- **Active source state.** When a popout is open, its source bar item gets an accent-tinted fill and a soft glow halo. This is the only persistent indicator of which popout owns the screen.
- **Bridgeable gap.** The empty space between bar and open popout is hover-bridged — moving the cursor across it does not close the popout. Implementation via an invisible `Item` per popout (see Phase 3).

Notifications and launcher use the same language — rounded floating panels with drop shadow, no concave-into-frame curves.

## Architecture Changes

Line references are against current `main` as of branch creation.

### Removed

The bar-seam machinery and frame chrome go away entirely. No backwards-compat shims — cut clean.

**`modules/bar/popouts/PopoutWrapper.qml`** (~527 lines → ~150)

- `nonAnimWidth` / `nonAnimHeight` (L66–71): the clip-along-bar-axis trick. Gone.
- `targetX` / `targetY` / `flushTop` / `flushBottom` / `flushLeft` / `flushRight` (L74–93): slide-and-clamp positioning. Gone.
- `popoutX` / `popoutY` / `popoutWidth` / `popoutHeight` exports (L96–101): existed only so `Drawers.qml` could paint the seam Shape. Gone.
- `animCurve` / `animDuration` / `reshapeDuration` swap dance and the dual `Behavior on implicitWidth/Height` (L132–225): axis-aware reshape choreography. Gone.
- `_checkRetracted` (L144–155): retraction-completion cleanup. Gone — bloom-out finishes itself.

**`modules/drawers/Drawers.qml`** (~785 lines → ~450)

- `Border` instantiation (L137–139). Gone.
- `popoutBgSide` Shape (L142–229, 88 lines of `PathArc`/`PathLine`). Gone.
- `popoutBgTop` Shape (L232–329, 98 lines). Gone.
- `notifBg` Shape (L333–422, ~90 lines of concave-into-bezel curves). Replaced by a rounded `Rectangle` per the new language.
- `launcherBg` Shape (L425–519, ~95 lines). Replaced by a rounded `Rectangle`.
- `compositedShapes` wrapper (L132–520) **and `innerGlow` block (L533–575)**: the wrapper existed only as a `MultiEffect` mask source; `innerGlow` was its consumer. Both die together — each island gets its own shadow effect directly.
- `mask` Region math (L48–93): `borderThickness` subtraction disappears; mask becomes the union of axis-aligned **bounding** rects for each visible island (Wayland `Region` is strictly rectangular — rounded corners falling through to the underlying window is harmless and arguably correct for click-outside-to-close).

**`modules/drawers/Border.qml`** — file deleted. The frame is gone.

**Cross-file `borderThickness` call sites** (replacement semantics, not pure deletion)

- `Exclusions.qml` — 9 refs at L15, L16, L22, L23, L29, L30, L36, L37, L45. The three frame-edge `PanelWindow`s exist solely to claim the frame's exclusive zone. Delete them entirely; the surviving bar exclusion gets new zone math (Phase 1).
- `PopoutWrapper.qml` — 10 refs at L76, L81, L82, L87, L92, L93, L116, L118, L123, L125. All inside blocks already marked for removal, but listed here so a final grep returns clean.
- `Drawers.qml` survivors outside the deleted Shape blocks — L52 (mask), L337 (`notifBg.bt`), L429 (`launcherBg.bt`), L581 (`launcherPanel.y`), L594/L597–598 (`notifColumn.x/y`). Phase 5 rewrites notif/launcher positions; Phase 2 simplifies the mask.

**Palette JSON cleanup** (11 files)

- `_quickshell.bezelIntensity` in: `catppuccin-mocha.json:48`, `catppuccin-macchiato.json:48`, `catppuccin-frappe.json:48`, `catppuccin-latte.json:54`, `everforest.json:49`, `everforest-light.json:50`, `rose-pine.json:49`, `rose-pine-dawn.json:50`, `rose-pine-moon.json:49`, `nord.json:49`, `active.json:45` (regenerated by `theme-switch`).
- `_quickshell.frameShadow` in: `everforest-light.json:49`, `rose-pine-dawn.json:49`.

Both done in Phase 0 alongside `islandShadowColor` seeding.

**Theme tokens to remove or repurpose**

- `bezelIntensity`, `borderThickness`, `borderRounding` (Theme.qml L141–143) — no frame to size. Remove.
- `frameShadow` semantic role (L104) **and its `Behavior on frameShadow` (L112)** — superseded by per-island shadow tokens. Remove.

**`frameGlow*` disposition** — tokens at Theme.qml L152–158 are **kept**, but their current consumer (`innerGlow` block at Drawers.qml L533–575) is deleted in Phase 2. They get repurposed as the bar-item active-halo primitive in Phase 4.

### Kept unchanged

- All popout *content* QMLs (`SystemPopout`, `VolumePopout`, `WifiPopout`, etc.) — they live inside the new container, untouched.
- The per-popout `Popout` Loader component (PopoutWrapper.qml L452–526) with `opacity 0→1` + `scale 0.8→1` `OutBack` overshoot. This was always the actual bloom; it just stops being wrapped in a clip container. Same for the tray-menu Repeater (L275–384).
- `Theme.qml` color system (palette + semantic roles + accents), color animations on theme switch, `frameGlow*` properties (repurposed as the bar-item active halo).
- `Anim.qml`, all animation curves (MD3 spec), `popoutRounding`, all spacing/size tokens not listed above.
- `Exclusions.qml` — bar still claims exclusive zone, just at a different geometry.
- `LockScreen` (orthogonal, lives in its own `WlSessionLock`).

### Added

**`modules/bar/BarWrapper.qml`** — bar becomes floating chrome:

- Margin from screen edge (`Theme.barMargin`).
- All four corners rounded (`Theme.barRounding`).
- Drop shadow via `MultiEffect`.
- Background stays `Theme.mantle`.

**`modules/bar/popouts/PopoutWrapper.qml`** — gutted and rebuilt as a floating-island spawner:

- One rounded `Rectangle` container per active popout, sized to content, positioned adjacent to the bar with `Theme.islandGap` margin.
- Bloom pivot uses `transform: Scale { origin.x; origin.y }`, **not** `transformOrigin` (which is an enum — `Item.Center`, etc. — not a coordinate). `Scale.origin.x/y` accepts pivots outside the item's bounds. Set origin once at transition start via `PropertyAction`; never animate origin alongside `xScale/yScale` (moving pivot mid-bloom looks wrong).
- Origin coords resolve to `Services.Popout.centerX/centerY` minus the container's `x/y`. Container position must be computed from cached `_lastContentWidth/Height`, **not** live `implicitWidth/Height`, to avoid reintroducing the binding cycle documented at PopoutWrapper.qml:17–19.
- Spring-overshoot `xScale/yScale` + opacity on enter, scale-down + fade on exit (port the existing per-popout transition up to the container level).
- Drop shadow via `MultiEffect` with `autoPaddingEnabled: true` and `layer.smooth: true` — without padding the blur clips at the bounding box; without smooth, scaled shadow edges alias during bloom.
- **Invisible hover bridge** — a transparent `Item` with its own `HoverHandler` spans from the active bar item's edge to the container's near edge, keeping `Services.Popout.popoutHovered = true` while the cursor crosses the `islandGap`. Bridge geometry recomputes per popout based on source-item position.

**Bar-item active state** — new visual treatment in `BarContent.qml` and bar components (`StatusIcons.qml`, `Tray.qml`, `Workspaces.qml`):

- Each bar item reads `Services.Popout.currentName` and is "active" when its popout is open.
- Active state: accent-tinted fill background (`accent` at ~15% alpha) + soft halo via `frameGlow` rendered as a localized blur, not as a frame paint.
- Color animations on the fill (reuses existing `ColorAnimation` Theme durations).

**New theme tokens** (added to `Theme.qml`):

```qml
// ── Floating Island ──
readonly property int barMargin: _qs.barMargin ?? 8
readonly property int barRounding: _qs.barRounding ?? roundingNormal   // 16
readonly property int islandRounding: _qs.islandRounding ?? 22
readonly property int islandGap: _qs.islandGap ?? 8        // distance bar→popout
readonly property int islandShadowBlur: _qs.islandShadowBlur ?? 24
readonly property real islandShadowOpacity: _qs.islandShadowOpacity ?? 0.35
readonly property int islandShadowY: _qs.islandShadowY ?? 4
property color islandShadowColor: _qs.islandShadowColor ?? crust

// ── Bar Item Active State ──
property color barItemActiveBg: _qs.barItemActiveBg ?? Qt.rgba(accent.r, accent.g, accent.b, 0.15)
readonly property int barItemActiveHaloBlur: _qs.barItemActiveHaloBlur ?? 12
readonly property real barItemActiveHaloOpacity: _qs.barItemActiveHaloOpacity ?? 0.5
```

All overridable per palette via `_quickshell` block, same pattern as existing tokens.

## Implementation Phases

Each phase is a clean commit. Verify visually after each before moving on.

### Phase 0 — Theme tokens and palette seeding ✅

`Theme.qml`:
- Add the new tokens listed above.
- Remove `bezelIntensity`, `borderThickness`, `borderRounding`, `frameShadow`, and the `Behavior on frameShadow` at L112.
- Keep `frameGlow*` tokens — they get repurposed in Phase 4.

Palette JSON updates (same pass):
- Remove all `_quickshell.bezelIntensity` entries (11 palette JSONs listed above).
- Remove all `_quickshell.frameShadow` entries (2 light-variant JSONs).
- Seed `_quickshell.islandShadowColor` overrides on light variants — `catppuccin-latte.json`, `everforest-light.json`, `rose-pine-dawn.json` — set to `overlay0` (or equivalent dark-on-light neutral). Mirrors the existing pattern documented in DEVGUIDE L307: a `crust`-colored shadow on a light background renders as a *highlight* and breaks the floating illusion.
- Dark variants accept the `crust` default — no override needed.

`Theme.qml` color `Behavior`s — every color property in `Theme.qml` has a matching `Behavior on X { ColorAnimation { duration: _tt; easing.type: Easing.OutCubic } }` so theme switches animate. Add `Behavior` blocks for the new color tokens: `islandShadowColor` and `barItemActiveBg`. Mirror the existing patterns at L51–62 (neutral scale) and L80–93 (accents).

**Acceptance:** shell still loads and renders identically to current `main` (nothing references the new tokens yet). Light variants don't yet show the shadow, but palette overrides are seeded for Phase 1 to consume. Theme switches still animate colors smoothly across all properties (regression check).

**Deviation:** plan called for outright removal of `frameShadow`/`bezelIntensity`/`borderThickness`/`borderRounding` in this phase. In practice, those tokens are still referenced by call sites that don't migrate until Phases 1–2 (Border, Exclusions, mask, popout positioning). Removing the tokens here would break the shell. Compromise: tokens kept and marked DEPRECATED in `Theme.qml`, default `bezelIntensity` dropped 2→1 so visuals match the (now-stripped) palette overrides. Same for the 2 light-variant `frameShadow` overrides — kept until Phase 2 deletes the frame, then re-removed in Phase 6 cleanup. Net: Phase 0 stayed a true visual no-op.

### Phase 1 — Float the bar ✅

`BarWrapper.qml`: margin from edge, four rounded corners, drop shadow via `MultiEffect` (`autoPaddingEnabled: true`, `layer.smooth: true`).

`Exclusions.qml` rework:
- Delete the three frame-edge `PanelWindow`s (top/bottom/non-bar-side).
- Bar exclusion: `exclusiveZone = Theme.barMargin + bar.implicitWidth` (side mode; height for top mode). Keeps Hyprland tiled windows out of the moat so the bar floats over emptiness, not over a window edge.

**Fullscreen handling** — extend `services/Hypr.qml` (already wires up Hyprland event subscriptions) to expose a `hasFullscreen` property. `BarWrapper.qml` and any open popout fade to `opacity: 0` with `OutCubic` 400ms when fullscreen is active, fade back when it clears.

At this point the frame still exists — bar floats *inside* the frame. Looks weird but isolates the change.

**Acceptance:** bar visibly floats with margin, exclusion math leaves the moat clear of tiled windows, popouts still work (seamed to bar inside frame), entering Hyprland fullscreen cleanly fades the bar out and exiting fades it back.

**Deviations:**
- Margin positioning. Initial attempt used `AnchorChanges` inside States to add margins — they didn't take effect (bar stayed flush against the screen edge). State-based `anchors.<edge>Margin` PropertyChanges proved unreliable. Fixed by setting direct `x`/`y`/`width`/`height` bindings on the bar instance in `Drawers.qml` instead of relying on anchors. Cleanest path.
- Frame hidden, not deleted. With the frame's exclusion zones gone but the `Border` paint still rendered, the transitional state was visually disconnected (frame painted with apps tiling underneath it). Set `Border.visible = false` in Phase 1; actual file deletion happened in Phase 2.
- `Hypr.qml::hasFullscreen` added then removed. Initially added the convenience property as planned. In practice `Drawers.qml` wires per-monitor fullscreen detection inline (more correct for multi-monitor), so the global convenience went unused and was removed in the cleanup pass.

### Phase 2 — Delete the frame ✅

- Delete `modules/drawers/Border.qml`.
- `Drawers.qml`: strip `Border` instantiation (L137–139), the `innerGlow` block (L533–575), the mask `borderThickness` math (L48–93), and the frame-edge `borderThickness` refs at L52, L337, L429, L581, L594, L597–598. Leave the `borderThickness` refs inside the Shape blocks — those blocks die in Phase 3.
- Mask simplification: after stripping, `mask: Region` collapses to a single axis-aligned bounding rect for the bar's expanded footprint (bar + margin). Popout, notification, and launcher rects get added back in Phases 3 and 5 as those features come online. **Without this stepwise rebuild, input passthrough breaks** — clicks fall through floating islands.
- `Exclusions.qml`: any surviving `borderThickness` refs disappear with the frame-edge `PanelWindow`s deleted in Phase 1.

Three edges of the screen return. Popouts still use the old Shape painting and now visibly fail — the concave curves are anchored to a frame that no longer exists. Expected. Phase 3 fixes it.

**Acceptance:** frame is gone, three screen edges free, bar floats correctly. No `Border.qml` file, no `innerGlow` rendering. Popouts may render with broken seams — fine for this phase.

**Deviations:**
- Mask simplification went bolder than planned. Rather than stepwise rebuild (bar-rect this phase, popout-rect Phase 3, notif/launcher Phase 5), kept the original boolean-passthrough design: when nothing is active, passthrough zone is everything except a `barMargin*2 + barWidth` reserve strip; when anything is active, mask collapses to 0×0 so the full window catches input. Works correctly for click-outside-to-close without needing per-island rectangles. Phase 5 plan note about adding notif/launcher rects is unnecessary.
- `notifBg`/`launcherBg` Shapes kept (still drawn) until Phase 5 replaces them. Their `borderThickness` references and concave-into-frame curves persist for now — visible but unobtrusive.

### Phase 3 — Rebuild popouts as floating islands ✅

Gut `PopoutWrapper.qml`. Rewrite as a single rounded floating container that:

1. Reads `Services.Popout.currentName`, `Services.Popout.activeScreen`, `Services.Popout.centerX/centerY`.
2. Sizes to current popout content via the imperative `_updateCurrentPopout` / `_lastContentWidth/Height` pattern (preserves the binding-cycle fix at L17–19). Origin coords downstream **must** read from these cached values, not live `implicitWidth/Height`.
3. Positions adjacent to bar with `islandGap`, clamped inside screen with `barMargin` of padding from every edge.
4. Bloom pivot via `transform: Scale` with `origin.x: Services.Popout.centerX - container.x`, `origin.y: Services.Popout.centerY - container.y`. `Scale.origin` accepts pivots outside item bounds; `transformOrigin` does not — it's an enum. Origin set via `PropertyAction` at transition start; never animated.
5. Bloom in: `xScale/yScale 0.85 → 1.0` with `OutBack` overshoot 1.2, opacity `0 → 1`, ~400ms.
6. Bloom out: `xScale/yScale 1.0 → 0.92`, opacity `1 → 0`, ~200ms `InCubic`.
7. Renders `Theme.mantle` rounded rect with drop shadow via `MultiEffect` (`autoPaddingEnabled: true`, `layer.smooth: true`).
8. **Invisible hover bridge** — transparent `Item` from active bar item's edge to container's near edge with its own `HoverHandler` that keeps `Services.Popout.popoutHovered = true` while crossed. Bridge geometry recomputes per popout from source-item position.
9. **Popout-to-popout switch (cross-fade)** — when `currentName` changes while a popout is already open, fire two transitions: outgoing popout fades + scales down (`InCubic`, 200ms) while incoming blooms from its new source via the standard bloom-in. Two `Loader`s briefly active; cleanup the outgoing one on completion. Picked over a single morphing container because re-anchoring `Scale.origin` mid-flight looks wrong, and "each popout is its own island appearing/disappearing" matches the design thesis.

Also:
- Delete `popoutBgSide`, `popoutBgTop`, all Shape painting from `Drawers.qml`.
- **Remove the per-`trayWrapper` opacity/scale transition** at PopoutWrapper.qml:323–382. Container now owns the bloom; leaving the per-item transition would double-animate.
- **Update `mask: Region` in `Drawers.qml`** — add the popout container's bounding rect (including hover bridge) to the passthrough mask while active. Without this, clicks fall through the floating island.

**Acceptance:** clicking a bar item blooms a clean floating popout from that item's position. Cursor traversal across the `islandGap` does not close the popout. Hover-out (outside the bridge + island) closes it. Switching between popouts cross-fades cleanly from old to new. Tray menus bloom from the specific tray icon clicked. Clicks on the open popout register on the popout, not the underlying window. No frame, no seam, no painted curves, no double-animation.

**Deviations:**
- Cross-fade abandoned for **switch gate + snap content**. Original plan called for "two `Loader`s briefly active" cross-fading old → new on switch. In practice this produced visible ghosting on rapid hover-panning across bar items, even with size morph + staggered fades + shortened durations. Final design: a global `switching` flag flips true on every `currentName` change between two non-empty popouts and stays true until 80 ms of stillness; while true, *every* popout's `shouldBeActive` is forced false. Content opacity snaps (no `Behavior on opacity`) — the container handles all visible motion (`transform: Scale` for bloom, `Behavior on x/y/width/height` for position+size morph). Net: zero in-transit content rendering during fast pans. Single deliberate switch: 80 ms gate + 100 ms container morph + content snap-in. Initial open and close paths bypass the gate.
- `popoutX/Y/Width/Height` exports never wired to a mask cut (see Phase 2 deviation note). Exports were dead code by end of phase and removed in cleanup pass.
- Line target: plan estimated ~150 lines, landed ~300. Extra weight comes from: imperative `_updateCurrentPopout` + Connections (binding-loop fix preserved), tray-Loader inline state machinery, hover-bridge geometry, switch gate plumbing, and the aggregate hover state (`panelHovered || bridgeHovered`).
- Per-popout `Popout` Loader transitions changed from "scale + opacity OutBack" to PropertyAction-driven "load → 16 ms layout pause → opacity snap to 1" (in) and "opacity snap to 0 → 50 ms grace → unload" (out). Scale + spring lives on the container only.

### Inter-phase cleanup pass ✅

After Phase 3, audited for dead code and bypassed machinery:
- Deleted `popoutX/Y/Width/Height` exports from `PopoutWrapper.qml` (no consumers); rewrote hover-bridge to use `targetX/Y` + `panelWidth/Height` directly.
- Deleted unused `hasFullscreen` from `Hypr.qml` (per-monitor logic lives inline in `Drawers.qml`).
- Stripped `BarWrapper.qml` of dead `contentWidth`/`contentHeight` properties and the state/transition machinery that animated `implicitWidth/Height` — bypassed since `Drawers.qml` sets `width/height` directly. Inlined `implicitWidth/Height` bindings.
- Skipped indent fix on `notifBg`/`launcherBg` (Phase 2 unwrap left them one level too deep) — they get deleted in Phase 5, no point re-indenting.

### Phase 4 — Bar-item active state ✅

Add the active-state visual treatment to bar components. Each clickable bar item:

- Tracks whether its popout name is current.
- Renders an accent-tinted rounded backdrop behind the icon when active.
- Renders a soft halo (`MultiEffect` blur) under that backdrop.
- Animates fill and halo opacity on transition.

This is where the rice gets its character back after Phase 3 leaves it feeling disconnected.

**Acceptance:** the source item visibly "owns" the open popout. Eye can trace which icon spawned which island. Halo + fill animate smoothly.

**Deviations**

- Implemented as a reusable `modules/bar/components/BarItemHalo.qml` component rather than inlining at each call site. One-line wire-up per item: `BarItemHalo { name: "<popoutName>" }`. The component owns its own active-state binding via `Services.Popout.currentName === name`.
- Single Rectangle drives both the fill (`barItemActiveBg`) and the halo (its `layer.effect: MultiEffect` shadow tinted with `accent`). Opacity is the only animated property — the colored backdrop and the colored halo fade together as one unit.
- Used `animDurationFast` (150 ms) with `Easing.OutCubic` — matches the popout's own fade so the halo doesn't linger after the island disappears.
- `radius: roundingFull` clamps to half the smaller dimension at render time → produces a stadium on tall items (clock-side) and a circle on square icons. Pill-language consistent with the workspace active indicator.
- `layer.enabled: visible` (not `true`) so the offscreen surface is only allocated during fade-in/visible/fade-out. 11 of 12 instances are layer-off at rest.
- 12 call sites: 6 in `BarContent.qml` (archLogo/clock/power × side+top modes), 5 in `StatusIcons.qml` (volume/brightness/wifi/bluetooth/battery), 1 dynamic in `TrayOverflow.qml` delegate (`name: "traymenu" + index`).
- `TrayOverflow.qml` lost its old `hover.containsMouse ? surface1 : transparent` pill — the halo now handles both hover-feedback and active-state in one element, matching how `BarContent` items work. The icon's scale grow still provides the immediate hover signal.
- Hot-reload caveat noted: when adding a *new* QML type into an already-watched folder, Quickshell may fail the first reload before its directory scan picks up the new file. A second reload (touch `shell.qml`) clears it. Not a code bug.

### Phase 5 — Float notifications and launcher ✅

- `notifBg` Shape → rounded `Rectangle` with island shadow (`MultiEffect`, `autoPaddingEnabled: true`). Same for `launcherBg`.
- Adjust positions so they sit with `barMargin`-equivalent breathing room from the screen edges instead of butting against a frame that's gone.
- Notification cards: keep the current stack and stagger animation. The container becomes one floating island (option 1 from the earlier discussion).
- Launcher: rounded rect, centered horizontally, floats above the bottom edge. Preserve the existing width morph when switching to wallpaper-picker mode via a `Behavior on width` on the new `Rectangle`.
- **Update `mask: Region` in `Drawers.qml`** — add the notification column rect (when visible) and the launcher panel rect (when visible) to the passthrough mask. Without this, clicks pass through to the underlying window.

**Acceptance:** notifications and launcher land as floating islands consistent with popouts. Stagger entrance still works. Click-outside-to-close still works. Clicks on a notification card or launcher item register correctly (input mask correct).

**Deviations**

- The mask region cuts didn't need changes — they already bound to `notifBg.x/y/width/height` and `launcherBg.x/y/width/height`. With the Shapes replaced by plain `Rectangle`s, the bounds shrunk from "shape + curve overhang" to "just the island," which is actually more accurate as a click region.
- `notifBg.y` distinguishes side-bar mode (`barMargin` from top) vs top-bar mode (`barMargin + barWidth + islandGap` so it sits below the floating bar). `launcherBg.y` is `barMargin` from bottom regardless of mode.
- `notifColumn` and `launcherPanel` now position themselves *inside* their bgs via `bg.x + bg.spacing` instead of recomputing window-relative offsets — keeps content + container coupled to one source of truth.
- Added `Behavior on width` to both `launcherBg` (the island shadow surface) and `launcherPanel` (the inner content). Both must animate, otherwise content jumps while shadow morphs.
- `launcherBg.x: (win.width - width) / 2` binds to the *animated* `width` property rather than the *instant* `lw` source, so the island stays centered during the width morph instead of growing from its left edge. `launcherPanel.x` chains through `launcherBg.x + launcherBg.spacing` so it follows the animated center automatically.
- Indentation of `notifBg` and `launcherBg` blocks normalized to 12 spaces — was 16, leftover drift from when these were nested under a now-deleted scope.
- `QtQuick.Shapes` import dropped from `Drawers.qml` — no more `Shape`/`ShapePath`/`PathArc` consumers.
- All `Utils.Theme.borderThickness` references in `Drawers.qml` removed (4 sites — two in the deleted Shapes, two in content positioning).

### Phase 6 — Cleanup and DEVGUIDE update ✅

- Grep verification: `rg borderThickness`, `rg bezelIntensity`, `rg frameShadow` across `dot_config/` all return zero hits. (Palette cleanup happened in Phase 0; QML cleanup in Phases 1–3 — this is just verification.)
- `DEVGUIDE.md` — surgical edits, not a section rewrite:
  - L33 semantic-role example currently uses `frameShadow` — swap for an island token (`islandShadowColor` works).
  - L307 testing checklist says "Shadows are visible (dark variants use `crust`, Latte overrides to `overlay0`)" — repoint at `islandShadowColor`.
  - Add a new section documenting the floating-island language: drop-shadow pattern, bar-item active state, invisible hover bridge, `Scale.origin` pivot pattern.
- Root `CLAUDE.md` — current quick check: clean (only generic mentions of bar/launcher/notifs). Re-skim after Phase 5 to be sure nothing went stale.

**Acceptance:** zero hits for removed tokens. DEVGUIDE reads as if the new design was always there.

**Deviations**

- `frameGlow*` tokens (5 properties + Behavior) were "repurposed for Phase 4" in the plan but Phase 4 ended up using explicit `barItemActiveHalo*` tokens instead. Phase 6 deleted the unused `frameGlow*` block from `Theme.qml` and the corresponding `_quickshell.frameGlow*` overrides from `catppuccin-latte.json`.
- Stripped `frameShadow` from `everforest-light.json`, `rose-pine-dawn.json`, and the live `active.json`. The light variants retain their `islandShadowColor` override (`overlay0`-tier neutral) — that's the replacement.
- Dead `modules/bar/components/Tray.qml` and `TrayItem.qml` removed via `git rm`. `TrayOverflow.qml` is the live component; the deletions had no live consumers.
- `chezmoi apply` doesn't proactively delete files removed from source — had to `rm` the deployed `Tray.qml` and `TrayItem.qml` copies in `~/.config/quickshell/modules/bar/components/` manually.
- `~/.config/palette/active.json` drifted from chezmoi (theme-switch writes it on every theme change). chezmoi blocked the apply on it; resolved by `cp`-ing the cleaned source over the deployed copy. Future theme-switches regenerate it anyway.
- Grep result hits in `FLOATING_ISLAND_PLAN.md` are historical references inside the design doc itself — intentional, not a stale-token leak.

## Open Decisions

Resolve as we go; flag in commit messages when locked in. (Decisions already made are recorded inline above and not listed here: hover bridge → invisible `Item` per popout; fullscreen → fade bar out; Latte shadow → `overlay0` override seeded in Phase 0.)

1. ~~**Exact `barMargin` and `barRounding` values.** Initial guess: 8px margin, 16px rounding. Try 12/20 and 6/14 for comparison.~~ → Landed on **6 px margin, 16 px rounding** in Phase 1. User confirmed visually.
2. **Popout background: solid `mantle` vs blur-and-tint.** Solid is simpler and matches current. Blur (`MultiEffect` with `blurEnabled`) feels more island-like but is GPU cost. Start solid; revisit in Phase 3 if it feels flat. → Phase 3 shipped solid `mantle`. Not revisited yet.
3. **Tray-menu origin source.** `TrayOverflow.qml:91–93` already captures per-tray-item geometry via `mapToItem(null, ...)`. Confirmed wired up — but the container-level bloom needs to read this per-item, not the tray-row center. Mechanical; flagging so it isn't forgotten. → Container reads `Services.Popout.centerX/Y` for *all* sources (tray + non-tray), which `TrayOverflow` already populates correctly. Resolved.
4. **Offscreen-clamped origin.** Popouts clamped to screen bounds (e.g. near top of a tall monitor) may have a bloom origin that lands offscreen relative to the container. Pick: shift origin to nearest in-bounds point. Forgiving > geometrically pure. → Currently `Scale.origin` accepts pivots outside item bounds with no visual issue; clamping target position only (not origin). Not exercised at extremes yet.
5. **Launcher width transition.** Current launcher animates width when switching to wallpaper-picker mode. The Shape-based animation goes away; the new rounded `Rectangle` needs an equivalent `Behavior on width`. Mechanical — don't forget. → Resolved in Phase 5: `Behavior on width` added to both `launcherBg` and `launcherPanel` (matched 300 ms OutExpo curve).
6. **Active-state visibility at distance.** On tall monitors, a clamped popout can sit far from its source bar item — the accent-fill + halo on a 24px icon may not be enough visual link at 1000+px separation. Revisit after Phase 4; consider a connector line or stronger halo at extreme distances if it feels weak. → Phase 4 shipped with default `barItemActiveHaloBlur: 20` / `barItemActiveHaloOpacity: 0.5`. Not yet tested at extreme separation; revisit if user feedback shows the link feels weak.
7. **Switch-gate stillness window.** 80 ms picked empirically — short enough that deliberate switches feel snappy, long enough that fast hover-pans fully suppress intermediate content. Revisit if user feedback indicates either lag or leak.

## Test Plan

After each phase, on the dev machine:

- [ ] Open every popout (volume, brightness, system, battery, calendar, wifi, bluetooth, power) and confirm bloom + close animation.
- [ ] Open a tray menu and confirm origin point makes sense for that specific tray item.
- [ ] Move cursor from a bar item across the `islandGap` to its open popout — confirm the popout does **not** close mid-traverse (hover bridge working).
- [ ] Trigger a notification (e.g. `notify-send test`) and confirm float + drop shadow.
- [ ] Open the launcher, switch to wallpaper picker mode, confirm width morph still works.
- [ ] Enter Hyprland fullscreen on a window — confirm bar (and any open popouts) fade out. Exit fullscreen — confirm fade back.
- [ ] `theme-switch catppuccin-mocha`, `catppuccin-latte`, `everforest`, `everforest-light`, `rose-pine`, `rose-pine-dawn` — confirm color transition still animates and shadows look appropriate on each (light variants must look grounded, not glowing).
- [ ] Multi-monitor: with monitors of different sizes/orientations, open popouts on each — confirm bloom origin lands at the correct bar item on each screen, `activeScreen` guard prevents cross-monitor leak.
- [ ] Switch `barMode` between `side` and `top` and confirm both render correctly (positions adapt, bloom origin works in both orientations).
- [ ] Lock the session (`Super+L`) and unlock — confirm `LockScreen` still works (should — it's orthogonal).
- [ ] Quickshell reload (`pkill -USR1 quickshell` or whatever the reload command is for this rig) and confirm no QML warnings in the journal.

## Out of Scope

Explicitly *not* doing in this branch:

- Restructuring popout content QMLs (Volume/Wifi/etc internal layouts).
- The big-popout consolidation noted earlier (extracting a shared "popout shell" primitive from VolumePopout/WifiPopout/SystemPopout). That's its own branch.
- Changing the launcher's interaction model (still a search list).
- Adding new popouts or new bar items.
- Reworking the notification *card* design — only the container becomes a floating island.
- Hyprland config changes beyond what's strictly needed (probably none).

## Reference

- Current `DEVGUIDE.md` documents the three-tier color system and popout patterns. Most of it stays accurate — only the bezel/border and popout-seam sections need updating.
- `Services.Popout.qml` already tracks `centerX`, `centerY`, `currentName`, `activeScreen` — the API needed for the new origin-tracking is already there.
- The per-popout `Popout` Loader component in `PopoutWrapper.qml` (L452–526) is the reference for the spring transition. Same primitive, just promoted to the container level.
