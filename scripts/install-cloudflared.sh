#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/Vendor"
VERSION="${CLOUDFLARED_VERSION:-}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
RELEASE_JSON="$TMP_DIR/release.json"

if [[ -z "$VERSION" ]]; then
  curl -fsSL https://api.github.com/repos/cloudflare/cloudflared/releases/latest -o "$RELEASE_JSON"
  VERSION="$(node -e 'const fs = require("fs"); const release = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); console.log(release.tag_name || "");' "$RELEASE_JSON")"
else
  curl -fsSL "https://api.github.com/repos/cloudflare/cloudflared/releases/tags/$VERSION" -o "$RELEASE_JSON"
fi

if [[ -z "$VERSION" || "$VERSION" == "latest" ]]; then
  echo "Could not resolve cloudflared release version." >&2
  exit 1
fi

BASE_URL="https://github.com/cloudflare/cloudflared/releases/download/$VERSION"

mkdir -p "$VENDOR_DIR"

CHECKSUMS_FILE="$VENDOR_DIR/cloudflared-release-checksums.txt"
node -e '
  const fs = require("fs");
  const release = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const lines = release.assets
    .filter((asset) => /^cloudflared-.+/.test(asset.name) && /^sha256:[a-f0-9]{64}$/.test(asset.digest || ""))
    .map((asset) => `${asset.name}: ${asset.digest.replace(/^sha256:/, "")}`);
  if (lines.length === 0) {
    throw new Error("No SHA256 asset digests found in release metadata");
  }
  fs.writeFileSync(process.argv[2], `${lines.join("\n")}\n`);
' "$RELEASE_JSON" "$CHECKSUMS_FILE"

checksum_for() {
  local file="$1"
  awk -F ': ' -v file="$file" '$1 == file { print $2 }' "$CHECKSUMS_FILE"
}

download_arch() {
  local arch="$1"
  local archive="cloudflared-darwin-$arch.tgz"
  local archive_path="$TMP_DIR/$archive"
  local extract_dir="$TMP_DIR/extract-$arch"
  local expected
  local actual
  local binary_path

  expected="$(checksum_for "$archive")"
  if [[ -z "$expected" ]]; then
    echo "Could not find checksum for $archive in $CHECKSUMS_FILE" >&2
    exit 1
  fi

  curl -fsSL "$BASE_URL/$archive" -o "$archive_path"
  actual="$(shasum -a 256 "$archive_path" | awk '{ print $1 }')"

  if [[ "$actual" != "$expected" ]]; then
    echo "Checksum mismatch for $archive" >&2
    echo "Expected: $expected" >&2
    echo "Actual:   $actual" >&2
    exit 1
  fi

  mkdir -p "$extract_dir"
  tar -xzf "$archive_path" -C "$extract_dir"

  binary_path="$(find "$extract_dir" -type f -name cloudflared -print -quit)"
  if [[ -z "$binary_path" ]]; then
    echo "Could not find cloudflared binary in $archive" >&2
    exit 1
  fi

  cp "$binary_path" "$VENDOR_DIR/cloudflared-$arch"
  chmod 755 "$VENDOR_DIR/cloudflared-$arch"
}

download_arch arm64
download_arch amd64

printf '%s\n' "$VERSION" > "$VENDOR_DIR/cloudflared-release.txt"

(
  cd "$VENDOR_DIR"
  shasum -a 256 cloudflared-arm64 cloudflared-amd64 > cloudflared-binaries.sha256
)

"$ROOT_DIR/scripts/verify-cloudflared.sh"

echo "Installed cloudflared $VERSION into $VENDOR_DIR"
