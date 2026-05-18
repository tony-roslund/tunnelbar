// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TunnelBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TunnelBar", targets: ["TunnelBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.2")
    ],
    targets: [
        .executableTarget(
            name: "TunnelBar",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/TunnelBar"
        ),
        .testTarget(
            name: "TunnelBarTests",
            dependencies: ["TunnelBar"],
            path: "Tests/TunnelBarTests"
        )
    ]
)
