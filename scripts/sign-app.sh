#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${APP_DIR:-$ROOT_DIR/.build/TunnelBar.app}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

if [[ ! -d "$APP_DIR" ]]; then
  echo "Missing app bundle: $APP_DIR" >&2
  echo "Run scripts/package-app.sh first." >&2
  exit 1
fi

if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "Set SIGN_IDENTITY to a Developer ID Application certificate name or '-' for local ad-hoc signing." >&2
  echo >&2
  security find-identity -v -p codesigning >&2 || true
  exit 1
fi

if [[ -d "$APP_DIR/Contents/Frameworks/Sparkle.framework" ]]; then
  codesign --force --deep --timestamp --options runtime --sign "$SIGN_IDENTITY" "$APP_DIR/Contents/Frameworks/Sparkle.framework"
fi

codesign --force --timestamp --options runtime --sign "$SIGN_IDENTITY" "$APP_DIR/Contents/Resources/cloudflared-arm64"
codesign --force --timestamp --options runtime --sign "$SIGN_IDENTITY" "$APP_DIR/Contents/Resources/cloudflared-amd64"
codesign --force --timestamp --options runtime --sign "$SIGN_IDENTITY" "$APP_DIR"

codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "Signed $APP_DIR"
