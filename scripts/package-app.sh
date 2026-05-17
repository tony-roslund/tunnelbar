#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/TunnelBar.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

swift build -c release --package-path "$ROOT_DIR"
swift "$ROOT_DIR/scripts/generate-app-icon.swift"
"$ROOT_DIR/scripts/verify-cloudflared.sh"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/release/TunnelBar" "$MACOS_DIR/TunnelBar"
cp "$ROOT_DIR/Assets/TunnelBarIcon.icns" "$RESOURCES_DIR/TunnelBarIcon.icns"

cp "$ROOT_DIR/Vendor/cloudflared-arm64" "$RESOURCES_DIR/cloudflared-arm64"
chmod 755 "$RESOURCES_DIR/cloudflared-arm64"

cp "$ROOT_DIR/Vendor/cloudflared-amd64" "$RESOURCES_DIR/cloudflared-amd64"
chmod 755 "$RESOURCES_DIR/cloudflared-amd64"

cp "$ROOT_DIR/Vendor/cloudflared-release.txt" "$RESOURCES_DIR/cloudflared-release.txt"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>TunnelBar</string>
  <key>CFBundleIconFile</key>
  <string>TunnelBarIcon</string>
  <key>CFBundleIdentifier</key>
  <string>com.tonyroslund.tunnelbar</string>
  <key>CFBundleName</key>
  <string>TunnelBar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "Created $APP_DIR"
