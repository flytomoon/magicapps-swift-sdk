import Foundation

/// Health check response from GET /ping.
public struct PingResponse: Decodable {
    public let message: String
    public let requestId: String?
}

/// Information about a registered application.
public struct AppInfo: Codable, Sendable {
    public let appId: String
    public let name: String
    public let slug: String
    public let description: String?
    public let createdAt: String
    public let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case appId = "app_id"
        case name, slug, description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// The main MagicApps SDK client for iOS/Swift.
///
/// Provides app_id-scoped API access with automatic authentication,
/// modular service plugins, and platform-conditional module availability.
///
/// ```swift
/// let client = MagicAppsClient(config: SdkConfig(
///     baseUrl: URL(string: "https://api.magicapps.dev")!,
///     appId: "my-app"
/// ))
///
/// let pong = try await client.ping()
/// ```
public class MagicAppsClient {
    private let http: SdkHttpClient
    private let registry: ServiceRegistry
    private let appId: String

    /// Authentication service (all platforms).
    public let auth: AuthService
    /// Apple Sign-In service (iOS only).
    public let appleAuth: AppleAuthService
    /// Apple IAP service (iOS only - enforced by registry).
    public let appleIap: AppleIapService
    /// AI proxy service (all platforms).
    public let ai: AiService
    /// Templates service (all platforms).
    public let templates: TemplatesService
    /// Devices catalog service (all platforms).
    public let devices: DevicesService

    public init(config: SdkConfig) {
        #if os(iOS) || os(tvOS) || os(watchOS)
        let platform: SdkPlatform = .ios
        #elseif os(macOS)
        let platform: SdkPlatform = .ios // macOS treated as Apple platform
        #else
        let platform: SdkPlatform = .ios
        #endif

        self.http = SdkHttpClient(config: config)
        self.appId = config.appId
        self.registry = ServiceRegistry(platform: platform)

        self.auth = AuthService(http: http)
        self.appleAuth = AppleAuthService(http: http)
        self.appleIap = AppleIapService(http: http)
        self.ai = AiService(http: http)
        self.templates = TemplatesService(http: http)
        self.devices = DevicesService(http: http)

        registry.register(auth)
        registry.register(appleAuth)
        registry.register(appleIap)
        registry.register(ai)
        registry.register(templates)
        registry.register(devices)
    }

    /// Health check - verifies connectivity to the MagicApps API.
    public func ping() async throws -> PingResponse {
        return try await http.get("/ping", authMode: .none)
    }

    /// Get information about the current application.
    public func getAppInfo() async throws -> AppInfo {
        return try await http.get("/apps/\(appId)", authMode: .none)
    }

    /// Register a custom service module.
    public func registerService(_ module: any ServiceModule) {
        registry.register(module)
    }

    /// Get a service by name (platform-checked).
    public func getService<T: ServiceModule>(_ name: String) throws -> T? {
        return try registry.get(name)
    }

    /// Check if a service is available on the current platform.
    public func hasService(_ name: String) -> Bool {
        return registry.has(name)
    }

    /// List all available services on the current platform.
    public func listServices() -> [any ServiceModule] {
        return registry.listAvailable()
    }

    /// Update authentication tokens.
    public func setTokens(accessToken: String? = nil, refreshToken: String? = nil, ownerToken: String? = nil) async {
        await http.tokenManager.setTokens(accessToken: accessToken, refreshToken: refreshToken, ownerToken: ownerToken)
    }

    /// Clear all authentication tokens.
    public func clearTokens() async {
        await http.tokenManager.clearTokens()
    }
}
