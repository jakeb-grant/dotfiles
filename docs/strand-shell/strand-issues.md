# Strand issues

Problems found while building this shell that look like Strand's to fix. They're parked here and get
fixed in Strand later. Newest first.

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

Found 2026-11-08 on Strand `d9d726f4` while building `monitors.strand` and the Thunderbolt page, in
nested Hyprland 0.57 (Strand's `target/try/mon`: headless outputs, a fake UPower and a fake bolt on a
private system bus). No repro folders yet: the harness needs nested Hyprland, which `verify.sh`'s
headless sway can't stand in for.

### A whole number reads as float through `reduce` and `distinct`

**What happens:** `strand check` types these as `float`, so an `int` let or return refuses them:
`xs.reduce(-1, (m, x) => x > m ? x : m)` over `xs: [int]` (a negative literal as the start),
`[3, 1, 2].reduce(0, …)` (a list literal with no type), and `[0, n].distinct()` with `n: int`
(`[float]`). `xs.reduce(0, …)` over a typed `[int]` is `int`.

**What it should do:** a whole-number literal stays `int` there, as it does everywhere else.

**Worked around:** the monitor editor's `band_end` starts its `reduce` at 0 (rows are never above
0), and its offset stops are a typed `let pts: [int]` with no `distinct`.

### A workspace moved off a monitor turned off still reads as shown

**What happens:** docked with the lid shut, Hyprland moves the panel's workspace (1) to the
monitor that stays on, which already shows its own. `workspaces.all` then has two workspaces with
`active` true and the same `screen`: the moved one keeps `active` from the monitor it left.

**What it should do:** one workspace is active per screen, the one Hyprland shows there.

**Worked around:** `monitors.strand` doesn't trust a screen that reads as showing two
(`shows_own`), and focuses one of the monitor's own there.

### Output.id ends in a space when the description is empty

**What happens:** `Output.id` (and `Screen.id`) is `make | model | description` (the description
without its connector, `output_id` in strand-services' `outputs.rs`), joined by `" | "` even when a
part is empty. Hyprland's headless outputs have no description, so their id is
`Unknown | Unknown | ` with a trailing space, and a description that itself ends in a space would
do the same. A profile written by hand, or read back from a TOML file an editor trimmed, no longer
matches. Not seen on this laptop's monitors: `hyprctl` gives the panel's description as
`LG Display 0x07C7`, but what its `wl_output` sends wasn't checked.

**What it should do:** no trailing separator when a part is empty, or the id trimmed.

**Worked around:** `monitors.strand` compares `o.id.trim()`.

### Identical monitors swap ids across a restart

**What happens:** monitors with the same make, model and description are numbered `#2`, `#3`.
Plugged in while Strand runs, they're numbered in the order they came; after a Strand restart, in
the order of their names. Three of Hyprland's headless outputs (all `Unknown | Unknown | `) made
as eDP-1, then DP-2, then DP-6 had eDP-1 as the bare id, and after a restart DP-2. A profile
keyed by those ids then puts each one where another was, and its workspaces with it.

**What it should do:** the same id for the same output for as long as it's connected, or numbering
that doesn't depend on history (by connector name, say).

**Worked around:** nothing: this laptop's monitors all have serial numbers, so no two ids are alike.
Only the nested-Hyprland test harness has identical heads.

### Nothing says which output is the laptop's own panel

**What happens:** a config that treats the panel apart (off while the lid is shut) has only the
connector's name to go on (`eDP-…`, `LVDS-…`, `DSI-…`).

**What it should do:** `Output.internal` (or similar), from the connector type the compositor gives.

**Worked around:** `o.name.starts_with("eDP")`, which is right for this laptop.

### A from-dbus method action's failure is only logged

**What happens:** `bolt.enroll(…)` failing (bolt refuses to enroll a device already stored) shows
only in Strand's log; there is no `bolt.enroll.error` the way a declared command action has
`.error`, so the page can't say why.

**What it should do:** a `from dbus` method action reads as its run too (`.running`, `.error`), as
declared command actions do (decisions.md action-error).

**Worked around:** the page never calls `enroll` on a stored device; the `boltctl` actions' `.error`
goes to the hint row.

### from dbus reads one object's properties, and can't read a method's answer

**What happens:** bolt lists its devices with a method (`ListDevices`, object paths), each device is
its own object, and authorizing or naming one is a method or property on that object. A `from dbus`
service binds properties and actions to one fixed object and can't read what a method returns.

**What it should do:** a field read from a method's answer (or `ObjectManager`-style children), and
actions on an object a value names.

**Worked around:** `~/.local/bin/bolt-devices` (busctl, jq, gdbus) prints the devices as a JSON line
for `from listen`, and `boltctl` actions authorize once and name.

### `strand check` doesn't read settings files

**What happens:** `strand check` on a copy of the config checks `state … from "monitors.toml"`'s
types, not the file: a profile with a typo'd key or a wrong type is only found by the running shell.

**What it should do:** check reads each settings file it can find beside the config and reports
what wouldn't load, as the running shell would.

### No way to copy a record with one field changed

**What happens:** the monitor editor changes one or two fields of a `Mon` at a time (its place, on or
off, mode and scale and turn, workspaces), and each change is a function rebuilding it with every
field written out (`moved_to`, `lit_as`, `shown_as`, `holding` in `monitors.strand`; a `Seat` the
same in `slid`), so a field added to the type must be added to each.

**What it should do:** something like `m with { on: false }`.

Fixed issues and their repro folders are in git history (the last went with the cleanup of 2026-11-07).
