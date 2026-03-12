import Foundation

/// Configuration for initializing the Magic Apps Cloud SDK.
public struct SdkConfig {
    /// The base URL of the MagicApps API.
    public let baseUrl: URL
    /// The app_id that scopes all API requests to a specific tenant.
    public let appId: String
    /// Optional Bearer JWT token for user authentication.
    public var accessToken: String?
    /// Optional refresh token for automatic token renewal.
    public var refreshToken: String?
    /// Optional owner token for owner-level authentication.
    public var ownerToken: String?
    /// Number of retries for failed requests (default: 2).
    public var retries: Int
    /// Base delay between retries in seconds (default: 0.25).
    public var retryDelay: TimeInterval
    /// Custom URLSession for requests (defaults to .shared).
    /// When ``certificatePinning`` is configured, this is ignored in favor of a
    /// pinning-enabled session created internally.
    public var session: URLSession
    /// Callback invoked when tokens are refreshed.
    public var onTokenRefresh: ((TokenPair) -> Void)?
    /// Callback invoked when token refresh fails.
    public var onAuthError: ((SdkError) -> Void)?
    /// Token storage backend. Defaults to ``KeychainTokenStorage`` for encrypted
    /// persistence. Pass ``InMemoryTokenStorage`` to opt out, or provide a custom
    /// ``TokenStorage`` implementation.
    public var tokenStorage: TokenStorage
    /// Certificate pinning configuration. When set, the SDK validates that the
    /// server's TLS certificate matches one of the configured public key hashes.
    /// Set ``CertificatePinningConfig/enabled`` to `false` for development.
    public var certificatePinning: CertificatePinningConfig?

    public init(
        baseUrl: URL,
        appId: String,
        accessToken: String? = nil,
        refreshToken: String? = nil,
        ownerToken: String? = nil,
        retries: Int = 2,
        retryDelay: TimeInterval = 0.25,
        session: URLSession = .shared,
        onTokenRefresh: ((TokenPair) -> Void)? = nil,
        onAuthError: ((SdkError) -> Void)? = nil,
        tokenStorage: TokenStorage? = nil,
        certificatePinning: CertificatePinningConfig? = nil
    ) {
        self.baseUrl = baseUrl
        self.appId = appId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.ownerToken = ownerToken
        self.retries = retries
        self.retryDelay = retryDelay
        self.session = session
        self.onTokenRefresh = onTokenRefresh
        self.onAuthError = onAuthError
        self.tokenStorage = tokenStorage ?? KeychainTokenStorage()
        self.certificatePinning = certificatePinning
    }
}

/// A pair of access + refresh tokens.
public struct TokenPair {
    public let accessToken: String
    public let refreshToken: String?

    public init(accessToken: String, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

/// Auth mode for a request.
public enum AuthMode {
    case bearer
    case owner
    case none
}
