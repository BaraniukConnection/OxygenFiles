#!/usr/bin/env bash
# Usage: bench-scroll.sh <binary> <app> [path] [key-presses]
#   app: loaf | nautilus
# Opens the app on the folder, focuses the window (via niri IPC), presses
# Down N times (keyboard scrolling through the view), and reports wall time,
# CPU seconds consumed by the app during the interaction, and RSS before/after.
# Kills the app afterwards.
#
# Safety: keys are only sent after the compositor confirms the bench window
# is focused; otherwise the script aborts without touching the keyboard.
set -euo pipefail
bin=$1
app=$2
path=${3:-$HOME/loaf-bench/big}
keys=${4:-300}
base=$(basename "$path")

case "$app" in
    loaf)     pkill -x loaf 2>/dev/null || true ;;
    nautilus) nautilus -q 2>/dev/null || true ;;
esac
sleep 0.3

"$bin" --new-window "$path" >/dev/null 2>&1 &
deadline=$(( $(date +%s%N) + 15 * 1000000000 ))
found=0
while [ "$(date +%s%N)" -lt "$deadline" ]; do
    if niri msg --json windows 2>/dev/null \
        | jq -e --arg t "$base" 'any(.[]; .title | contains($t))' >/dev/null; then
        found=1; break
    fi
    sleep 0.01
done
[ "$found" -eq 1 ] || { echo "window never appeared" >&2; exit 1; }
sleep 0.5   # grid settle

info=$(niri msg --json windows 2>/dev/null \
    | jq -c --arg t "$base" '[.[] | select(.title | contains($t))][0]')
id=$(jq -r '.id' <<<"$info")
pid=$(jq -r '.pid' <<<"$info")

niri msg action focus-window --id "$id" >/dev/null
sleep 0.2
focused=$(niri msg --json windows 2>/dev/null \
    | jq -r --argjson id "$id" '.[] | select(.id == $id) | .is_focused')
if [ "$focused" != "true" ]; then
    echo "could not focus the bench window - no keys sent" >&2
    kill "$pid" 2>/dev/null || true
    exit 1
fi

read -r ut1 st1 <<< "$(awk '{print $14, $15}' "/proc/$pid/stat")"
rss1=$(awk '/VmRSS/{print $2}' "/proc/$pid/status")

t0=$(date +%s%N)
for ((i = 0; i < keys; i++)); do
    ydotool key 108:1 108:0
    sleep 0.012
done
t1=$(date +%s%N)

read -r ut2 st2 <<< "$(awk '{print $14, $15}' "/proc/$pid/stat")"
rss2=$(awk '/VmRSS/{print $2}' "/proc/$pid/status")

awk -v app="$app" -v keys="$keys" \
    -v wall=$(( (t1 - t0) / 1000000 )) \
    -v cpu=$(( (ut2 + st2) - (ut1 + st1) )) \
    -v r1="$rss1" -v r2="$rss2" \
    'BEGIN { printf "%s: %d keys in %d ms, cpu %d ms, rss %d -> %d kB\n", app, keys, wall, cpu, r1, r2 }'

case "$app" in
    loaf)     pkill -x loaf 2>/dev/null || true ;;
    nautilus) nautilus -q 2>/dev/null || true ;;
esac
sleep 0.3
