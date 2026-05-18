# TunnelBar

TunnelBar is a native macOS menu bar app for turning localhost URLs into temporary public tunnel links.

Paste a local URL like `http://localhost:3000/share/review`, start a tunnel, and TunnelBar copies a public URL that keeps the same route. Active tunnels stay visible in the menu bar and stop when you stop them or quit the app.

## Status

TunnelBar is early v1 software.

The source is public and source-available, but this is not an open-source project in the OSI sense because commercial use is restricted. See [License](#license).

## Download

Signed and notarized Mac downloads will be published from GitHub Releases.

You can also build TunnelBar locally from source.

## Features

- Native SwiftUI/AppKit menu bar app.
- Local URL validation for `http://localhost:<port>` and `http://127.0.0.1:<port>`.
- Origin extraction with path, query, and fragment reattachment.
- Multiple simultaneous active tunnels, with one active tunnel per local origin.
- Public URL copy after the tunnel URL is reachable.
- Local server preflight before starting a tunnel.
- Public-DNS-first quick tunnel verification to avoid local DNS cache misses.
- Compact active tunnel controls for copy and stop.
- Diagnostics log for captured `cloudflared` output.
- Bundled Apple Silicon and Intel `cloudflared` binaries during packaged builds.

## Tunnel Availability

TunnelBar uses account-less Cloudflare Quick Tunnels for local development previews. Cloudflare describes Quick Tunnels as a way to experiment without an account and notes that they are for testing and development, not production.

Cloudflare does not provide an uptime guarantee or SLA for account-less Quick Tunnels. Cloudflare also documents current Quick Tunnel limits, including a 200 concurrent in-flight request limit and no Server-Sent Events support.

TunnelBar does not control Cloudflare's service availability, limits, or terms. Review Cloudflare's [Quick Tunnel docs](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/) and [Website and Online Services Terms](https://www.cloudflare.com/policies/terms/) before relying on the generated URLs. If you need production reliability, use a named Cloudflare Tunnel in your own Cloudflare account instead of an account-less Quick Tunnel.

## Run Locally

```sh
swift run TunnelBar
```

During development, TunnelBar uses bundled `cloudflared-arm64` / `cloudflared-amd64` resources when present, then falls back to `cloudflared` on `PATH`.

## Vendor cloudflared

```sh
scripts/install-cloudflared.sh
```

By default this installs the latest `cloudflared` GitHub release into `Vendor/`. Set `CLOUDFLARED_VERSION=2026.5.0` to pin a specific release.

## Package

```sh
scripts/package-app.sh
```

Packaging verifies vendored `cloudflared` checksums before creating `.build/TunnelBar.app`.

## Release Build

```sh
scripts/release-build.sh
```

By default this packages the app and creates `.build/TunnelBar-0.1.9.dmg`. It skips signing and notarization unless credentials are configured.

For a Developer ID release:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/release-build.sh
```

For signing and notarization, use a stored notarytool profile:

```sh
NOTARYTOOL_PROFILE="tunnelbar" SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/release-build.sh
```

Or set `APPLE_ID`, `APPLE_TEAM_ID`, and `APPLE_APP_SPECIFIC_PASSWORD`.

Individual release steps are also available:

```sh
scripts/sign-app.sh
scripts/create-dmg.sh
scripts/sign-dmg.sh
scripts/notarize-dmg.sh
```

## Test

```sh
swift test
```

## License

TunnelBar is source-available for noncommercial use under the [PolyForm Noncommercial License 1.0.0](LICENSE.md).

Commercial use, resale, paid redistribution, bundling TunnelBar into a commercial product, or offering TunnelBar as part of a paid service requires separate written permission. See [NOTICE.md](NOTICE.md) and [COMMERCIAL.md](COMMERCIAL.md).
