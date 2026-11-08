# Monitors cutover: hyprpier to Strand

Done on 2026-11-08. Strand took over from hyprpier: `strand/monitors.strand` arranges the monitors
from `monitors.toml`, the launcher's Displays page (Alt+Y) arranges, saves and switches profiles,
and its Thunderbolt page (Alt+H) lists the devices bolt knows. hyprpier, its config, its daemon,
its `monitors.lua`, its udev rule and its resume service are gone; the one-off script that
retired them is in git history.

## What replaced what

- **Profiles:** `state/monitors.toml` (linked from `~/.config/strand/monitors.toml`, so Strand's
  saves land in the source), made from hyprpier's three profiles. A `[[profiles]]` table each,
  with its set of monitors and whether it is the set's default.
- **`monitors.lua`:** written by Strand each time a layout takes, for Hyprland's next start.
- **The lid:** Strand's: the panel goes off while the lid is shut and another monitor is on.
- **Resume:** `thunderbolt-resume.service` (`run_onchange_after_setup-thunderbolt-resume.sh`)
  still resets the Thunderbolt controllers after a resume, but replugs only what bolt let in,
  where hyprpier's let every device back in.
- **Docks:** bolt decides. This laptop has IOMMU DMA protection (`iommu_dma_protection = 1`), so
  bolt lets a new device in by itself and stores it with policy `iommu`; the Thunderbolt page's
  "wants to connect" ask comes up only for a device bolt holds back (one kept `manual`, or on a
  machine without the protection). F2 names a stored device and Del forgets it.

## Still to see once

- **At work:** the work profile's monitor ids come from hyprpier's profile, and Strand hasn't seen
  those monitors yet. If Alt+Y says "Best guess", hyprpier's ids didn't match: compare them with the
  "work" listed as not connected (its pane names its monitors), select it and Del to forget it, since
  a name is one profile's whatever the set and saving the guess as "work" is refused while it is
  there. Then arrange the guess on Alt+Y: select a monitor (↑ ↓ or a click on its tile), move it
  with ← → and ⇧↑ ⇧↓ or drag its tile, give it its workspaces with Alt+1 to Alt+0, then Ctrl+S and
  name it "work". Each change goes up at once and Esc puts back what was there. chezmoi's
  autoCommit commits a save at the next `chezmoi` write, or you can commit it by hand.
- **Monitor modes:** on a U2720Q (several modes), Ctrl+M and Ctrl+Shift+M on the Displays page
  should step its mode down and up (`hyprctl monitors` shows each), the scale falling back to one
  the mode takes, and Esc should put the saved mode back.
- **After a suspend with the dock attached**, which is still the open docked-suspend re-test in
  `dot_config/hypr/README.md`: the dock's USB devices should be back within a few seconds, and
  `journalctl -b -u thunderbolt-resume` shouldn't say "not let back in". The service waits up to
  30 s for bolt to let back in each stored dock that is still plugged in, and 8 s at most for one
  unplugged while asleep. It doesn't wait for a device stored with policy manual.
