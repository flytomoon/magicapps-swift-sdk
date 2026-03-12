# MagicAppsCloudSDK (Swift)

Official Swift SDK for the MagicApps platform. Supports iOS, macOS, watchOS, and tvOS.

## Installation

### Swift Package Manager

Add the package dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/magicapps/magicapps-infra", from: "0.1.0")
]
```

Then add `MagicAppsCloudSDK` to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["MagicAppsCloudSDK"]
)
```

Or in Xcode: **File > Add Package Dependencies** and enter the repository URL.

## Quick Start

```swift
import MagicAppsCloudSDK

let config = SdkConfig(
    baseUrl: URL(string: "https://api.yourplatform.com")!,
    appId: "your-app-id"
)

let client = MagicAppsClient(config: config)

// Get app info
let appInfo = try await client.getAppInfo()
print(appInfo.name)

// List templates
let templates = try await client.listTemplates()
```

## Authentication

```swift
let config = SdkConfig(
    baseUrl: URL(string: "https://api.yourplatform.com")!,
    appId: "your-app-id",
    accessToken: "your-jwt-token",
    refreshToken: "your-refresh-token"
)

let client = MagicAppsClient(config: config)
```

The SDK automatically handles token refresh when a refresh token is provided.

## Error Handling

```swift
do {
    let appInfo = try await client.getAppInfo()
} catch let error as SdkError {
    switch error {
    case .unauthorized(let msg, _):
        print("Auth error: \(msg)")
    case .notFound(let msg, _):
        print("Not found: \(msg)")
    case .networkError(let msg, _):
        print("Network error: \(msg)")
    default:
        print("Error: \(error.description)")
    }
}
```

## Supported Platforms

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 16.0           |
| macOS    | 13.0           |
| watchOS  | 9.0            |
| tvOS     | 16.0           |

## License

MIT
