// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "StreakKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
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
