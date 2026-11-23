#!/usr/bin/env bash
# Usage: bench-open.sh <binary> <app> [path]
#   app: loaf | nautilus
# Times spawn -> window with the folder's name is mapped (polled through the
# niri compositor IPC every 10 ms), prints the milliseconds, then closes the
# app again so the next run measures a cold start.
#
# The killer detail: loaf is single-instance. If any loaf window is open,
# a new `loaf <path>` just hands the path to it and exits. --new-window
# bypasses the handoff; the pre-kill below removes the instance anyway.
set -euo pipefail

bin=$1
app=$2
path=${3:-$HOME/loaf-bench/big}
base=$(basename "$path")

# 1. Clean state: no instances, no matching windows left over.
case "$app" in
    loaf)     pkill -x loaf 2>/dev/null || true ;;
    nautilus) nautilus -q 2>/dev/null || true ;;
esac
for i in $(seq 1 50); do
    n=$(niri msg --json windows 2>/dev/null \
        | jq --arg t "$base" '[.[] | select(.title | contains($t))] | length')
    [ "${n:-0}" -eq 0 ] && break
    sleep 0.1
done
sleep 0.2

# 2. Spawn and poll until a window titled with the folder shows up.
start=$(date +%s%N)
case "$app" in
    loaf)     "$bin" --new-window "$path" >/dev/null 2>&1 & ;;
    nautilus) "$bin" --new-window "$path" >/dev/null 2>&1 & ;;
esac
child=$!
deadline=$(( start + 15 * 1000000000 ))
found=0
while [ "$(date +%s%N)" -lt "$deadline" ]; do
    if niri msg --json windows 2>/dev/null \
        | jq -e --arg t "$base" 'any(.[]; .title | contains($t))' >/dev/null; then
        found=1
        break
    fi
    sleep 0.01
done
end=$(date +%s%N)

if [ "$found" -eq 1 ]; then
    echo "$(( (end - start) / 1000000 ))"
else
    echo "TIMEOUT" >&2
fi

# 3. Close it again (bench-ready for the next iteration).
case "$app" in
    loaf)     pkill -x loaf 2>/dev/null || true ;;
    nautilus) nautilus -q 2>/dev/null || true ;;
esac
sleep 0.3
[ "$found" -eq 1 ]
