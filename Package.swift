// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "StreakKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "StreakKit",
            targets: ["StreakKit"]
        )
    ],
    targets: [
        .target(name: "StreakKit"),
        .testTarget(
            name: "StreakKitTests",
            dependencies: ["StreakKit"]
        )
    ],
    swiftLanguageModes: [.v6]
)
