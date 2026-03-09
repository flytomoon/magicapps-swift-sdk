//
// GeneratedTypes.swift
// Auto-generated API types from OpenAPI specification.
// DO NOT EDIT MANUALLY - regenerate with: npm run openapi:generate-types
//// Generated at: 2026-03-09T07:54:32.672Z
//

import Foundation

public struct AuthTokenResponse: Codable, Sendable {
    public let user: [String: AnyCodable]?
    public let id: String?
    public let email: String?
    public let status: String?
    public let token: String?
    public let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case user
        case id
        case email
        case status
        case token
        case refreshToken = "refresh_token"
    }
}

public struct Tenant: Codable, Sendable {
    public let tenantId: String?
    public let name: String?
    public let email: String?
    public let status: String?
    public let createdAt: String?
    public let plan: String?

    enum CodingKeys: String, CodingKey {
        case tenantId = "tenant_id"
        case name
        case email
        case status
        case createdAt = "created_at"
        case plan
    }
}

public struct AIProvider: Codable, Sendable {
    public let id: String?
    public let name: String?
    public let provider: String?
    public let model: String?
    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case provider
        case model
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct Error: Codable, Sendable {
    public let error: String
    public let message: String
}

public struct LookupTableSummary: Codable, Sendable {
    public let lookupTableId: String?
    public let name: String?
    public let description: String?
    public let schemaKeys: [String]?
    public let schemaKeyCount: Int?
    public let schemaKeysTruncated: Bool?
    public let version: Int?
    public let payloadHash: String?
    public let storageMode: String?
    public let chunkCount: Int?
    public let updatedAt: Int?

    enum CodingKeys: String, CodingKey {
        case lookupTableId = "lookup_table_id"
        case name
        case description
        case schemaKeys = "schema_keys"
        case schemaKeyCount = "schema_key_count"
        case schemaKeysTruncated = "schema_keys_truncated"
        case version
        case payloadHash = "payload_hash"
        case storageMode = "storage_mode"
        case chunkCount = "chunk_count"
        case updatedAt = "updated_at"
    }
}

public struct LookupTableChunk: Codable, Sendable {
    public let index: Int?
    public let path: String?
    public let sha256: String?
    public let byteLength: Int?

    enum CodingKeys: String, CodingKey {
        case index
        case path
        case sha256
        case byteLength = "byte_length"
    }
}

public struct LookupTableDetail: LookupTableSummary {
    /// Present on detail only; omitted from summary list.
    public let prompt: String?
    /// Optional templated success sentence using {{path.to.key}} tokens.
    public let defaultSuccessSentence: String?
    /// Optional fallback fail sentence.
    public let defaultFailSentence: String?
    public let chunkEncoding: String?
    public let manifestHash: String?
    public let chunks: [LookupTableChunk]?

    enum CodingKeys: String, CodingKey {
        case prompt
        case defaultSuccessSentence = "default_success_sentence"
        case defaultFailSentence = "default_fail_sentence"
        case chunkEncoding = "chunk_encoding"
        case manifestHash = "manifest_hash"
        case chunks
    }
}

public struct AdminLookupTableDetail: LookupTableDetail {
    public let allowlistedApps: [String]?
    public let clientTargets: [String]?
    public let status: String?
    public let createdAt: Int?
    public let updatedBy: String?
    public let deletedAt: Int?
    public let purgeAt: Int?
    public let payloadJson: [String: AnyCodable]?
    public let manifestKey: String?

    enum CodingKeys: String, CodingKey {
        case allowlistedApps = "allowlisted_apps"
        case clientTargets = "client_targets"
        case status
        case createdAt = "created_at"
        case updatedBy = "updated_by"
        case deletedAt = "deleted_at"
        case purgeAt = "purge_at"
        case payloadJson = "payload_json"
        case manifestKey = "manifest_key"
    }
}

public struct AdminLookupTableUpsertRequest: Codable, Sendable {
    public let lookupTableId: String?
    public let name: String
    public let description: String?
    /// Optional prompt metadata (max 4000 chars).
    public let prompt: String?
    /// Optional success sentence template (max 2000 chars).
    public let defaultSuccessSentence: String?
    /// Optional fail sentence text (max 1000 chars).
    public let defaultFailSentence: String?
    public let allowlistedApps: [String]?
    public let clientTargets: [String]?
    /// Required on PATCH for optimistic locking.
    public let version: Int?
    public let payloadJson: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case lookupTableId = "lookup_table_id"
        case name
        case description
        case prompt
        case defaultSuccessSentence = "default_success_sentence"
        case defaultFailSentence = "default_fail_sentence"
        case allowlistedApps = "allowlisted_apps"
        case clientTargets = "client_targets"
        case version
        case payloadJson = "payload_json"
    }
}

public struct Template: Codable, Sendable {
    public let pk: String?
    public let sk: String?
    public let templateId: String?
    public let integrationId: String?
    public let appId: String?
    public let templateName: String?
    public let templateType: String?
    /// High-level grouping (e.g., custom_core, built_integration)
    public let group: String?
    /// End-user facing description shown publicly
    public let publicDescription: String?
    /// How the endpoint is supplied (e.g., full_url, id_only)
    public let endpointInputMode: String?
    /// Placeholder text for id_only inputs
    public let endpointInputPlaceholder: String?
    /// Whether the client should show the endpoint input field
    public let showEndpointInput: Bool?
    /// Whether the client should display parameter fields
    public let showParameters: Bool?
    public let integrationName: String?
    public let provider: String?
    public let description: String?
    public let category: String?
    public let tags: [String]?
    public let status: String?
    public let version: String?
    public let isLatest: Bool?
    public let lastVerifiedAt: String?
    public let maintainer: String?
    public let createdByName: String?
    public let websiteUrl: String?
    public let docsUrl: String?
    public let supportUrl: String?
    public let appStoreUrls: [String: AnyCodable]?
    public let apple: String?
    public let google: String?
    public let iconUrl: String?
    public let priceTier: String?
    public let currentPrice: String?
    public let authType: String?
    public let authLocation: String?
    public let scopes: [String]?
    public let requiresSignature: Bool?
    public let contentType: String?
    public let submittedByName: String?
    public let submittedByEmail: String?
    public let submittedAt: String?
    public let breakingChanges: String?
    public let supersedesVersion: String?
    public let approvedAt: String?
    public let isNewUntil: String?
    public let visibility: TemplateVisibility?
    public let allowedAppIds: [String]?
    public let endpointPattern: String?
    public let parameters: [TemplateParameter]?
    public let metadata: [String: AnyCodable]?
    public let createdAt: Double?
    public let updatedAt: Double?

    enum CodingKeys: String, CodingKey {
        case pk
        case sk
        case templateId = "template_id"
        case integrationId = "integration_id"
        case appId = "app_id"
        case templateName = "template_name"
        case templateType = "template_type"
        case group
        case publicDescription = "public_description"
        case endpointInputMode = "endpoint_input_mode"
        case endpointInputPlaceholder = "endpoint_input_placeholder"
        case showEndpointInput = "show_endpoint_input"
        case showParameters = "show_parameters"
        case integrationName = "integration_name"
        case provider
        case description
        case category
        case tags
        case status
        case version
        case isLatest = "is_latest"
        case lastVerifiedAt = "last_verified_at"
        case maintainer
        case createdByName = "created_by_name"
        case websiteUrl = "website_url"
        case docsUrl = "docs_url"
        case supportUrl = "support_url"
        case appStoreUrls = "app_store_urls"
        case apple
        case google
        case iconUrl = "icon_url"
        case priceTier = "price_tier"
        case currentPrice = "current_price"
        case authType = "auth_type"
        case authLocation = "auth_location"
        case scopes
        case requiresSignature = "requires_signature"
        case contentType = "content_type"
        case submittedByName = "submitted_by_name"
        case submittedByEmail = "submitted_by_email"
        case submittedAt = "submitted_at"
        case breakingChanges = "breaking_changes"
        case supersedesVersion = "supersedes_version"
        case approvedAt = "approved_at"
        case isNewUntil = "is_new_until"
        case visibility
        case allowedAppIds = "allowed_app_ids"
        case endpointPattern = "endpoint_pattern"
        case parameters
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct AppIntegration: Codable, Sendable {
    public let integrationId: String?
    public let integrationName: String?
    public let group: String?
    public let templateId: String?
    public let templateName: String?
    public let templateType: String?
    public let endpointInputMode: String?
    public let endpointInputPlaceholder: String?
    public let showEndpointInput: Bool?
    public let showParameters: Bool?
    public let endpointPattern: String?
    public let parameters: [TemplateParameter]?
    public let metadata: [String: AnyCodable]?
    public let createdByName: String?
    public let authType: String?
    public let authLocation: String?
    public let scopes: [String]?
    public let requiresSignature: Bool?
    public let contentType: String?
    public let setupFields: [SetupField]?

    enum CodingKeys: String, CodingKey {
        case integrationId = "integration_id"
        case integrationName = "integration_name"
        case group
        case templateId = "template_id"
        case templateName = "template_name"
        case templateType = "template_type"
        case endpointInputMode = "endpoint_input_mode"
        case endpointInputPlaceholder = "endpoint_input_placeholder"
        case showEndpointInput = "show_endpoint_input"
        case showParameters = "show_parameters"
        case endpointPattern = "endpoint_pattern"
        case parameters
        case metadata
        case createdByName = "created_by_name"
        case authType = "auth_type"
        case authLocation = "auth_location"
        case scopes
        case requiresSignature = "requires_signature"
        case contentType = "content_type"
        case setupFields = "setup_fields"
    }
}

public struct AppIntegrationV2: Codable, Sendable {
    public let integrationId: String?
    public let integrationName: String?
    public let group: String?
    public let templateId: String?
    public let templateName: String?
    public let templateType: String?
    public let endpointInputMode: String?
    public let endpointInputPlaceholder: String?
    public let showEndpointInput: Bool?
    public let showParameters: Bool?
    public let endpointPattern: String?
    public let parameters: [TemplateParameter]?
    public let metadata: [String: AnyCodable]?
    public let createdByName: String?
    public let authType: String?
    public let authLocation: String?
    public let scopes: [String]?
    public let requiresSignature: Bool?
    public let contentType: String?
    public let setupFields: [SetupField]?

    enum CodingKeys: String, CodingKey {
        case integrationId = "integration_id"
        case integrationName = "integration_name"
        case group
        case templateId = "template_id"
        case templateName = "template_name"
        case templateType = "template_type"
        case endpointInputMode = "endpoint_input_mode"
        case endpointInputPlaceholder = "endpoint_input_placeholder"
        case showEndpointInput = "show_endpoint_input"
        case showParameters = "show_parameters"
        case endpointPattern = "endpoint_pattern"
        case parameters
        case metadata
        case createdByName = "created_by_name"
        case authType = "auth_type"
        case authLocation = "auth_location"
        case scopes
        case requiresSignature = "requires_signature"
        case contentType = "content_type"
        case setupFields = "setup_fields"
    }
}

public struct App: Codable, Sendable {
    public let appId: String?
    public let name: String?
    public let displayName: String?
    public let summary: String?
    public let allowMultiple: Bool?
    public let publicDescription: String?
    public let description: String?
    public let category: String?
    public let tags: [String]?
    public let aliases: [String]?
    public let defaultIntegrationId: String?
    public let status: String?
    public let version: String?
    public let isLatest: Bool?
    public let lastVerifiedAt: String?
    public let maintainer: String?
    public let createdByName: String?
    public let createdByEmail: String?
    public let websiteUrl: String?
    public let docsUrl: String?
    public let supportUrl: String?
    public let appStoreUrls: [String: AnyCodable]?
    public let apple: String?
    public let google: String?
    public let iconUrl: String?
    public let visibility: TemplateVisibility?
    public let integrations: [AppIntegration]?

    enum CodingKeys: String, CodingKey {
        case appId = "app_id"
        case name
        case displayName = "display_name"
        case summary
        case allowMultiple = "allow_multiple"
        case publicDescription = "public_description"
        case description
        case category
        case tags
        case aliases
        case defaultIntegrationId = "default_integration_id"
        case status
        case version
        case isLatest = "is_latest"
        case lastVerifiedAt = "last_verified_at"
        case maintainer
        case createdByName = "created_by_name"
        case createdByEmail = "created_by_email"
        case websiteUrl = "website_url"
        case docsUrl = "docs_url"
        case supportUrl = "support_url"
        case appStoreUrls = "app_store_urls"
        case apple
        case google
        case iconUrl = "icon_url"
        case visibility
        case integrations
    }
}

public struct AppV2: Codable, Sendable {
    public let appId: String?
    public let name: String?
    public let displayName: String?
    public let summary: String?
    public let allowMultiple: Bool?
    public let publicDescription: String?
    public let description: String?
    public let category: String?
    public let tags: [String]?
    public let aliases: [String]?
    public let defaultIntegrationId: String?
    public let status: String?
    public let version: String?
    public let isLatest: Bool?
    public let lastVerifiedAt: String?
    public let maintainer: String?
    public let createdByName: String?
    public let createdByEmail: String?
    public let websiteUrl: String?
    public let docsUrl: String?
    public let supportUrl: String?
    public let appStoreUrls: [String: AnyCodable]?
    public let apple: String?
    public let google: String?
    public let iconUrl: String?
    public let visibility: TemplateVisibility?
    public let integrations: [AppIntegrationV2]?

    enum CodingKeys: String, CodingKey {
        case appId = "app_id"
        case name
        case displayName = "display_name"
        case summary
        case allowMultiple = "allow_multiple"
        case publicDescription = "public_description"
        case description
        case category
        case tags
        case aliases
        case defaultIntegrationId = "default_integration_id"
        case status
        case version
        case isLatest = "is_latest"
        case lastVerifiedAt = "last_verified_at"
        case maintainer
        case createdByName = "created_by_name"
        case createdByEmail = "created_by_email"
        case websiteUrl = "website_url"
        case docsUrl = "docs_url"
        case supportUrl = "support_url"
        case appStoreUrls = "app_store_urls"
        case apple
        case google
        case iconUrl = "icon_url"
        case visibility
        case integrations
    }
}

public struct AppAvailabilityIntegration: Codable, Sendable {
    public let integrationId: String?
    public let integrationName: String?
    public let templateType: String?

    enum CodingKeys: String, CodingKey {
        case integrationId = "integration_id"
        case integrationName = "integration_name"
        case templateType = "template_type"
    }
}

public struct AppAvailabilityMatch: Codable, Sendable {
    public let appId: String?
    public let name: String?
    public let defaultIntegrationId: String?
    public let integrations: [AppAvailabilityIntegration]?

    enum CodingKeys: String, CodingKey {
        case appId = "app_id"
        case name
        case defaultIntegrationId = "default_integration_id"
        case integrations
    }
}

public struct AppAvailabilityResponse: Codable, Sendable {
    public let available: Bool?
    public let matches: [AppAvailabilityMatch]?
}

public struct TemplateInput: Codable, Sendable {
    public let templateType: String?
    public let publicDescription: String?
    /// How the endpoint is supplied (e.g., full_url, id_only)
    public let endpointInputMode: String?
    /// Placeholder text for id_only inputs
    public let endpointInputPlaceholder: String?
    /// Whether the client should show the endpoint input field
    public let showEndpointInput: Bool?
    /// Whether the client should display parameter fields
    public let showParameters: Bool?
    public let integrationName: String?
    public let category: String?
    public let tags: [String]?
    public let status: String?
    public let version: String?
    public let isLatest: Bool?
    public let description: String?
    public let websiteUrl: String?
    public let docsUrl: String?
    public let supportUrl: String?
    public let appStoreUrls: [String: AnyCodable]?
    public let apple: String?
    public let google: String?
    public let iconUrl: String?
    public let priceTier: String?
    public let currentPrice: String?
    public let submittedByName: String?
    public let submittedByEmail: String?
    public let submittedAt: String?
    public let visibility: TemplateVisibility?
    public let parameters: [TemplateParameter]?
    public let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case templateType = "template_type"
        case publicDescription = "public_description"
        case endpointInputMode = "endpoint_input_mode"
        case endpointInputPlaceholder = "endpoint_input_placeholder"
        case showEndpointInput = "show_endpoint_input"
        case showParameters = "show_parameters"
        case integrationName = "integration_name"
        case category
        case tags
        case status
        case version
        case isLatest = "is_latest"
        case description
        case websiteUrl = "website_url"
        case docsUrl = "docs_url"
        case supportUrl = "support_url"
        case appStoreUrls = "app_store_urls"
        case apple
        case google
        case iconUrl = "icon_url"
        case priceTier = "price_tier"
        case currentPrice = "current_price"
        case submittedByName = "submitted_by_name"
        case submittedByEmail = "submitted_by_email"
        case submittedAt = "submitted_at"
        case visibility
        case parameters
        case metadata
    }
}

/// Mutable fields admins can update on approved templates; approved_at/is_new_until remain unchanged.
public struct TemplateAdminUpdate: Codable, Sendable {
    public let templateName: String?
    public let publicDescription: String?
    public let description: String?
    public let integrationName: String?
    public let provider: String?
    public let endpointPattern: String?
    public let endpointInputMode: String?
    public let endpointInputPlaceholder: String?
    public let showEndpointInput: Bool?
    public let showParameters: Bool?
    public let parameters: [TemplateParameter]?
    public let category: String?
    public let tags: [String]?
    public let maintainer: String?
    public let websiteUrl: String?
    public let docsUrl: String?
    public let supportUrl: String?
    public let appStoreUrls: [String: AnyCodable]?
    public let apple: String?
    public let google: String?
    public let iconUrl: String?
    public let priceTier: String?
    public let currentPrice: String?
    public let breakingChanges: String?
    public let supersedesVersion: String?
    public let visibility: TemplateVisibility?

    enum CodingKeys: String, CodingKey {
        case templateName = "template_name"
        case publicDescription = "public_description"
        case description
        case integrationName = "integration_name"
        case provider
        case endpointPattern = "endpoint_pattern"
        case endpointInputMode = "endpoint_input_mode"
        case endpointInputPlaceholder = "endpoint_input_placeholder"
        case showEndpointInput = "show_endpoint_input"
        case showParameters = "show_parameters"
        case parameters
        case category
        case tags
        case maintainer
        case websiteUrl = "website_url"
        case docsUrl = "docs_url"
        case supportUrl = "support_url"
        case appStoreUrls = "app_store_urls"
        case apple
        case google
        case iconUrl = "icon_url"
        case priceTier = "price_tier"
        case currentPrice = "current_price"
        case breakingChanges = "breaking_changes"
        case supersedesVersion = "supersedes_version"
        case visibility
    }
}

public struct TemplateParameter: Codable, Sendable {
    public let name: String
    /// Legacy alias for value_type.
    public let type: String?
    /// Preferred field for parameter value type.
    public let valueType: String?
    /// User-facing label when value_type is user_input.
    public let label: String?
    public let required: Bool?
    public let default: String?
    public let example: String?
    public let encoding: String?

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case valueType = "value_type"
        case label
        case required
        case default
        case example
        case encoding
    }
}

public struct SetupField: Codable, Sendable {
    public let id: String?
    public let label: String?
    public let type: String?
    public let required: Bool?
    public let placeholder: String?
    public let hint: String?
    public let inputMode: String?
    public let expectedFormat: String?
    public let validation: [String: AnyCodable]?
    public let isSecret: Bool?
    public let allowVoiceInput: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case type
        case required
        case placeholder
        case hint
        case inputMode = "input_mode"
        case expectedFormat = "expected_format"
        case validation
        case isSecret = "is_secret"
        case allowVoiceInput = "allow_voice_input"
    }
}

public struct TemplateVisibility: Codable, Sendable {
    public let registry: Bool?
    public let templates: Bool?
    public let wellKnown: Bool?
}

public struct Device: Codable, Sendable {
    public let id: String?
    public let deviceName: String?
    public let displayName: String?
    public let deviceType: String?
    public let description: String?
    public let category: String?
    public let tags: [String]?
    public let visibility: String?
    public let bluetoothUuid: String?
    public let status: String?
    public let version: String?
    public let isLatest: Bool?
    public let manufacturer: String?
    public let model: String?
    public let allowedAppIds: [String]?
    public let metadata: [String: AnyCodable]?
    public let createdAt: Double?
    public let updatedAt: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case deviceName = "device_name"
        case displayName = "display_name"
        case deviceType = "device_type"
        case description
        case category
        case tags
        case visibility
        case bluetoothUuid = "bluetooth_uuid"
        case status
        case version
        case isLatest = "is_latest"
        case manufacturer
        case model
        case allowedAppIds = "allowed_app_ids"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct DeviceInput: Codable, Sendable {
    public let deviceName: String
    public let displayName: String
    public let deviceType: String
    public let description: String?
    public let category: String?
    public let tags: [String]?
    public let visibility: String
    public let bluetoothUuid: String?
    public let status: String?
    public let version: String?
    public let isLatest: Bool?
    public let manufacturer: String?
    public let model: String?
    public let websiteUrl: String?
    public let docsUrl: String?
    public let supportUrl: String?
    public let appStoreUrls: [String: AnyCodable]?
    public let apple: String?
    public let google: String?
    public let iconUrl: String?
    public let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case deviceName = "device_name"
        case displayName = "display_name"
        case deviceType = "device_type"
        case description
        case category
        case tags
        case visibility
        case bluetoothUuid = "bluetooth_uuid"
        case status
        case version
        case isLatest = "is_latest"
        case manufacturer
        case model
        case websiteUrl = "website_url"
        case docsUrl = "docs_url"
        case supportUrl = "support_url"
        case appStoreUrls = "app_store_urls"
        case apple
        case google
        case iconUrl = "icon_url"
        case metadata
    }
}

public struct SubmissionReviewInput: Codable, Sendable {
    public let status: String
    public let reviewNotes: String?
    /// ISO8601 timestamp; optional override (defaults to approval +14 days)
    public let isNewUntil: String?
    public let reviewedBy: String?
    public let reviewedAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case reviewNotes = "review_notes"
        case isNewUntil = "is_new_until"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
    }
}

/// |
public struct SubmissionAdminUpdate: Codable, Sendable {
    public let status: String?
    public let reviewNotes: String?
    public let isNewUntil: String?
    public let action: String?
    public let message: String?
    public let templateName: String?
    public let templateType: String?
    public let integrationName: String?
    public let provider: String?
    public let createdByName: String?
    public let publicDescription: String?
    public let description: String?
    public let category: String?
    public let tags: [String]?
    public let maintainer: String?
    public let visibility: String?
    public let endpointPattern: String?
    public let endpointInputMode: String?
    public let endpointInputPlaceholder: String?
    public let showEndpointInput: Bool?
    public let showParameters: Bool?
    public let parameters: [TemplateParameter]?
    public let websiteUrl: String?
    public let docsUrl: String?
    public let supportUrl: String?
    public let appStoreUrls: [String: AnyCodable]?
    public let apple: String?
    public let google: String?
    public let iconUrl: String?
    public let priceTier: String?
    public let currentPrice: String?
    public let breakingChanges: String?
    public let supersedesVersion: String?
    public let contentType: String?
    public let authType: String?
    public let authLocation: String?
    public let requiresSignature: Bool?
    public let performAppInstallCheck: Bool?
    public let urlSchemeParamMode: String?
    public let deviceName: String?
    public let displayName: String?
    public let deviceType: String?
    public let allowedAppIds: [String]?
    public let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case status
        case reviewNotes = "review_notes"
        case isNewUntil = "is_new_until"
        case action
        case message
        case templateName = "template_name"
        case templateType = "template_type"
        case integrationName = "integration_name"
        case provider
        case createdByName = "created_by_name"
        case publicDescription = "public_description"
        case description
        case category
        case tags
        case maintainer
        case visibility
        case endpointPattern = "endpoint_pattern"
        case endpointInputMode = "endpoint_input_mode"
        case endpointInputPlaceholder = "endpoint_input_placeholder"
        case showEndpointInput = "show_endpoint_input"
        case showParameters = "show_parameters"
        case parameters
        case websiteUrl = "website_url"
        case docsUrl = "docs_url"
        case supportUrl = "support_url"
        case appStoreUrls = "app_store_urls"
        case apple
        case google
        case iconUrl = "icon_url"
        case priceTier = "price_tier"
        case currentPrice = "current_price"
        case breakingChanges = "breaking_changes"
        case supersedesVersion = "supersedes_version"
        case contentType = "content_type"
        case authType = "auth_type"
        case authLocation = "auth_location"
        case requiresSignature = "requires_signature"
        case performAppInstallCheck = "perform_app_install_check"
        case urlSchemeParamMode = "url_scheme_param_mode"
        case deviceName = "device_name"
        case displayName = "display_name"
        case deviceType = "device_type"
        case allowedAppIds = "allowed_app_ids"
        case metadata
    }
}

public struct Submission: Codable, Sendable {
    public let id: String?
    /// app/template/device
    public let type: String?
    public let status: String?
    public let reviewNotes: String?
    public let reviewedBy: String?
    public let reviewedAt: String?
    public let isNewUntil: String?
    public let approvedAt: String?
    public let statusType: String?
    public let generatedAppId: String?
    public let reviewedByName: String?
    public let lastSubmitterEmailStatus: String?
    public let lastSubmitterEmailAt: String?
    public let lastSubmitterEmailError: String?
    public let lastAdminEmailStatus: String?
    public let lastAdminEmailAt: String?
    public let lastAdminEmailError: String?
    public let thread: [SubmissionThreadEntry]?
    public let submittedAt: String?
    public let submittedByEmail: String?
    public let submittedByName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case status
        case reviewNotes = "review_notes"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
        case isNewUntil = "is_new_until"
        case approvedAt = "approved_at"
        case statusType = "status_type"
        case generatedAppId = "generated_app_id"
        case reviewedByName = "reviewed_by_name"
        case lastSubmitterEmailStatus = "last_submitter_email_status"
        case lastSubmitterEmailAt = "last_submitter_email_at"
        case lastSubmitterEmailError = "last_submitter_email_error"
        case lastAdminEmailStatus = "last_admin_email_status"
        case lastAdminEmailAt = "last_admin_email_at"
        case lastAdminEmailError = "last_admin_email_error"
        case thread
        case submittedAt = "submitted_at"
        case submittedByEmail = "submitted_by_email"
        case submittedByName = "submitted_by_name"
    }
}

public struct SubmissionReview: Codable, Sendable {
    public let status: String
    public let reviewNotes: String?
    public let reviewedBy: String?
    public let reviewedAt: String?
    public let isNewUntil: String?

    enum CodingKeys: String, CodingKey {
        case status
        case reviewNotes = "review_notes"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
        case isNewUntil = "is_new_until"
    }
}

public struct SubmissionThreadEntry: Codable, Sendable {
    public let author: String?
    public let authorName: String?
    public let role: String?
    public let type: String?
    public let status: String?
    public let message: String?
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case author
        case authorName = "author_name"
        case role
        case type
        case status
        case message
        case createdAt = "created_at"
    }
}

public struct Registry: Codable, Sendable {
    public let version: String?
    public let templates: [Template]?
    public let apps: [App]?
}
