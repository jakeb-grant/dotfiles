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

### A player can't be raised, sought by an offset, or matched to its app

Found 2026-11-04 on Strand `035ac995`. Not needed yet: the Media page works without them.

**What happens:** `Player` has no `raise()` (MPRIS `Raise`), so the Media page can't take you to the
browser tab or app that plays; no relative seek (MPRIS `Seek`), so the 15 s skips write `position`
as a fraction of `length` and do nothing on a stream whose length is unknown; and no icon or desktop
entry (MPRIS `DesktopEntry`), so a row can't show the app's icon beside the art.

**In this config:** `launcher.strand`, the Media page (`seek_step / length`).

**Done when:** `Player.raise()` with `can_raise`, `Player.seek(by: duration)`, and `Player.icon` (or
`app`), on `media` for the active player too.

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

### A panel's `on change` handlers seem not to run while it is closed

Found 2026-11-04 on Strand `035ac995`; seen, not proved on its own.

**What happens:** `on change view { theme_held = view == theme_list }`, written inside `panel
Launcher`, didn't set the state when Alt+T opened the launcher (`view` and `open` set in one handler
while the panel was closed). The same line at the top level of the file works. The docs don't say
when a surface's handlers run.

**In this config:** `launcher.strand` keeps that line at the top level.

**Done when:** the docs say whether a surface's handlers run while it is closed, and a change made
in the tick that opens it is seen by them either way.

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

### A `Screen` has no position, so monitors can't be put in order

Found 2026-11-04 on Strand `035ac995`.

**What happens:** `Screen` has `name`, `width`, `height` and `scale`, but not where the monitor sits.
A wallpaper set puts its images on the monitors left to right, which needs each one's `x` (and `y`).
The order of `screens.all` isn't documented and doesn't follow the layout.

**In this config:** the `wall` action in `launcher.strand` asks `hyprctl -j monitors` and sorts by `x`
with jq, so it works only on Hyprland.

**Done when:** a `Screen` has its position in the layout (`x`, `y` in logical pixels), or
`screens.all` is documented to be in layout order.

### Removed state opens the reload notice box, listed as "renamed"

Found 2026-11-03 on Strand `fb75dc93`.

**What happens:** a save that removes `state` cells (here `notify.grown`, `notify.filled`,
`notify.shown`, and `launcher.wide`, which became `out`) opens the overlay as "strand: reloaded with
notices", one row per cell: `notify.grown: reset (renamed)`. Nothing needs doing, but the box stays
up until its × is clicked. "Renamed" is wrong for the three that were deleted, and `strand watch
--json` lists them under `reset`, not `notices`, so the box shows more than the reload reported.

**In this config:** nothing; close the box.

**Done when:** a removed cell opens no box (or says "removed"), and the box and `watch` agree.

### A list's selection goes to its first row when the selected row leaves

Found 2026-11-03 on Strand `1966fab0`.

**What happens:** clearing the selected notification on the launcher's Notifications page (a keyed
row leaving the `list`) moves the selection to the list's first row, Do not disturb, not to the row
that takes its place. `results.select(i)` in the same handler doesn't help: it applies before the
row has gone. The docs don't say where the selection goes.

**In this config:** `launcher.strand` keeps the place in `keep_at` and selects it again once the
list is shorter (`on change found_notes.len`).

**Done when:** the selection stays at its place (or the docs say where it goes, and how to keep it).

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

## Fixed

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
