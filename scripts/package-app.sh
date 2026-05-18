#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/TunnelBar.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
VERSION="${VERSION:-0.1.6}"
BUILD_NUMBER="${BUILD_NUMBER:-7}"
SPARKLE_FRAMEWORK_SRC="$ROOT_DIR/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"

swift build -c release --arch arm64 --arch x86_64 --package-path "$ROOT_DIR"
swift "$ROOT_DIR/scripts/generate-app-icon.swift"
"$ROOT_DIR/scripts/verify-cloudflared.sh"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$FRAMEWORKS_DIR"

cp "$ROOT_DIR/.build/apple/Products/Release/TunnelBar" "$MACOS_DIR/TunnelBar"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_DIR/TunnelBar" 2>/dev/null || true
cp "$ROOT_DIR/Assets/TunnelBarIcon.icns" "$RESOURCES_DIR/TunnelBarIcon.icns"

if [[ ! -d "$SPARKLE_FRAMEWORK_SRC" ]]; then
  echo "Missing Sparkle framework: $SPARKLE_FRAMEWORK_SRC" >&2
  echo "Run swift package resolve first." >&2
  exit 1
fi

ditto "$SPARKLE_FRAMEWORK_SRC" "$FRAMEWORKS_DIR/Sparkle.framework"

cp "$ROOT_DIR/Vendor/cloudflared-arm64" "$RESOURCES_DIR/cloudflared-arm64"
chmod 755 "$RESOURCES_DIR/cloudflared-arm64"

cp "$ROOT_DIR/Vendor/cloudflared-amd64" "$RESOURCES_DIR/cloudflared-amd64"
chmod 755 "$RESOURCES_DIR/cloudflared-amd64"

cp "$ROOT_DIR/Vendor/cloudflared-release.txt" "$RESOURCES_DIR/cloudflared-release.txt"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
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
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>SUEnableAutomaticChecks</key>
  <true/>
  <key>SUAutomaticallyUpdate</key>
  <true/>
  <key>SUFeedURL</key>
  <string>https://tunnelbar.dev/appcast.xml</string>
  <key>SUPublicEDKey</key>
  <string>xYTSaiVK9ZMuZ0ic0rUDKwdJJaIrPExF/dLbzbtbA+4=</string>
</dict>
</plist>
PLIST

echo "Created $APP_DIR"
