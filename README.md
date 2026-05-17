# TunnelBar

TunnelBar is a native macOS menu bar app for creating temporary public URLs for local development servers with Cloudflare quick tunnels.

## Current Implementation

- SwiftUI/AppKit menu bar shell.
- Local URL validation for `http://localhost:<port>` and `http://127.0.0.1:<port>`.
- Origin extraction and path/query/fragment reattachment.
- `cloudflared tunnel --url <origin>` process lifecycle.
- Quick tunnel URL parsing from `cloudflared` output.
- Clipboard copy, stop control, diagnostics log, and local recent history.
- Bundled Apple Silicon and Intel `cloudflared` binaries with checksum verification.
- `localhost` inputs are tunneled through `127.0.0.1` internally to avoid macOS IPv4/IPv6 port collisions while preserving the original URL for display and route composition.

## Run Locally

```sh
swift run TunnelBar
```

During development, TunnelBar uses a bundled `cloudflared-arm64`/`cloudflared-amd64` resource when present, then falls back to `cloudflared` on `PATH`.

## Vendor cloudflared

```sh
scripts/install-cloudflared.sh
```

By default this installs the latest `cloudflared` GitHub release into `Vendor/`. Set `CLOUDFLARED_VERSION=2026.5.0` to pin a specific release.

## Package

```sh
scripts/package-app.sh
```

Packaging verifies the vendored `cloudflared` checksums before creating `.build/TunnelBar.app`.

## Test

```sh
swift test
```
