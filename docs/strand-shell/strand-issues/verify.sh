#!/usr/bin/env bash
# verify.sh <issue-folder> <strand-checkout> [strand-binary]: runs an issue's
# reproduction in Strand's CI container, on a headless sway. It never touches a
# desktop session. The binary is a path inside the checkout, by default
# target/container/debug/strand (scripts/container/run.sh cargo build -p strand).
#
# Exit: 0 fixed, 1 the bug is still there, 2 the check itself could not run.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
[ $# -ge 2 ] || { sed -n 2,7p "$0" >&2; exit 2; }
ISSUE=$(cd "$1" && pwd); ROOT=$(cd "$2" && pwd); BIN=${3:-target/container/debug/strand}
[ -x "$ROOT/$BIN" ] || { echo "no binary at $ROOT/$BIN" >&2; exit 2; }
# Only the checkout is visible in the container.
WORK=$ROOT/target/issue-repro/$(basename "$ISSUE")
rm -rf "${WORK:?}"; mkdir -p "$WORK"
cp -r "$ISSUE/." "$WORK/"; cp "$HERE/session.sh" "$WORK/session.sh"
# The checkout's commit is the binary's only if it was built from it: compare the times.
echo "checkout: $(git -C "$ROOT" log -1 --format='%h, committed %ad' --date=iso)$(git -C "$ROOT" diff --quiet HEAD || echo ', with uncommitted changes')"
echo "binary:   $BIN, built $(date -d "@$(stat -c %Y "$ROOT/$BIN")" '+%Y-%m-%d %H:%M:%S %z')"
cd "$ROOT"
exec scripts/container/run.sh bash "$WORK/session.sh" "$WORK" "$ROOT/$BIN"
