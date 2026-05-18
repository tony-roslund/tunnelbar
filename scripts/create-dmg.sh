#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${APP_DIR:-$ROOT_DIR/.build/TunnelBar.app}"
VERSION="${VERSION:-0.1.4}"
STAGING_DIR="$ROOT_DIR/.build/dmg"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/.build/TunnelBar-$VERSION.dmg}"

if [[ ! -d "$APP_DIR" ]]; then
  echo "Missing app bundle: $APP_DIR" >&2
  echo "Run scripts/package-app.sh first." >&2
  exit 1
fi

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

ditto "$APP_DIR" "$STAGING_DIR/TunnelBar.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "TunnelBar" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Created $DMG_PATH"
