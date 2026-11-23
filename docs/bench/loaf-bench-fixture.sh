#!/usr/bin/env bash
# Creates ~/loaf-bench/big with ~12k entries:
#   - 4000 valid 1x1 PNGs (digit-heavy names, exercise thumbnails + natural sort)
#   - 6000 ".jpg.txt" files (look image-ish in the name, are plain text)
#   - 1000 Cyrillic names, 1000 digit-leading reports, 20 subfolders
# Real disk (home), not /tmp (often tmpfs = unrealistically fast IO).
# Delete the folder when you are done: rm -rf ~/loaf-bench
set -euo pipefail
dest="$HOME/loaf-bench/big"
mkdir -p "$dest"
python3 - "$dest" <<'EOF'
import base64, sys
dest = sys.argv[1]
# Valid 1x1 transparent PNG -> thumbnailers succeed and cache it.
png = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")
for i in range(4000):
    with open(f"{dest}/photo_{i:05}.png", "wb") as f:
        f.write(png)
for i in range(6000):
    open(f"{dest}/IMG_2026-01-{i % 28 + 1:02}_{i % 9000:04}.jpg.txt", "w").close()
for i in range(1000):
    open(f"{dest}/папка_заметка_{i}.txt", "w").close()
for i in range(1000):
    open(f"{dest}/{i % 97}-report-{i}.md", "w").close()
EOF
for i in $(seq 1 20); do
    mkdir -p "$dest/sub$i"
    touch "$dest/sub$i/inner$i.txt"
done
echo "fixture ready: $(ls -1 "$dest" | wc -l) entries in $dest"
