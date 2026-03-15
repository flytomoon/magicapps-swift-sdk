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

/// Request body for creating a template.
public struct CreateTemplateRequest: Encodable {
    public let name: String
    public let description: String?
    public let content: [String: AnyCodable]?

    public init(name: String, description: String? = nil, content: [String: AnyCodable]? = nil) {
        self.name = name
        self.description = description
        self.content = content
    }
}

/// Request body for updating a template.
public struct UpdateTemplateRequest: Encodable {
    public let name: String?
    public let description: String?
    public let content: [String: AnyCodable]?

    public init(name: String? = nil, description: String? = nil, content: [String: AnyCodable]? = nil) {
        self.name = name
        self.description = description
        self.content = content
    }
}

/// Paginated list response for templates.
public struct TemplateListResponse: Decodable {
    public let templates: [Template]?
    public let items: [Template]?
    public let nextToken: String?
    public let count: Int?

    enum CodingKeys: String, CodingKey {
        case templates, items
        case nextToken = "next_token"
        case count
    }

    /// Convenience accessor that returns templates from whichever field the API uses.
    public var allTemplates: [Template] {
        return templates ?? items ?? []
    }
}

/// Registry app in the catalog.
public struct RegistryApp: Decodable {
    public let appId: String
    public let name: String
    public let slug: String
    public let description: String?
    public let iconUrl: String?
    public let status: String?
    public let visibility: String?

    enum CodingKeys: String, CodingKey {
        case appId = "app_id"
        case name, slug, description
        case iconUrl = "icon_url"
        case status, visibility
    }
}

/// Response from the registry apps endpoint.
public struct RegistryAppsResponse: Decodable {
    public let apps: [RegistryApp]?
    public let items: [RegistryApp]?

    /// Convenience accessor that returns apps from whichever field the API uses.
    public var allApps: [RegistryApp] {
        return apps ?? items ?? []
    }
}

// MARK: - Templates Service (All Platforms)

/// Templates service module.
/// Provides CRUD operations for templates within a tenant's app,
/// plus read access to the registry catalog.
/// Available on all platforms.
public class TemplatesService: ServiceModule {
    public let name = "templates"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    // MARK: - List Templates

    /// List templates for the current app.
    ///
    /// - Parameter nextToken: Optional pagination token for the next page.
    /// - Returns: A paginated list of templates.
    public func list(nextToken: String? = nil) async throws -> TemplateListResponse {
        var query: [String: String]? = nil
        if let nextToken {
            query = ["next_token": nextToken]
        }
        return try await http.get("/apps/\(http.appId)/templates", query: query, authMode: .none)
    }

    // MARK: - Get Template

    /// Get a specific template by ID.
    ///
    /// - Parameter templateId: The ID of the template to retrieve.
    /// - Returns: The template details.
    public func get(templateId: String) async throws -> Template {
        return try await http.get("/apps/\(http.appId)/templates/\(templateId)", authMode: .none)
    }

    // MARK: - Create Template

    /// Create a new template for the current app. Requires authentication.
    ///
    /// - Parameter request: The template creation request.
    /// - Returns: The created template.
    public func create(_ request: CreateTemplateRequest) async throws -> Template {
        return try await http.post("/apps/\(http.appId)/templates", body: request)
    }

    /// Convenience: create a template with name and optional description.
    public func create(name: String, description: String? = nil, content: [String: AnyCodable]? = nil) async throws -> Template {
        let request = CreateTemplateRequest(name: name, description: description, content: content)
        return try await create(request)
    }

    // MARK: - Update Template

    /// Update an existing template. Requires authentication.
    ///
    /// - Parameters:
    ///   - templateId: The ID of the template to update.
    ///   - request: The update request with fields to change.
    /// - Returns: The updated template.
    public func update(templateId: String, _ request: UpdateTemplateRequest) async throws -> Template {
        return try await http.put("/apps/\(http.appId)/templates/\(templateId)", body: request)
    }

    // MARK: - Delete Template

    /// Delete a template. Requires authentication.
    ///
    /// - Parameter templateId: The ID of the template to delete.
    public func delete(templateId: String) async throws {
        let _: EmptyResponse = try await http.delete("/apps/\(http.appId)/templates/\(templateId)")
    }

    // MARK: - Registry Catalog

    /// Browse the registry catalog of well-known apps and templates.
    ///
    /// - Returns: A list of registry apps.
    public func browseRegistry() async throws -> RegistryAppsResponse {
        return try await http.get("/registry/apps", authMode: .none)
    }
}
