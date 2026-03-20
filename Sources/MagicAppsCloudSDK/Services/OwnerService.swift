import Foundation

// MARK: - Owner Types

/// Request body for registering a device owner.
public struct OwnerRegisterRequest: Encodable {
    public let deviceOwnerId: String
    public let appId: String
    public let hcaptchaToken: String?

    enum CodingKeys: String, CodingKey {
        case deviceOwnerId = "device_owner_id"
        case appId = "app_id"
        case hcaptchaToken = "hcaptcha_token"
    }
}

/// Response from registering a device owner.
public struct OwnerRegisterResponse: Decodable {
    public let ownerToken: String

    enum CodingKeys: String, CodingKey {
        case ownerToken = "owner_token"
    }
}

/// Request body for migrating an owner to a user.
public struct OwnerMigrateRequest: Encodable {
    public let deviceOwnerId: String
    public let appId: String

    enum CodingKeys: String, CodingKey {
        case deviceOwnerId = "device_owner_id"
        case appId = "app_id"
    }
}

/// Response from migrating an owner to a user.
public struct OwnerMigrateResponse: Decodable {
    public let success: Bool
    public let message: String?
}

// MARK: - Owner Service (All Platforms)

/// Owner service module.
/// Provides device-owner registration and migration to user accounts.
/// Available on all platforms.
public class OwnerService: ServiceModule {
    public let name = "owner"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Register a device owner with the platform.
    ///
    /// - Parameters:
    ///   - deviceOwnerId: The unique device owner identifier.
    ///   - appId: The app ID to register under.
    ///   - hcaptchaToken: Optional hCaptcha verification token.
    /// - Returns: An owner registration response containing the owner token.
    public func registerOwner(deviceOwnerId: String, appId: String, hcaptchaToken: String? = nil) async throws -> OwnerRegisterResponse {
        let body = OwnerRegisterRequest(deviceOwnerId: deviceOwnerId, appId: appId, hcaptchaToken: hcaptchaToken)
        return try await http.post("/owner/register", body: body, authMode: .none)
    }

    /// Migrate a device owner to a full user account.
    ///
    /// - Parameters:
    ///   - deviceOwnerId: The unique device owner identifier.
    ///   - appId: The app ID the owner belongs to.
    /// - Returns: A migration response indicating success or failure.
    public func migrateOwnerToUser(deviceOwnerId: String, appId: String) async throws -> OwnerMigrateResponse {
        let body = OwnerMigrateRequest(deviceOwnerId: deviceOwnerId, appId: appId)
        return try await http.post("/owner/migrate", body: body, authMode: .none)
    }
}
