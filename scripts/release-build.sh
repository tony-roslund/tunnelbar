#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/scripts/package-app.sh"

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  "$ROOT_DIR/scripts/sign-app.sh"
else
  echo "Skipping code signing because SIGN_IDENTITY is not set."
fi

"$ROOT_DIR/scripts/create-dmg.sh"

if [[ -n "${NOTARYTOOL_PROFILE:-}" || ( -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ) ]]; then
  "$ROOT_DIR/scripts/notarize-dmg.sh"
else
  echo "Skipping notarization because notary credentials are not set."
fi
