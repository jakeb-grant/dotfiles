#!/bin/bash
# The Thunderbolt controllers on this laptop wake from sleep wedged, and a dock's
# USB hubs with them. thunderbolt-resume.service resets them after each resume:
# the controllers are removed and found again, then each device bolt has let in
# is let out and back in, a replug that brings its hubs back. A device bolt has
# not let in stays out, so the launcher's Thunderbolt page asks for it.
# (Taken over from hyprpier's resume service, which let every device back in.)
# Runs again whenever this file changes.
set -e
echo "Installing thunderbolt-resume.service. This requires sudo."

sudo mkdir -p /usr/local/libexec
cat <<'EOF' | sudo tee /usr/local/libexec/thunderbolt-resume > /dev/null
#!/bin/sh
# thunderbolt-resume: reset the Thunderbolt controllers after a resume, then
# replug each device bolt let in (installed by chezmoi's
# run_onchange_after_setup-thunderbolt-resume.sh; SYS is for its test).
SYS=${SYS:-/sys}
for pci in "$SYS"/bus/pci/devices/*; do
  drv=$(readlink "$pci/driver" 2>/dev/null); drv=${drv##*/}
  if [ "$drv" = thunderbolt ] || [ "$(cat "$pci/class" 2>/dev/null)" = 0x0c0340 ]; then
    echo 1 > "$pci/remove" 2>/dev/null || true
  fi
done
sleep 1
echo 1 > "$SYS/bus/pci/rescan"
i=0
while ! ls "$SYS"/bus/thunderbolt/devices/[0-9]-0 >/dev/null 2>&1 && [ $i -lt 15 ]; do
  sleep 1; i=$((i + 1))
done
sleep 2   # bolt lets in what it has stored meanwhile
for dev in "$SYS"/bus/thunderbolt/devices/[0-9]-[1-9]*; do
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
