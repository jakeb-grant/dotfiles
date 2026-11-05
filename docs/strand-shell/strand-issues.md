# Strand issues

Problems found while building this shell that look like Strand's to fix. They're parked here and get
fixed in Strand later. Newest first. The keyboard gaps are listed separately, in `features.md`
section 3.

## Checking an issue

Each issue has a folder under `strand-issues/` with its own config and a check that reads the result
from a screenshot. It runs in Strand's CI container on a headless sway, never on a desktop session, and
needs nothing from this machine's config.

```sh
cd ~/projects/strand
scripts/container/run.sh cargo build -p strand
~/.local/share/chezmoi/docs/strand-shell/strand-issues/verify.sh ~/.local/share/chezmoi/docs/strand-shell/strand-issues/<issue-folder> ~/projects/strand
```

| Exit | Meaning |
| --- | --- |
| 0 | Fixed |
| 1 | The issue is still there |
| 2 | The check itself could not run, or a control failed. Says nothing about the issue |

It prints the checkout's commit and when the binary was built, since nothing ties the two together:
build first, as above. Its working files go in the checkout's `target/issue-repro/`.

A new issue needs a folder with `strand/`, `home/` (the check's `$HOME`) and `check.py`, plus controls
where they can show the check is working.

## Open

### A lock's first frames come before its still of the screen

Found 2026-11-05 on Strand `3714cc62`, in the lock VM (owner_lock scratch test, frames grabbed back
to back).

**What happens:** a `thumbnail screen` inside `lock { }` shows nothing in the lock's first frames:
its still, taken before the lock, is only handed to the thumbnail once a frame has shown the
thumbnail is visible (`Feeds::demand`). A lock meant to open on the desktop as it was opens on its
own background for a few frames and then cuts to the still, a flicker. A panel's first frame waits
for its stills (`Feeds::before_map`, `HOLD`); a lock's doesn't.

**What it should do:** a lock's first frame waits (bounded, like `HOLD`) until its thumbnails have
their stills, so it can open on the desktop and change from there.

**Worked around:** the lock opens dark and the blurred desktop fades up behind a veil.

### Full-screen blur is slow on the GPU, and a backdrop's first draw differs

Found 2026-11-05 on Strand `3714cc62`, on this laptop's Intel Arc B390 in `gpu.sh` (the lock's
content as a 1920x1200 overlay panel; probe in Strand's `target/try/notes/lockgpu`).

**What happens:**
- `filter: blur(36)` on a full-screen image of the still takes about 500 ms to come up: the panel
  draws without it meanwhile and it pops in.
- A full-screen `backdrop: blur(36)` costs a 70 ms frame when it first draws at full strength, and
  that first draw lets the sharp desktop show through; the next frame snaps to the full blur. The
  surface is promoted to the GPU mid-animation, and the CPU's quarter-scale blur and the GPU's
  full-resolution one don't match.
- A box with `filter: blur(22)` whose size animates (a soft shadow on a growing card) costs about
  20 ms every frame (27 ms median, 49 ms p95 with the backdrop).
- An `image` drawn small with `filter: blur` and `scale: 8` is rasterised at full size again, so it
  comes out barely blurred.

**What it should do:** a blur of something that doesn't change is drawn once, cached, and costs
nothing after; a backdrop looks the same from its first frame; an animated soft shadow fits in a
120 Hz frame.

**Worked around:** the backdrop fades in from nothing under the veil (6 to 7 ms median, 9 to 12 ms
p95, under 20 ms worst), and the card has no shadow.

### A `shadow:` inside a lock shrinks the lock and delays it

Found 2026-11-05 on Strand `3714cc62`. No check folder: it needs the lock VM
(`scripts/container/lockvm.sh`), which `verify.sh` doesn't run; seen there with the owner_lock
scratch test on this shell's `lock.strand`.

**What happens:** any node inside `lock { }` with a `shadow:` (here the card, 420×268 in the middle of
a 1280×720 output) draws the whole lock smaller than the output: inset by about 73 px left and right
and 91 px top and bottom, with black around it. Sizing the lock's contents to `screen.width` ×
`screen.height` brings back the width but leaves the top 49 px black, and `clip: true` on the
outer stack changes nothing. The first frame also comes about 530 ms later than without the shadow
(600 ms against 70 ms).

**What it should do:** a shadow inside a lock is paint, like anywhere else: the lock fills its output
and the shadow is cut at its edge.

**Worked around:** the card has no shadow. A blurred box standing in for one cost about 20 ms a frame
while the card grew (below).

### A lock can't play its way out

Found 2026-11-05 on Strand `3714cc62`.

**What happens:** the lock goes the moment the password is accepted, so there is no closing
animation (the island shrinking back up into the bar) the way the launcher has one.

**What it should do:** a lock could keep its surface for an `exit { }` pose after it unlocks, as
other surfaces do when they close.

## Fixed

### A list reports its starting selection a tick late

Found 2026-11-05 on Strand `9f19dfc6`. No check folder yet; seen on a test copy of this launcher.

**What happens:** a `list` with `selected_index: n` starts on row `n`, but its `on select` (here
mirrored into `results_at`) hears of it a tick after the list mounts. Anything that follows the
mirrored index shows the old row for that tick: the Themes page previewed the first theme for one
frame before the theme in use, a flash of the whole shell's colours.

**In this config:** `launcher.strand` sets `results_at = theme_at` itself in `on change view` when
the Themes page opens.

**Done when:** a list's starting selection reaches its `on select` (or a binding over the list's
selection) in the tick it mounts, or the docs say it doesn't and give the pattern.

**Fixed** in Strand `3714cc62` (decisions.md list-start). A list's start now reaches `selected_index`, its `on change` and what reads it in the tick that sets it: as it mounts, when the start changes while you haven't moved, and when a new search or whole new rows start it again. Two edges stay, both in decisions.md: on the launcher's very first opening after boot an `on change` of the preview hears the old row inside the tick (never drawn), and a list whose surface gets the keyboard back starts on its start a frame before logic hears it. **In this config:** the `on change view` workaround for the Themes page is gone. Done in this config on 2026-11-05, on Strand `3714cc62`.

### Eventually: a dictionary type

Found 2026-11-04 on Strand `035ac995`. Not needed yet: parked so it isn't forgotten.

**What happens:** a config that remembers things keyed by something (the last window used on each
workspace, a per-app setting) keeps them as a list of records, `type Seen { ws: int; win: text }` in
`state seen: [Seen] = [] persist`, looks one up with `.find` and writes one with `.filter` plus an
added record. That works for dozens of entries but reads clumsily, and nothing caps a persisted list,
so the config has to trim it itself. `persist` itself is enough as the store (no database needed).

**In this config:** nothing uses it yet; the island's workspace chips order icons by window size
instead of by last use.

**Done when:** a typed dictionary (`state seen: {int: text} = {} persist`, with get, set and remove),
or the docs give the list-of-records pattern with a way to bound it.

**Fixed** in Strand `f657a245` (decisions.md dictionary). `[K: V]` dictionaries: `state last_win: [int: text] = [] persist`, read `m[k]` (null when absent), written `m[k] = v` in a handler, `m.remove(k)` (nothing when absent), `m.clear()`, `m.entries` for a `for`, and `m.filter(…)` to bound one. Keys are `int`, `text`, `path`, `bool` or an enum; persisted as JSON, settings as TOML tables, `strand get`/`set` reach one entry. A keyed list also reads one item with `xs.get(k)`. Braces (`{1: "a"}`) and Python or JS method names (`m.get`, `m.items()`) get errors that say the Strand form. The docs cover them wherever lists and records are, with a how-to on remembering by key. **In this config:** nothing uses one yet; the workspace chips could order icons by last use with `[int: text]`.

### A player can't be raised, sought by an offset, or matched to its app

Found 2026-11-04 on Strand `035ac995`. Not needed yet: the Media page works without them.

**What happens:** `Player` has no `raise()` (MPRIS `Raise`), so the Media page can't take you to the
browser tab or app that plays; no relative seek (MPRIS `Seek`), so the 15 s skips write `position`
as a fraction of `length` and do nothing on a stream whose length is unknown; and no icon or desktop
entry (MPRIS `DesktopEntry`), so a row can't show the app's icon beside the art.

**In this config:** `launcher.strand`, the Media page (`seek_step / length`).

**Done when:** `Player.raise()` with `can_raise`, `Player.seek(by: duration)`, and `Player.icon` (or
`app`), on `media` for the active player too.

**Fixed** in Strand `9f19dfc6` (decisions.md player-raise-seek). `Player.raise()` with `can_raise`, `Player.seek(by: duration)` with its own `can_seek_by` (`can_seek` still means a `position` write works, which needs the length), and `p.icon`/`p.app` from the desktop entry, on `media` too. **In this config:** the Media page's skips can become `p.seek(by: ±seek_step)`, guarded by `can_seek_by`. Done in this config on 2026-11-05, on Strand `f657a245`.

### Siblings glide on a curve of their own

Found 2026-11-04 on Strand `035ac995`.

**What happens:** when a node in a row is added or removed, its siblings glide to their new places
(spec.md 6.6) on Strand's own curve, and nothing in the config can set it. The island's workspace
highlight is placed by sums of the chips' widths on its own spring (`glide`), so while an empty
workspace's chip came or went, the chips slid on one curve and the highlight on another, and the
switch wobbled. Nor can a node follow another's laid-out box: a `morph` would, but it scales the
node, so a rounded highlight's corners and border stretch between two chip widths.

**In this config:** `island.strand` sizes each chip on `glide` itself (it grows from width 0 and
shrinks to 0, carrying its gap), so the siblings never have a jump to glide over.

**Done when:** the siblings' glide can take a curve (`~` on the container, say), or a node can follow
another's laid-out box without scaling. The docs should name the curve either way.

**Fixed** in Strand `9f19dfc6` (decisions.md glide-curve). A glide (and a wheel step, and a dragged row let go) plays the `$motion.spatial` in effect where the node is, so `set { $motion.spatial: glide }` names the curve; no new syntax. Inside a content-sized surface springing over a step, glides still ride the step's curve. **In this config:** kept as it is (decided 2026-11-05). The highlight behind the chips is placed by sums of their widths on `glide`, so each chip still has to size itself on that spring: a chip left to Strand's sibling glide would snap wider when it gains an app while the highlight springs, and the two would part for a moment. The fix still matters for a row without such a highlight.

### A `list` has no way to start on a row

Found 2026-11-04 on Strand `035ac995`.

**What happens:** a `list` that mounts selects its first row, and `results.select(i)` reaches it only
once it is mounted. The launcher's list mounts once the box has dropped, 110 ms after it opens, and
the Themes page's rows (from a `poll` service read only while shown) come in about then, so opening
on the theme in use took three handlers (on the drop, on the themes arriving, and on the selection
landing elsewhere) and a hold on the preview so the first theme's colours don't flash.

**In this config:** `launcher.strand`, "the Themes page opens on the theme in use".

**Done when:** a list can say where its selection starts (`selected: theme_at`, kept until the rows
it names are there), or the docs give the pattern.

**Fixed** in Strand `9f19dfc6` (decisions.md list-selection). A list takes `selected_index: n` (the issue suggested `selected:`, but `selected` is already a row's own flag), kept until its rows arrive and followed again when it changes, unless the user has moved since. **In this config:** the Themes page's three handlers, `theme_held` and its hold can go. Done in this config on 2026-11-05, on Strand `f657a245`.

### A panel's `on change` handlers seem not to run while it is closed

Found 2026-11-04 on Strand `035ac995`; seen, not proved on its own.

**What happens:** `on change view { theme_held = view == theme_list }`, written inside `panel
Launcher`, didn't set the state when Alt+T opened the launcher (`view` and `open` set in one handler
while the panel was closed). The same line at the top level of the file works. The docs don't say
when a surface's handlers run.

**In this config:** `launcher.strand` keeps that line at the top level.

**Done when:** the docs say whether a surface's handlers run while it is closed, and a change made
in the tick that opens it is seen by them either way.

**Fixed** in Strand `9f19dfc6` (decisions.md panel-change-closed). Real, and reproduced on a copy of this launcher. A closed surface's handlers now wait, and when it opens they catch up with a change they missed, including one made in the tick that opens it. **In this config:** `on change view { theme_held = … }` can move back inside `panel Launcher` (or go with the Themes workaround). Done in this config on 2026-11-05, on Strand `f657a245`.

### A power profile asked for can settle on another

Found 2026-11-04 on Strand `035ac995`, with power-profiles-daemon on this laptop.

**What happens:** `power.profile = power_saver` while on performance ends on balanced. The firmware
offers only balanced and performance (`/sys/firmware/acpi/platform_profile_choices`), so the daemon
writes balanced to it, then reads its own write back as a switch to balanced. From balanced, power
saver takes. Strand reports the write as done (power saver) and then follows the daemon to balanced,
so a menu that cycles skips power saver.

**In this config:** `launcher.strand` remembers the profile it asked for (`want_profile`) and asks once
more when the daemon settles on another within two seconds.

**Done when:** Strand's `power` asks once more itself when the daemon settles elsewhere right after a
write (or the docs say it may, and how to handle it). No check folder yet: it needs a daemon with the
quirk, which `target/try/notes/looks/ppd_quirk.py` stands in for on top of the dbusmock template.

**Fixed** in Strand `9f19dfc6` (decisions.md power-reask). The builtin `power` asks once more itself when the daemon settles on another profile within 2 s of a write, then follows the daemon. Tried against a stand-in daemon with the quirk, not yet against this laptop's. **In this config:** `want_profile` and its retry can go. Done in this config on 2026-11-05, on Strand `f657a245`.

### A `Screen` has no position, so monitors can't be put in order

Found 2026-11-04 on Strand `035ac995`.

**What happens:** `Screen` has `name`, `width`, `height` and `scale`, but not where the monitor sits.
A wallpaper set puts its images on the monitors left to right, which needs each one's `x` (and `y`).
The order of `screens.all` isn't documented and doesn't follow the layout.

**In this config:** the `wall` action in `launcher.strand` asks `hyprctl -j monitors` and sorts by `x`
with jq, so it works only on Hyprland.

**Done when:** a `Screen` has its position in the layout (`x`, `y` in logical pixels), or
`screens.all` is documented to be in layout order.

**Fixed** in Strand `9f19dfc6` (decisions.md screen-position). `Screen` has `x` and `y` (logical pixels, from xdg-output), and `screens.all` is in layout order: left to right, then top to bottom. **In this config:** the `wall` action can use `screens.all` instead of `hyprctl -j monitors` and jq. Done in this config on 2026-11-05, on Strand `f657a245`.

### Removed state opens the reload notice box, listed as "renamed"

Found 2026-11-03 on Strand `fb75dc93`.

**What happens:** a save that removes `state` cells (here `notify.grown`, `notify.filled`,
`notify.shown`, and `launcher.wide`, which became `out`) opens the overlay as "strand: reloaded with
notices", one row per cell: `notify.grown: reset (renamed)`. Nothing needs doing, but the box stays
up until its × is clicked. "Renamed" is wrong for the three that were deleted, and `strand watch
--json` lists them under `reset`, not `notices`, so the box shows more than the reload reported.

**In this config:** nothing; close the box.

**Done when:** a removed cell opens no box (or says "removed"), and the box and `watch` agree.

**Fixed** in Strand `9f19dfc6` (decisions.md removed-state-notice). A cell is called renamed only when its own file or component gained one; a removed cell goes silently unless its whole file went while it held a value you set, and the box and `strand watch` agree. **In this config:** nothing to change.

### A list's selection goes to its first row when the selected row leaves

Found 2026-11-03 on Strand `1966fab0`.

**What happens:** clearing the selected notification on the launcher's Notifications page (a keyed
row leaving the `list`) moves the selection to the list's first row, Do not disturb, not to the row
that takes its place. `results.select(i)` in the same handler doesn't help: it applies before the
row has gone. The docs don't say where the selection goes.

**In this config:** `launcher.strand` keeps the place in `keep_at` and selects it again once the
list is shorter (`on change found_notes.len`).

**Done when:** the selection stays at its place (or the docs say where it goes, and how to keep it).

**Fixed** in Strand `9f19dfc6` (decisions.md list-selection). When the selected row leaves and other rows stay, the selection stays at its place (the row that takes it, or the new last row). **In this config:** `keep_at` and its `on change found_notes.len` can go. Done in this config on 2026-11-05, on Strand `f657a245`.

### A `path` argument to an action keeps a literal `~`

Found 2026-11-03 on Strand `6827541b`.

**What happens:** `action rec(file: path) ["wf-recorder", "-f", file]` called with `"~/Videos/a.mp4"`
runs wf-recorder with that text unchanged, so it fails (`avio_open failed`, exit 255). Everywhere
else Strand takes a path (`from dir`, `file`, `state … from`), `~/…` is the home folder, so the
`path` type reads as if it would expand it too. The spec (5.7) says each argument is passed "as
`text` shows it", which is why it doesn't; there's also no builtin for the home folder to build one.

**In this config:** `strand/record.strand` runs wf-recorder through `sh -c` so the shell expands
`$HOME`.

**Done when:** a `path` argument starting with `~/` reaches the program as a full path (or the
docs say plainly that it doesn't, and give a way to name the home folder).

**Fixed** in Strand `9f19dfc6` (decisions.md path-tilde). A `path` parameter's `~/…` reaches the program with the home folder in its place, as everywhere else Strand takes a path; a bare `~` and `text` parameters stay as written. **In this config:** `record.strand` can call wf-recorder directly instead of through `sh -c`. Done in this config on 2026-11-05, on Strand `f657a245`.

### A delete-then-create save can blank the shell for a moment

Found 2026-11-01. Not caused by this shell: it fails the same on `d7572909`, before the keyboard work.

**What happens:** Strand's `five_save_styles_land_on_a_cold_boot` fails with `round 23 (style 3, missing
16 ms): a blank frame`. The file was gone for far less than the watcher's 50 ms removal grace, yet the
scene went empty. So a reload that's already running can read the folder while the file is missing. My
guess, not traced: the grace covers the watcher's removal event, not a read started by the save before it.

**How to reproduce:** run that test 32 at a time, in Strand's container. It failed 140 of 1,280 on
`2c37ea59` and 210 of 1,280 on `d7572909`, always on round 23. It failed once on GitHub, on `2c37ea59`.

**Why it matters:** only editors that delete then create a file are exposed, and only just after another
save. It's a flash on a save, not a crash. It also makes GitHub's `test` job fail now and then.

**Done when:** the test passes that loop.

**Fixed** in Strand `9f19dfc6` (decisions.md save-blank). The watcher's own flush was listing the folder inside the save's gap. Now a file whose removal was heard is never reported removed until its 50 ms grace is over, whichever flush finds it missing. The loop that failed 31 of 320 on `035ac995` passed 1,280 of 1,280. **In this config:** nothing to change.

### A real card's profiles never reach `AudioDevice.profiles`
Found 2026-11-04 on Strand `d6623f12`, with AirPods Pro connected.

**What happens:** PipeWire lists the AirPods' five profiles (device 44, `pw-dump 44`), and the sink
and the microphone both name that card (`device.id` 44), yet `audio.sink.profiles` is empty in the
running shell (read through a temporary `export let`). So the Sound page shows no headset modes, and
the microphone row can't tell that the AirPods are in A2DP, where they have no microphone, or switch
them to call mode. Strand's only live test of card profiles runs on a PipeWire with no cards.
**Likely cause:** `Profiles` in `strand-services/src/audio/thread.rs` keeps only the profiles that arrive
before the core sync it issues after the param info, and drops any that come later. A card lives in
WirePlumber's process, so PipeWire fetches its params from there, and they can arrive after the sync.
Routes (`Routes`) accept items whenever they come, which is why volume writes to cards work.
**In this config:** nothing to do; the mode rows and "asleep in music mode" stay hidden until it's fixed.
**No headless check:** it needs a real card (ALSA or Bluetooth), which the container can't have.
**Fixed** in Strand `035ac995` (decisions.md card-params). There were two causes, and the guess above was only near the first. A change to a card's params arrives as the info alone, so the profiles are now asked for again. And a node info event without properties no longer takes a node off its card. Checked on the laptop: the webcam card kept its profiles through a switch, and the AirPods' modes show on the Sound page.

### A save loaded the file a second time when the config path was relative

Fixed on Strand's `main` in `fb75dc93` (2026-11-03). Found the same day on `1966fab0`.

**What happened:** with the shell started as `strand run strand`, every save (in place or by
rename) was taken for a second copy of the file, under its absolute path, beside the one loaded at
start under `strand/…`. Every name in it was declared twice, the save was held back and the error
overlay stayed up, while `strand check` said 0 errors.

**The fix:** the live reload loads the config by its absolute path, as the watcher reports saves.
Strand's test is `a_save_in_a_config_named_by_a_relative_path_replaces_its_file`.

**In this config:** nothing; `strand run strand` works once the installed Strand has the fix.

### A shadow's room outside a surface changed while it animated

Closed on Strand's `main` in `1966fab0` (2026-11-03). Found the same day on `6827541b`: the owner saw
the launcher twitch about 20 px left and back as it came to rest, on every monitor.

**What happened:** Strand asked Hyprland for a new size or margins while the launcher animated: its
content's width first (no monitor known yet), then the monitor's; 34 px more below as the card
dropped; on the reopen 28 px more each side, until it came to rest. Hyprland animates every such
change and draws the new frame at the old place meanwhile, so each showed as a jump.

**The fix:** a panel anchored to one edge is stretched along it by the compositor from its first
configure; its shadow room is reserved once from every shadow it may take; on Hyprland its own moves
are painted. Strand's test is `a_mapped_layer_surface_sends_no_layer_state_after_its_first_configure`.

**In this config:** the workaround is gone (`shade`, `shade_side`, the outer row's extra room,
`screens: (focused)`).

**Worth knowing:** Hyprland also fades a layer surface in as it appears, which made the launcher
look like a second layer over the island. That one needs a rule in Hyprland's config: run
`strand compositor-rules` (Strand `6ed19378`), and see Strand's "Strand and your compositor" page.

### A flat file of named colours couldn't be a palette

Closed on Strand's `main` in `d7572909` by `palette(...)`. Found 2026-10-31 on `a18cfdeb`. Folders:
`strand-issues/palette-import-flat`, whose check now exits 0, and its control,
`strand-issues/palette-import-flat-control`.

**What happened:** a file with colour names at the top level, as `active.json` has, had no way into
Strand's tokens. The config could read the colours through `service … from file`, but `$fg`, `$surface`,
`$accent` and the built-in widgets didn't follow them.

**The fix:** `palette(from:, <role>: color?)` makes a palette from colours of any source, so the file's
format and names stay out of Strand. The service reads the file, and the config says which name is which
role. `import("w3c:…")` on the flat file still fails at runtime with 0 errors from `strand check`; that
form is for W3C tokens, and there's no longer a reason to use it here.

**In this config:** `strand/island.strand` has the mapping, and its colours are `$` tokens.

**Worth knowing:**
- A broken or removed file goes to `from`'s colours. It doesn't keep the last good theme.
- A broken file logs one warning per colour the service reads.

### Reading a `let` before its own line blanked its later shades

Fixed on Strand's `main` in `d5055aea`. Found 2026-10-31 as "a default parameter blanks a `let`'s other
shades". Folder: `strand-issues/shade-default-param`, whose check now exits 0.

**What happened:** with `let a = base.alpha(0.7)`, `let b = base.alpha(0.3)` and a default
`c: color = a`, `b` drew nothing and `strand check` reported 0 errors.

**Cause:** a declaration read before its own line is checked at that read. When its line asked again,
the checker marked it as still being checked, for good, so later reads got an error type that nothing
reported, and a method call on that lowered to null. A default parameter was one way in; an earlier
`let`, `state` or `fn` reading a later one did the same. Strand's test is
`a_declaration_read_before_its_line_keeps_its_type`.

**In this config:** `lit.alpha(...)` in `strand/island.strand` depends on this fix.
