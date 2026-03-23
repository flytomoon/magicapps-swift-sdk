import Foundation

// MARK: - Account Types

/// Request body for account deletion.
public struct DeleteAccountRequest: Encodable {
    public let reason: String?

    public init(reason: String? = nil) {
        self.reason = reason
    }
}

/// Response from account deletion.
public struct DeleteAccountResponse: Decodable {
    public let success: Bool?
    public let message: String?
}

// MARK: - Account Service (All Platforms)

/// Account management service module.
/// Provides user-initiated account deletion.
/// Available on all platforms.
public class AccountService: ServiceModule {
    public let name = "account"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Delete the authenticated user's account.
    ///
    /// This permanently removes the user's data including profile, files,
    /// and associated records. This action cannot be undone.
    ///
    /// - Parameter reason: Optional reason for account deletion (max 2000 characters).
    /// - Returns: A response indicating whether the deletion was successful.
    public func deleteAccount(reason: String? = nil) async throws -> DeleteAccountResponse {
        let body = DeleteAccountRequest(reason: reason)
        return try await http.delete("/apps/\(http.appId)/account", body: body)
    }
}
