#!/bin/bash
# The Thunderbolt controllers on this laptop wake from sleep wedged, and a dock's
# USB hubs with them. thunderbolt-resume.service resets them after each resume:
# the controllers are removed and found again, then each device bolt has let in
# is let out and back in, a replug that brings its hubs back, once bolt has let
# back in every stored device that was plugged in (it waits for bolt, up to
# 30 s, not a fixed time). A device bolt has not let in stays out, so the
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
  done
}
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
# training, later on a slow resume or a daisy chain: wait for every one plugged
# in before, and any other stored one found meanwhile (30 s at most)
i=0
while [ $i -lt 30 ]; do
  late=""
  for u in $before $(stored); do back_in "$u" || late="$late $u"; done
  [ -z "$late" ] && break
  sleep 1; i=$((i + 1))
done
[ -n "$late" ] && echo "thunderbolt-resume: not let back in:$late" >&2
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
