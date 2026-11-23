#!/usr/bin/env bash
# Builds Oxygen Files from this code against the system Qt (output: target/release/loaf).
set -euo pipefail
cd "$(dirname "$0")"

missing=()
for c in cargo cmake ninja g++ pkg-config; do command -v "$c" >/dev/null || missing+=("$c"); done
[ -e /usr/lib64/cmake/Qt6Qml/Qt6QmlConfig.cmake ] || missing+=(qt6-devel)
# Loaf 0.4 compiles its translations with lrelease; release builds stop without it.
command -v lrelease >/dev/null || command -v lrelease-qt6 >/dev/null || command -v lrelease6 >/dev/null || missing+=(lrelease)
if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing: ${missing[*]}. On Fedora:" >&2
    echo "  sudo dnf install cargo rust cmake ninja-build gcc-c++ pkgconf-pkg-config qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtsvg-devel qt6-qtwayland-devel qt6-linguist" >&2
    exit 1
fi

cargo build --release
echo "Built: $PWD/target/release/loaf. ./install.sh will now install this build"
