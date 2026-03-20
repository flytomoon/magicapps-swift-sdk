import Foundation

// MARK: - Settings Types

/// Response from the settings endpoint.
public struct SettingsResponse: Decodable {
    public let settings: [String: AnyCodable]?
    public let appId: String?

    enum CodingKeys: String, CodingKey {
        case settings
        case appId = "app_id"
    }
}

/// Response from the config endpoint.
public struct ConfigResponse: Decodable {
    public let config: [String: AnyCodable]?
    public let appId: String?

    enum CodingKeys: String, CodingKey {
        case config
        case appId = "app_id"
    }
}

/// Response from the integration secret endpoint.
public struct IntegrationSecretResponse: Decodable {
    public let integrationId: String?
    public let secret: [String: AnyCodable]?
    public let success: Bool?

    enum CodingKeys: String, CodingKey {
        case integrationId = "integration_id"
        case secret
        case success
    }
}

// MARK: - Settings Service (All Platforms)

/// Settings service module.
/// Provides access to app settings, config, and integration secrets.
/// Available on all platforms.
public class SettingsService: ServiceModule {
    public let name = "settings"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    // MARK: - Settings

    /// Get settings for the current app.
    ///
    /// - Returns: The app settings response.
    public func getSettings() async throws -> SettingsResponse {
        return try await http.get("/apps/\(http.appId)/settings")
    }

    /// Update settings for the current app.
    ///
    /// - Parameter body: The settings fields to update.
    /// - Returns: The updated settings response.
    public func updateSettings(_ body: [String: AnyCodable]) async throws -> SettingsResponse {
        return try await http.put("/apps/\(http.appId)/settings", body: body)
    }

    // MARK: - Config

    /// Get config for the current app.
    ///
    /// - Returns: The app config response.
    public func getConfig() async throws -> ConfigResponse {
        return try await http.get("/apps/\(http.appId)/config")
    }

    /// Update config for the current app.
    ///
    /// - Parameter body: The config fields to update.
    /// - Returns: The updated config response.
    public func updateConfig(_ body: [String: AnyCodable]) async throws -> ConfigResponse {
        return try await http.put("/apps/\(http.appId)/config", body: body)
    }

    // MARK: - Integration Secrets

    /// Get an integration secret by integration ID.
    ///
    /// - Parameter integrationId: The ID of the integration.
    /// - Returns: The integration secret response.
    public func getIntegrationSecret(integrationId: String) async throws -> IntegrationSecretResponse {
        return try await http.get("/apps/\(http.appId)/integrations/\(integrationId)/secret")
    }

    /// Upload an integration secret.
    ///
    /// - Parameters:
    ///   - integrationId: The ID of the integration.
    ///   - body: The secret data to upload.
    /// - Returns: The integration secret response.
    public func uploadIntegrationSecret(integrationId: String, body: [String: AnyCodable]) async throws -> IntegrationSecretResponse {
        return try await http.post("/apps/\(http.appId)/integrations/\(integrationId)/secret", body: body)
    }
}
