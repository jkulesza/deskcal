#!/bin/bash
# Packages dist/DeskCal.app into dist/DeskCal-<version>.dmg with an /Applications shortcut.
# Usage: scripts/make-dmg.sh [version]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-0.0.0}"
STAGING="dist/dmg-staging"
DMG="dist/DeskCal-$VERSION.dmg"

[[ -d dist/DeskCal.app ]] || { echo "error: dist/DeskCal.app not found; run scripts/make-app.sh first" >&2; exit 1; }

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R dist/DeskCal.app "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "DeskCal" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
rm -rf "$STAGING"

echo "Created $DMG"
