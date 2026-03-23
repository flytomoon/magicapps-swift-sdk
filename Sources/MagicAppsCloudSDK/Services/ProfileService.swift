import Foundation

// MARK: - Profile Request/Response Types

/// Request body for updating the user's profile.
public struct UpdateProfileRequest: Encodable {
    public let displayName: String?
    public let avatarUrl: String?
    public let bio: String?
    public let preferences: [String: AnyCodable]?
    public let customFields: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bio
        case preferences
        case customFields = "custom_fields"
    }

    public init(
        displayName: String? = nil,
        avatarUrl: String? = nil,
        bio: String? = nil,
        preferences: [String: AnyCodable]? = nil,
        customFields: [String: AnyCodable]? = nil
    ) {
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.preferences = preferences
        self.customFields = customFields
    }
}

// UserProfile and UserProfilePublic are defined in GeneratedTypes.swift

// MARK: - Profile Service (All Platforms)

/// User profile service module.
/// Provides access to the authenticated user's profile and public profiles of other users.
/// Available on all platforms.
public class ProfileService: ServiceModule {
    public let name = "profile"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Get the authenticated user's profile.
    ///
    /// - Returns: The full user profile including preferences and custom fields.
    public func getProfile() async throws -> UserProfile {
        return try await http.get("/apps/\(http.appId)/profile")
    }

    /// Update the authenticated user's profile.
    ///
    /// Only the provided fields are updated; omitted fields remain unchanged.
    ///
    /// - Parameters:
    ///   - displayName: The user's display name.
    ///   - avatarUrl: URL to the user's avatar image.
    ///   - bio: A short biography or description.
    ///   - preferences: User preference key-value pairs.
    ///   - customFields: Arbitrary custom fields.
    /// - Returns: The updated user profile.
    public func updateProfile(
        displayName: String? = nil,
        avatarUrl: String? = nil,
        bio: String? = nil,
        preferences: [String: AnyCodable]? = nil,
        customFields: [String: AnyCodable]? = nil
    ) async throws -> UserProfile {
        let body = UpdateProfileRequest(
            displayName: displayName,
            avatarUrl: avatarUrl,
            bio: bio,
            preferences: preferences,
            customFields: customFields
        )
        return try await http.put("/apps/\(http.appId)/profile", body: body)
    }

    /// Get another user's public profile.
    ///
    /// Returns a limited subset of profile fields visible to other users.
    ///
    /// - Parameter userId: The ID of the user whose public profile to retrieve.
    /// - Returns: The public profile with display name, avatar, and bio.
    public func getPublicProfile(userId: String) async throws -> UserProfilePublic {
        let encoded = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId
        return try await http.get("/apps/\(http.appId)/profile/\(encoded)")
    }
}
