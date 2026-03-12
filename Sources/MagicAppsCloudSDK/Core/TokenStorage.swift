import Foundation

/// Protocol for pluggable token storage backends.
///
/// Implement this protocol to provide custom secure storage for tokens.
/// The SDK ships with ``KeychainTokenStorage`` (default) and ``InMemoryTokenStorage``.
public protocol TokenStorage: Sendable {
    /// Save a token value for the given key.
    func save(key: String, value: String) throws
    /// Load a token value for the given key. Returns nil if not found.
    func load(key: String) throws -> String?
    /// Delete a token value for the given key.
    func delete(key: String) throws
    /// Delete all tokens managed by this storage instance.
    func deleteAll() throws
}

/// Well-known keys used by the SDK for token storage.
public enum TokenStorageKey {
    public static let accessToken = "com.magicapps.sdk.accessToken"
    public static let refreshToken = "com.magicapps.sdk.refreshToken"
    public static let ownerToken = "com.magicapps.sdk.ownerToken"
}
