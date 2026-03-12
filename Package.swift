// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MagicAppsCloudSDK",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "MagicAppsCloudSDK",
            targets: ["MagicAppsCloudSDK"]
        ),
    ],
    targets: [
        .target(
            name: "MagicAppsCloudSDK"
        ),
        .testTarget(
            name: "MagicAppsCloudSDKTests",
            dependencies: ["MagicAppsCloudSDK"]
        ),
    ]
)
