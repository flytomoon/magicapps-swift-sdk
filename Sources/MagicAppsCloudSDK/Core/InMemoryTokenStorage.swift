import Foundation

/// Stores tokens in memory only. Tokens are lost when the process exits.
///
/// Use this storage backend when you don't want tokens persisted to disk,
/// or in environments where the Keychain is unavailable (e.g., Linux servers,
/// unit tests).
///
/// ```swift
/// let config = SdkConfig(
///     baseUrl: URL(string: "https://api.magicapps.dev")!,
///     appId: "my-app",
///     tokenStorage: InMemoryTokenStorage()
/// )
/// ```
public final class InMemoryTokenStorage: TokenStorage, @unchecked Sendable {
    private var store: [String: String] = [:]
    private let lock = NSLock()

    public init() {}

    public func save(key: String, value: String) throws {
        lock.lock()
        defer { lock.unlock() }
        store[key] = value
    }

    public func load(key: String) throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return store[key]
    }

    public func delete(key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        store.removeValue(forKey: key)
    }

    public func deleteAll() throws {
        lock.lock()
        defer { lock.unlock() }
        store.removeAll()
    }
}
