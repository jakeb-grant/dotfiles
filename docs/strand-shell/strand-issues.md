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

### A workspace moved off a monitor turned off still reads as shown

**What happens:** docked with the lid shut, Hyprland moves the panel's workspace (1) to the
monitor that stays on, which already shows its own. `workspaces.all` then has two workspaces with
`active` true and the same `screen`: the moved one keeps `active` from the monitor it left.

**What it should do:** one workspace is active per screen, the one Hyprland shows there.

**Worked around:** `monitors.strand` doesn't trust a screen that reads as showing two
(`shows_own`), and focuses one of the monitor's own there.

### Output.id ends in a space when there is no serial

**What happens:** `Output.id` (and `Screen.id`) is `make | model | serial` (or the description) with
the last part empty and its space kept: this laptop's panel reads `… | ` with a trailing space, and
Hyprland's headless outputs `Unknown | Unknown | `. A profile written by hand, or read back from a
TOML file an editor trimmed, no longer matches.

**What it should do:** no trailing separator when a part is empty, or the id trimmed.

**Worked around:** `monitors.strand` compares `o.id.trim()`.

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

**What happens:** turning one monitor of a profile off means rebuilding its `Mon` with every field
written out (`as_held`), so a field added to the type must be added there too.

**What it should do:** something like `m with { on: false }`.

Fixed issues and their repro folders are in git history (the last went with the cleanup of 2026-11-07).
