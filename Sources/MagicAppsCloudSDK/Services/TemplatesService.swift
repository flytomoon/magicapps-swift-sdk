import Foundation

// MARK: - Template Types

// Template type is defined in GeneratedTypes.swift

/// A simple type-erased codable wrapper for template content.
/// Uses @unchecked Sendable because the underlying `Any` value is immutable after init —
/// only value types (String, Int, Double, Bool) and Sendable collections ([AnyCodable],
/// [String: AnyCodable]) are stored, so cross-isolation sharing is safe.
public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else {
            value = NSNull()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let dict = value as? [String: AnyCodable] {
            try container.encode(dict)
        } else if let array = value as? [AnyCodable] {
            try container.encode(array)
        } else {
            try container.encodeNil()
        }
    }
}

/// Response from the catalog endpoint.
public struct CatalogResponse: Decodable {
    public let apps: [App]?
    public let items: [App]?

    /// Convenience accessor that returns apps from whichever field the API uses.
    public var allApps: [App] {
        return apps ?? items ?? []
    }
}

// MARK: - Templates Service (All Platforms)

/// Templates service module.
/// Provides read-only access to a specific template by ID
/// and the app catalog endpoint.
/// Available on all platforms.
public class TemplatesService: ServiceModule {
    public let name = "templates"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    // MARK: - Get Template

    /// Get a specific template by ID.
    ///
    /// - Parameter templateId: The ID of the template to retrieve.
    /// - Returns: The template details.
    public func get(templateId: String) async throws -> Template {
        return try await http.get("/apps/\(http.appId)/templates/\(templateId)", authMode: .none)
    }

    // MARK: - Catalog

    /// Fetch the app catalog for the current app.
    ///
    /// - Returns: The catalog response with available apps and integrations.
    public func getCatalog() async throws -> CatalogResponse {
        return try await http.get("/apps/\(http.appId)/catalog", authMode: .none)
    }
}
