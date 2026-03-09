// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MagicAppsSDK",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "MagicAppsSDK",
            targets: ["MagicAppsSDK"]
        ),
    ],
    targets: [
        .target(
            name: "MagicAppsSDK",
            path: "Sources/MagicAppsSDK"
        ),
        .testTarget(
            name: "MagicAppsSDKTests",
            dependencies: ["MagicAppsSDK"],
            path: "Tests/MagicAppsSDKTests"
        ),
    ]
)
