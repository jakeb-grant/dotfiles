# Hypr Idle / Sleep Configuration

## Current state (as of 2026-05-14)

- **Lock at 10 min idle** → `loginctl lock-session` → quickshell lock surface
- **Displays off at 30 min idle** → `hyprctl dispatch 'hl.dsp.dpms("off")'` (kept longer than the lock timeout so the lockscreen stays visible for ~20 min before screens sleep)
- **No auto-suspend.** Intentionally removed.

## Why no auto-suspend

On 2026-05-14, unattended auto-suspend (`systemctl suspend` after 30 min idle while docked with external displays) triggered a kernel NULL dereference in the `xe` GPU driver. The crash wedged the system: no display output, dbus timing out, `sudo` / `systemctl` hanging indefinitely. Hard reboot was the only recovery.

Stack trace summary from `journalctl -b -1 --priority=err`:

```
xe 0000:00:02.0: [drm] *ERROR* Sending link address failed with -5
BUG: kernel NULL pointer dereference, address: 000000000000003c
Freezing user space processes failed after 20.002 seconds
systemd-sleep: Failed to put system to sleep. System resumed again: Device or resource busy
```

The `xe` driver on Panther Lake (integrated Arc B390, PCI ID `8086:b080`) is not yet reliable through full suspend cycles with external displays attached. Removing the unattended trigger eliminates the worst case — a crash with no human present to catch the wedge.

This is a kernel-side bug, not a config bug. The dotfile change is mitigation, not fix.

## User-side practice while xe is unstable

- **Long absences (hours+):** `systemctl poweroff`. Boot is fast; avoids the broken suspend path entirely.
- **Short absences (meeting, lunch):** walk away. Lock + DPMS-off handle it; machine stays at full power but won't crash.
- **Manual `systemctl suspend` while docked is still risky** — same code path that crashed. If you need to suspend, undock first.
- **Lid-close-undocked suspend works** (logind tears down displays before suspend). Safe to keep using.

## Ideal config — restore once xe is stable

Re-add this listener to `hypridle.conf`:

```
# Suspend after 30 minutes
listener {
    timeout = 1800
    on-timeout = systemctl suspend
}
```

This is the original 30-minute unattended-suspend behavior.

## Re-test procedure before restoring

Do not restore the suspend listener on faith. Verify the kernel actually fixed the bug:

1. Dock with external displays connected.
2. Run `systemctl suspend` manually with a recoverable terminal / second machine handy.
3. Wait for full suspend (machine actually powers down to S3/s2idle, not just screen-off).
4. Wake. Verify displays restore, dbus responds (`systemctl status` returns promptly), no errors in `journalctl -b -k | grep -iE 'xe|drm'`.
5. Repeat across **2–3 kernel releases** without recurrence before re-enabling unattended auto-suspend.

## If it recurs

Capture immediately on the next boot, before logs roll:

```
journalctl -b -1 --priority=err > /tmp/xe-crash-$(date +%F).log
journalctl -b -1 -k | grep -iE 'xe|drm|freezing' >> /tmp/xe-crash-$(date +%F).log
```

File upstream against the kernel `drm/xe` subsystem or the Arch bug tracker.
