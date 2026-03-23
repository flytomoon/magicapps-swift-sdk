# MagicAppsCloudSDK (Swift)

Official Swift SDK for the MagicApps Cloud platform. Provides tenant-scoped API access with automatic token management, modular service architecture, and platform-conditional module availability.

## Supported Platforms

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 16.0           |
| macOS    | 13.0           |
| watchOS  | 9.0            |
| tvOS     | 16.0           |

## Installation

### Swift Package Manager

Add the dependency in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/flytomoon/magicapps-swift-sdk", from: "0.3.0")
]
```

Add `MagicAppsCloudSDK` to your target:

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
    baseUrl: URL(string: "https://api.magicapps.dev")!,
    appId: "your-app-id"
)

let client = MagicAppsClient(config: config)

// Health check
let pong = try await client.ping()
print(pong.message)

// Get app info
let appInfo = try await client.getAppInfo()
print(appInfo.name)

// Fetch the device catalog
let devices = try await client.devices.getAll()

// Get templates
let catalog = try await client.templates.getCatalog()
```

## Services

All services are accessed as properties on `MagicAppsClient`. Services marked **(iOS only)** are restricted to Apple platforms via the service registry.

### Client

Top-level methods on `MagicAppsClient`:

```swift
func ping() async throws -> PingResponse
func getAppInfo() async throws -> AppInfo
```

### Auth (`client.auth`)

Core authentication: email/password, passkeys, email magic links, token refresh, and identity linking. Available on all platforms.

```swift
// Email/password
func register(email: String, password: String, name: String? = nil) async throws -> RegisterResponse
func login(email: String, password: String) async throws -> LoginResponse
func logout() async throws

// Token refresh
func refreshToken(_ refreshToken: String) async throws -> TokenRefreshResponse

// Identity linking
func linkProvider(provider: String, token: String) async throws -> LinkProviderResponse

// Passkey registration
func getPasskeyRegisterOptions() async throws -> PasskeyRegisterOptionsResponse
func verifyPasskeyRegistration(_ credential: PasskeyRegisterVerifyRequest) async throws -> PasskeyRegisterVerifyResponse

// Passkey authentication
func getPasskeyAuthOptions() async throws -> PasskeyAuthOptionsResponse
func verifyPasskeyAuth(_ assertion: PasskeyAuthVerifyRequest) async throws -> PasskeyAuthVerifyResponse

// Email magic link
func requestEmailMagicLink(email: String) async throws -> EmailMagicLinkResponse
func verifyEmailMagicLink(token: String) async throws -> EmailMagicLinkVerifyResponse
```

### Apple Auth (`client.appleAuth`) -- iOS only

Sign in with Apple token exchange.

```swift
func exchangeToken(_ request: AppleExchangeRequest) async throws -> AppleExchangeResponse
```

### Owner (`client.owner`)

Device-owner registration and migration to full user accounts. Available on all platforms.

```swift
func registerOwner(deviceOwnerId: String, appId: String, hcaptchaToken: String? = nil) async throws -> OwnerRegisterResponse
func migrateOwnerToUser(deviceOwnerId: String, appId: String) async throws -> OwnerMigrateResponse
```

### Settings (`client.settings`)

App settings, config, and integration secrets. Available on all platforms.

```swift
// Settings
func getSettings() async throws -> SettingsResponse
func updateSettings(_ body: [String: AnyCodable]) async throws -> SettingsResponse

// Config
func getConfig() async throws -> ConfigResponse
func updateConfig(_ body: [String: AnyCodable]) async throws -> ConfigResponse

// Integration secrets
func getIntegrationSecret(integrationId: String) async throws -> IntegrationSecretResponse
func uploadIntegrationSecret(integrationId: String, body: [String: AnyCodable]) async throws -> IntegrationSecretResponse
```

### Templates (`client.templates`)

Read-only access to templates and the app catalog. Available on all platforms.

```swift
func get(templateId: String) async throws -> Template
func getCatalog() async throws -> CatalogResponse
```

### Devices (`client.devices`)

Read-only access to the merged device catalog (hardcoded, catalog, and user-submitted). Available on all platforms.

```swift
func list() async throws -> DeviceCatalogResponse
func getAll() async throws -> [Device]
```

### Endpoints (`client.endpoints`)

Webhook endpoint management and event consumption. Available on all platforms.

```swift
func create() async throws -> CreateEndpointResponse
func revokeAndReplace(oldSlug: String) async throws -> RevokeAndReplaceResponse
func revoke(slug: String) async throws -> RevokeEndpointResponse
func postEvent(slug: String, payload: [String: AnyCodable], hmacSecret: String? = nil) async throws -> PostEventResponse
func consumeEvent(slug: String) async throws -> ConsumedEvent
```

### Lookup Tables (`client.lookupTables`)

Read-only access to lookup tables (reference data configured by tenant admins). Available on all platforms.

```swift
func list() async throws -> LookupTableListResponse
func get(lookupTableId: String) async throws -> LookupTableDetail
func getChunk(lookupTableId: String, chunkIndex: Int, version: Int? = nil) async throws -> [String: AnyCodable]
func getFullDataset(lookupTableId: String) async throws -> [String: AnyCodable]
```

### AI (`client.ai`)

AI proxy for chat completions, embeddings, image generation, and content moderation. Requests are routed through the tenant's configured provider (OpenAI, Anthropic, Google). Available on all platforms.

```swift
// Chat completions
func createChatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse
func chat(message: String, model: String? = nil) async throws -> ChatCompletionResponse

// Embeddings
func createEmbedding(_ request: EmbeddingRequest) async throws -> EmbeddingResponse
func embed(text: String, model: String? = nil) async throws -> EmbeddingResponse

// Image generation
func createImage(_ request: ImageGenerationRequest) async throws -> ImageGenerationResponse
func generateImage(prompt: String, size: String? = nil) async throws -> ImageGenerationResponse

// Content moderation
func createModeration(_ request: ModerationRequest) async throws -> ModerationResponse
func moderate(text: String) async throws -> ModerationResponse

```

### Apple IAP (`client.appleIap`) -- iOS only

Apple In-App Purchase verification, restore, entitlement checks, and client commerce configuration.

```swift
func verifyTransaction(_ request: IapVerifyRequest) async throws -> IapVerifyResponse
func verifyTransaction(transactionId: String, receiptData: String? = nil, productId: String? = nil) async throws -> IapVerifyResponse
func restorePurchases(transactionIds: [String]? = nil) async throws -> IapRestoreResponse
func getClientConfig() async throws -> ClientCommerceConfig
func checkEntitlement(transactionId: String, productId: String? = nil) async throws -> Entitlement?
```

## HMAC Utilities

Free functions for signing and verifying webhook event payloads. The signature is `HMAC-SHA256(secret, "slug:timestamp:body")`.

```swift
// Generate signature headers for posting a signed event
let headers = generateHmacSignature(
    slug: "my-slug",
    body: jsonBodyString,
    secret: endpointHmacSecret
)
// headers.signature  -- hex-encoded HMAC
// headers.timestamp  -- Unix timestamp string

// Verify an incoming webhook signature (constant-time comparison, clock skew check)
let valid = verifyHmacSignature(
    slug: "my-slug",
    body: rawBody,
    signature: request.header("X-Signature"),
    timestamp: request.header("X-Timestamp"),
    secret: endpointHmacSecret,
    maxSkewSeconds: 300  // default
)
```

## Token Management

The SDK manages three token types: **access token** (JWT), **refresh token**, and **owner token**. Tokens are persisted to the Keychain by default and survive app restarts.

```swift
// Provide tokens at initialization
let config = SdkConfig(
    baseUrl: URL(string: "https://api.magicapps.dev")!,
    appId: "your-app-id",
    accessToken: "jwt-token",
    refreshToken: "refresh-token",
    ownerToken: "owner-token"
)

// Update tokens at runtime
await client.setTokens(accessToken: "new-jwt", refreshToken: "new-refresh")

// Clear all tokens (logout)
await client.clearTokens()
// or equivalently:
await client.logout()
```

**Automatic refresh:** When a refresh token is available and the access token is expired (checked via JWT `exp` claim with a 30-second buffer), the SDK automatically refreshes before sending the request.

**Token storage backends:**
- `KeychainTokenStorage` (default) -- encrypted Keychain persistence
- `InMemoryTokenStorage` -- no persistence, tokens lost on app termination
- Custom -- conform to the `TokenStorage` protocol

**Callbacks:**

```swift
let config = SdkConfig(
    baseUrl: url,
    appId: "my-app",
    onTokenRefresh: { tokenPair in
        print("Tokens refreshed: \(tokenPair.accessToken)")
    },
    onAuthError: { error in
        print("Auth failed: \(error.description)")
    }
)
```

## Error Handling

All SDK methods throw `SdkError`, an enum with typed cases:

```swift
do {
    let appInfo = try await client.getAppInfo()
} catch let error as SdkError {
    switch error {
    case .unauthorized(let msg, let payload):
        // 401 -- token expired or missing
        print("Auth error: \(msg)")
    case .forbidden(let msg, _):
        // 403 -- insufficient permissions
        print("Forbidden: \(msg)")
    case .notFound(let msg, _):
        // 404
        print("Not found: \(msg)")
    case .rateLimited(let msg, _):
        // 429
        print("Rate limited: \(msg)")
    case .serverError(let status, let msg, _):
        // 5xx
        print("Server error (\(status)): \(msg)")
    case .apiError(let status, let msg, _):
        // Other HTTP errors
        print("API error (\(status)): \(msg)")
    case .networkError(let msg, let underlyingError):
        // Request never reached the server
        print("Network error: \(msg)")
    case .configError(let msg):
        print("Config error: \(msg)")
    case .platformError(let moduleName, let current, let supported):
        // Attempted to use an iOS-only service on an unsupported platform
        print("\(moduleName) not available on \(current)")
    case .certificatePinningFailure(let host):
        // TLS certificate did not match any pinned public key
        print("Pinning failure for \(host)")
    }
}
```

Every error case carries an optional `ApiErrorPayload` with the server's structured error response (`statusCode`, `error`, `message`, `code`, `requestId`).

## Certificate Pinning

Optional TLS certificate pinning for production hardening:

```swift
let config = SdkConfig(
    baseUrl: URL(string: "https://api.magicapps.dev")!,
    appId: "my-app",
    certificatePinning: CertificatePinningConfig(
        pins: ["sha256/YOUR_CUSTOM_PIN_HASH="],
        enabled: true,            // set false for development
        includeBuiltInPins: true  // includes SDK's bundled pins for api.magicapps.dev
    )
)
```

## License

MIT
