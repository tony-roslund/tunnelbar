import AppKit
import Foundation

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetsURL = rootURL.appendingPathComponent("Assets", isDirectory: true)
let iconsetURL = assetsURL.appendingPathComponent("TunnelBarIcon.iconset", isDirectory: true)
let icnsURL = assetsURL.appendingPathComponent("TunnelBarIcon.icns")
let publicIconURL = assetsURL.appendingPathComponent("TunnelBarIcon.png")
let publicSVGURL = assetsURL.appendingPathComponent("TunnelBarIcon.svg")
let sitePublicURL = rootURL.appendingPathComponent("site/public", isDirectory: true)

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: sitePublicURL, withIntermediateDirectories: true)

let sizes: [(name: String, points: Int, scale: Int)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2),
]

let lime = NSColor(red: 0.847, green: 1.0, blue: 0.373, alpha: 1.0)
let ink = NSColor(red: 0.047, green: 0.051, blue: 0.043, alpha: 1.0)

func renderIcon(pixels: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "TunnelBarIcon", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Could not create \(pixels)x\(pixels) bitmap",
        ])
    }

    bitmap.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()

    let padding = CGFloat(pixels) * 0.11
    let iconRect = NSRect(
        x: padding,
        y: padding,
        width: CGFloat(pixels) - padding * 2,
        height: CGFloat(pixels) - padding * 2
    )
    let radius = CGFloat(pixels) * 0.18

    lime.setFill()
    NSBezierPath(roundedRect: iconRect, xRadius: radius, yRadius: radius).fill()

    let glyph = ">_"
    let fontSize = CGFloat(pixels) * 0.34
    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .semibold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: ink,
        .kern: -CGFloat(pixels) * 0.015,
    ]
    let glyphSize = glyph.size(withAttributes: attributes)
    let glyphRect = NSRect(
        x: (CGFloat(pixels) - glyphSize.width) / 2,
        y: (CGFloat(pixels) - glyphSize.height) / 2 + CGFloat(pixels) * 0.015,
        width: glyphSize.width,
        height: glyphSize.height
    )
    glyph.draw(in: glyphRect, withAttributes: attributes)

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "TunnelBarIcon", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Could not render \(pixels)x\(pixels)",
        ])
    }

    return pngData
}

func writeIconSVG(to url: URL) throws {
    let svg = """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
      <rect x="112" y="112" width="800" height="800" rx="184" fill="#D8FF5F"/>
      <text x="512" y="590" text-anchor="middle" font-family="ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace" font-size="348" font-weight="700" letter-spacing="-15" fill="#0C0D0B">&gt;_</text>
    </svg>
    """

    try svg.write(to: url, atomically: true, encoding: .utf8)
}

for size in sizes {
    let pixels = size.points * size.scale
    let pngData = try renderIcon(pixels: pixels)
    try pngData.write(to: iconsetURL.appendingPathComponent(size.name))
}

try renderIcon(pixels: 1024).write(to: publicIconURL)
try renderIcon(pixels: 512).write(to: sitePublicURL.appendingPathComponent("tunnelbar-icon.png"))
try renderIcon(pixels: 180).write(to: sitePublicURL.appendingPathComponent("apple-touch-icon.png"))
try renderIcon(pixels: 32).write(to: sitePublicURL.appendingPathComponent("favicon-32x32.png"))
try renderIcon(pixels: 16).write(to: sitePublicURL.appendingPathComponent("favicon-16x16.png"))
try writeIconSVG(to: publicSVGURL)
try writeIconSVG(to: sitePublicURL.appendingPathComponent("tunnelbar-icon.svg"))
try writeIconSVG(to: sitePublicURL.appendingPathComponent("favicon.svg"))

if FileManager.default.fileExists(atPath: icnsURL.path) {
    try FileManager.default.removeItem(at: icnsURL)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "TunnelBarIcon", code: Int(process.terminationStatus), userInfo: [
        NSLocalizedDescriptionKey: "iconutil failed with status \(process.terminationStatus)",
    ])
}

print("Created \(icnsURL.path)")
print("Created \(publicIconURL.path)")
print("Created \(sitePublicURL.path)/favicon.svg")
