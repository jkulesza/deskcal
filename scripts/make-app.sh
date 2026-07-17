#!/bin/bash
# Assembles dist/DeskCal.app from the release binary built by SwiftPM.
# Usage: scripts/make-app.sh [version]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-0.0.0}"
APP="dist/DeskCal.app"

# Universal builds land in .build/apple/Products/Release, single-arch in .build/release.
if [[ -x .build/apple/Products/Release/DeskCal ]]; then
    BIN=.build/apple/Products/Release/DeskCal
elif [[ -x .build/release/DeskCal ]]; then
    BIN=.build/release/DeskCal
else
    echo "error: no release binary found; run 'swift build -c release' first" >&2
    exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/DeskCal"
sed "s/__VERSION__/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "Assembled $APP (version $VERSION, $(lipo -archs "$APP/Contents/MacOS/DeskCal" 2>/dev/null || echo unknown))"
