import Foundation
#if canImport(Security)
import Security
#endif

/// Stores tokens securely in the iOS/macOS Keychain.
///
/// Tokens are encrypted at rest by the operating system and are not accessible
/// to other apps. Each ``MagicAppsClient`` instance can use a unique `serviceName`
/// to isolate its tokens from other SDK instances.
///
/// This is the default storage backend for the SDK on Apple platforms.
///
/// ```swift
/// // Use default service name
/// let storage = KeychainTokenStorage()
///
/// // Use custom service name for multi-app isolation
/// let storage = KeychainTokenStorage(serviceName: "com.myapp.tokens")
/// ```
public final class KeychainTokenStorage: TokenStorage, @unchecked Sendable {
    private let serviceName: String
    private let lock = NSLock()

    /// All token keys managed by this storage, used for ``deleteAll()``.
    private let managedKeys = [
        TokenStorageKey.accessToken,
        TokenStorageKey.refreshToken,
        TokenStorageKey.ownerToken
    ]

    /// Create a Keychain storage instance.
    ///
    /// - Parameter serviceName: The Keychain service name used to scope stored items.
    ///   Defaults to `"com.magicapps.sdk.tokens"`. Use different service names to
    ///   isolate tokens between multiple SDK client instances.
    public init(serviceName: String = "com.magicapps.sdk.tokens") {
        self.serviceName = serviceName
    }

    public func save(key: String, value: String) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // Delete existing item first (update = delete + add for simplicity)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    public func load(key: String) throws -> String? {
        lock.lock()
        defer { lock.unlock() }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                throw KeychainError.decodingFailed
            }
            return value
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.loadFailed(status)
        }
    }

    public func delete(key: String) throws {
        lock.lock()
        defer { lock.unlock() }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    public func deleteAll() throws {
        for key in managedKeys {
            try delete(key: key)
        }
    }
}

/// Errors specific to Keychain operations.
public enum KeychainError: Error, CustomStringConvertible {
    case encodingFailed
    case decodingFailed
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)

    public var description: String {
        switch self {
        case .encodingFailed:
            return "Keychain Error: Failed to encode token data"
        case .decodingFailed:
            return "Keychain Error: Failed to decode token data"
        case .saveFailed(let status):
            return "Keychain Error: Save failed with status \(status)"
        case .loadFailed(let status):
            return "Keychain Error: Load failed with status \(status)"
        case .deleteFailed(let status):
            return "Keychain Error: Delete failed with status \(status)"
        }
    }
}
