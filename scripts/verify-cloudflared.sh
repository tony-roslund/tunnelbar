#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Vendor"
CHECKSUM_FILE="$VENDOR_DIR/cloudflared-binaries.sha256"

if [[ ! -d "$VENDOR_DIR" ]]; then
  echo "Missing Vendor/. Run scripts/install-cloudflared.sh first." >&2
  exit 1
fi

for arch in arm64 amd64; do
  binary="$VENDOR_DIR/cloudflared-$arch"
  if [[ ! -f "$binary" ]]; then
    echo "Missing $binary. Run scripts/install-cloudflared.sh first." >&2
    exit 1
  fi

  if [[ ! -x "$binary" ]]; then
    echo "$binary is not executable." >&2
    exit 1
  fi
done

if [[ ! -f "$CHECKSUM_FILE" ]]; then
  echo "Missing $CHECKSUM_FILE. Run scripts/install-cloudflared.sh first." >&2
  exit 1
fi

(
  cd "$VENDOR_DIR"
  shasum -a 256 -c "$(basename "$CHECKSUM_FILE")"
)

if [[ -f "$VENDOR_DIR/cloudflared-release.txt" ]]; then
  echo "Verified cloudflared $(cat "$VENDOR_DIR/cloudflared-release.txt")"
else
  echo "Verified cloudflared binaries"
fi
