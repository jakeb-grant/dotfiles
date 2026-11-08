#!/bin/bash
# The Thunderbolt controllers on this laptop wake from sleep wedged, and a dock's
# USB hubs with them. thunderbolt-resume.service resets them after each resume:
# the controllers are removed and found again, then each device bolt has let in
# is let out and back in, a replug that brings its hubs back, once bolt has let
# back in every stored device it lets in by itself (policy not manual) that is
# plugged in, and the devices plugged in have held still for a second (it waits
# for bolt, up to 30 s, not a fixed time; one kept manual is not waited for, one
# unplugged while asleep 8 s at most). A device bolt has not let in stays out, so the
# launcher's Thunderbolt page asks for it.
# (Taken over from hyprpier's resume service, which let every device back in.)
# Runs again whenever this file changes.
set -e
echo "Installing thunderbolt-resume.service. This requires sudo."

sudo mkdir -p /usr/local/libexec
cat <<'EOF' | sudo tee /usr/local/libexec/thunderbolt-resume > /dev/null
#!/bin/sh
# thunderbolt-resume: reset the Thunderbolt controllers after a resume, then
# replug each device bolt let in (installed by chezmoi's
# run_onchange_after_setup-thunderbolt-resume.sh; SYS and BOLTDB are for its test).
SYS=${SYS:-/sys}
BOLTDB=${BOLTDB:-/var/lib/boltd/devices}
TB=$SYS/bus/thunderbolt/devices
# the devices plugged in that bolt has stored, by their ids
stored() {
  for d in "$TB"/[0-9]-[1-9]*; do
    u=$(cat "$d/unique_id" 2>/dev/null) && [ -e "$BOLTDB/$u" ] && echo "$u"
  done | sort -u | tr '\n' ' '
}
# auto: bolt lets the stored device with that id in by itself (its policy is
# auto, iommu or the default, written as no policy line; manual stays out)
auto() { ! grep -q '^policy=manual' "$BOLTDB/$1" 2>/dev/null; }
# back_in: the device with that id is there and let in
back_in() {
  for d in "$TB"/[0-9]-[1-9]*; do
    [ "$(cat "$d/unique_id" 2>/dev/null)" = "$1" ] && [ "$(cat "$d/authorized" 2>/dev/null)" = 1 ] && return 0
  done
  return 1
}
before=$(stored)
for pci in "$SYS"/bus/pci/devices/*; do
  drv=$(readlink "$pci/driver" 2>/dev/null); drv=${drv##*/}
  if [ "$drv" = thunderbolt ] || [ "$(cat "$pci/class" 2>/dev/null)" = 0x0c0340 ]; then
    echo 1 > "$pci/remove" 2>/dev/null || true
  fi
done
sleep 1
echo 1 > "$SYS/bus/pci/rescan"
# bolt lets each stored device back in once its router comes up, after link
# training, later on a slow resume or a daisy chain: wait until every stored
# device plugged in that bolt lets in by itself is back, and the stored devices
# plugged in are the same as a second ago (30 s at most). One plugged in before
# the sleep but not found again is waited for 8 s, then taken as unplugged
# while asleep.
i=0; last=-
while [ $i -lt 30 ]; do
  now=$(stored); late=""
  for u in $now; do auto "$u" && ! back_in "$u" && late="$late $u"; done
  if [ $i -lt 8 ]; then
    for u in $before; do
      case " $now " in *" $u "*) ;; *) auto "$u" && late="$late $u" ;; esac
    done
  fi
  [ -z "$late" ] && [ "$now" = "$last" ] && break
  last=$now; sleep 1; i=$((i + 1))
done
gone=""
for u in $before; do case " $now " in *" $u "*) ;; *) gone="$gone $u" ;; esac; done
[ -n "$late" ] && echo "thunderbolt-resume: not let back in:$late" >&2
[ -n "$gone" ] && echo "thunderbolt-resume: not plugged in after the resume:$gone" >&2
for dev in "$TB"/[0-9]-[1-9]*; do
  [ "$(cat "$dev/authorized" 2>/dev/null)" = 1 ] || continue
  echo 0 > "$dev/authorized" 2>/dev/null || true
  sleep 1
  echo 1 > "$dev/authorized" 2>/dev/null || true
done
EOF
sudo chmod 755 /usr/local/libexec/thunderbolt-resume

cat <<'EOF' | sudo tee /etc/systemd/system/thunderbolt-resume.service > /dev/null
[Unit]
Description=Reset the Thunderbolt controllers on resume, and replug what bolt let in
After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
TimeoutStartSec=60
ExecStart=/usr/local/libexec/thunderbolt-resume

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable thunderbolt-resume.service
echo "thunderbolt-resume.service installed."
