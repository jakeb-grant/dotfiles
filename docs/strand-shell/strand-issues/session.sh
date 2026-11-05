#!/usr/bin/env bash
# In the container: headless sway, strand on the issue's config, then its check.py.
set -uo pipefail
WORK=$1; BIN=$2
export XDG_RUNTIME_DIR=$(mktemp -d); chmod 700 "$XDG_RUNTIME_DIR"
export HOME=$WORK/home XDG_CONFIG_HOME=$WORK XDG_STATE_HOME=$WORK/state XDG_CACHE_HOME=$WORK/cache
export WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman
echo 'output HEADLESS-1 mode 800x400 scale 1 bg #4c566a solid_color' >"$XDG_RUNTIME_DIR/sway.conf"
export WORK BIN
exec dbus-run-session -- bash -c '
sway -c "$XDG_RUNTIME_DIR/sway.conf" >"$WORK/sway.log" 2>&1 &
for _ in $(seq 50); do ls "$XDG_RUNTIME_DIR"/wayland-[0-9] >/dev/null 2>&1 && break; sleep 0.1; done
export WAYLAND_DISPLAY=$(basename "$(ls "$XDG_RUNTIME_DIR"/wayland-[0-9] | head -1)")
export STRAND_SOCKET=$XDG_RUNTIME_DIR/s.sock
"$BIN" check >"$WORK/check.log" 2>&1; echo $? >"$WORK/check.code"
"$BIN" run >"$WORK/strand.log" 2>&1 &
sleep 3
grim -t ppm "$WORK/shot.ppm"
python3 "$WORK/check.py" "$WORK"
'
