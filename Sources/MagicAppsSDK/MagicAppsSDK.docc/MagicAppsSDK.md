# ``MagicAppsSDK``

The official MagicApps SDK for Swift — provides authentication, registry,
payments, and platform service access for iOS, macOS, watchOS, and tvOS.

## Overview

MagicAppsSDK provides app_id-scoped API access with automatic authentication,
modular service plugins, and platform-conditional module availability.

```swift
let client = MagicAppsClient(config: SdkConfig(
    baseUrl: URL(string: "https://api.magicapps.dev")!,
    appId: "my-app"
))

let pong = try await client.ping()
```

## Topics

### Essentials

- ``MagicAppsClient``
- ``SdkConfig``

### Authentication

- ``AuthService``
- ``AppleAuthService``

### In-App Purchases

- ``AppleIapService``

### Services Architecture

- ``ServiceModule``
- ``ServiceRegistry``

### Errors

- ``SdkError``

### Deprecation

- ``DeprecationInfo``
- ``DeprecationRegistry``

### Network

- ``SdkHttpClient``
- ``TokenManager``
