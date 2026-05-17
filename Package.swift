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
    targets: [
        .executableTarget(
            name: "TunnelBar",
            path: "Sources/TunnelBar"
        ),
        .testTarget(
            name: "TunnelBarTests",
            dependencies: ["TunnelBar"],
            path: "Tests/TunnelBarTests"
        )
    ]
)
