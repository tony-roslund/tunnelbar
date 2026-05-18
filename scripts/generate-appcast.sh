#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1.5}"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/.build/TunnelBar-$VERSION.dmg}"
APPCAST_DIR="$ROOT_DIR/.build/appcast"
SPARKLE_ACCOUNT="${SPARKLE_ACCOUNT:-tunnelbar}"
SPARKLE_BIN="$ROOT_DIR/.build/artifacts/sparkle/Sparkle/bin/generate_appcast"
DOWNLOAD_URL_PREFIX="${DOWNLOAD_URL_PREFIX:-https://github.com/tony-roslund/tunnelbar/releases/download/v$VERSION/}"
APPCAST_OUTPUT="$ROOT_DIR/site/public/appcast.xml"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "Missing DMG: $DMG_PATH" >&2
  echo "Run scripts/release-build.sh first." >&2
  exit 1
fi

if [[ ! -x "$SPARKLE_BIN" ]]; then
  echo "Missing Sparkle generate_appcast tool: $SPARKLE_BIN" >&2
  echo "Run swift package resolve first." >&2
  exit 1
fi

rm -rf "$APPCAST_DIR"
mkdir -p "$APPCAST_DIR"

cp "$DMG_PATH" "$APPCAST_DIR/"

"$SPARKLE_BIN" \
  --account "$SPARKLE_ACCOUNT" \
  --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
  --maximum-versions 1 \
  "$APPCAST_DIR"

cp "$APPCAST_DIR/appcast.xml" "$APPCAST_OUTPUT"

echo "Generated $APPCAST_OUTPUT"
