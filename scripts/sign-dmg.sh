#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1.9}"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/.build/TunnelBar-$VERSION.dmg}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "Set SIGN_IDENTITY to sign the DMG." >&2
  exit 1
fi

if [[ ! -f "$DMG_PATH" ]]; then
  echo "Missing DMG: $DMG_PATH" >&2
  echo "Run scripts/create-dmg.sh first." >&2
  exit 1
fi

codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"

echo "Signed $DMG_PATH"
