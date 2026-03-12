import Foundation

// MARK: - Lookup Table Types

/// Summary of a lookup table (returned in list responses).
public struct LookupTableSummary: Decodable {
    public let lookupTableId: String
    public let name: String
    public let description: String?
    public let schemaKeys: [String]
    public let schemaKeyCount: Int
    public let schemaKeysTruncated: Bool
    public let version: Int
    public let payloadHash: String
    public let storageMode: String
    public let chunkCount: Int
    public let updatedAt: Int

    enum CodingKeys: String, CodingKey {
        case lookupTableId = "lookup_table_id"
        case name, description
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

/// Response from listing lookup tables.
public struct LookupTableListResponse: Decodable {
    public let items: [LookupTableSummary]
}

/// A reference to an individual data chunk in a lookup table.
public struct LookupTableChunkRef: Decodable {
    public let index: Int
    public let path: String
    public let sha256: String
    public let byteLength: Int

    enum CodingKeys: String, CodingKey {
        case index, path, sha256
        case byteLength = "byte_length"
    }
}

/// Detailed lookup table metadata including chunk references.
public struct LookupTableDetail: Decodable {
    public let lookupTableId: String
    public let name: String
    public let description: String?
    public let schemaKeys: [String]
    public let schemaKeyCount: Int
    public let schemaKeysTruncated: Bool
    public let version: Int
    public let payloadHash: String
    public let storageMode: String
    public let chunkCount: Int
    public let updatedAt: Int
    public let prompt: String?
    public let defaultSuccessSentence: String?
    public let defaultFailSentence: String?
    public let chunkEncoding: String
    public let manifestHash: String
    public let chunks: [LookupTableChunkRef]

    enum CodingKeys: String, CodingKey {
        case lookupTableId = "lookup_table_id"
        case name, description
        case schemaKeys = "schema_keys"
        case schemaKeyCount = "schema_key_count"
        case schemaKeysTruncated = "schema_keys_truncated"
        case version
        case payloadHash = "payload_hash"
        case storageMode = "storage_mode"
        case chunkCount = "chunk_count"
        case updatedAt = "updated_at"
        case prompt
        case defaultSuccessSentence = "default_success_sentence"
        case defaultFailSentence = "default_fail_sentence"
        case chunkEncoding = "chunk_encoding"
        case manifestHash = "manifest_hash"
        case chunks
    }
}

// MARK: - Lookup Tables Service

/// Lookup Tables service module.
/// Provides read-only access to lookup tables for client apps.
/// Lookup tables are created and managed in the tenant console;
/// client apps consume them via this SDK for reference data like
/// product catalogs, configuration lists, etc.
/// Available on all platforms.
public class LookupTablesService: ServiceModule {
    public let name = "lookup-tables"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// List all available lookup tables for the current app.
    public func list() async throws -> LookupTableListResponse {
        return try await http.get("/lookup-tables", authMode: .owner)
    }

    /// Get a specific lookup table's metadata by ID.
    /// Includes chunk references for downloading data.
    public func get(lookupTableId: String) async throws -> LookupTableDetail {
        let encoded = lookupTableId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? lookupTableId
        return try await http.get("/lookup-tables/\(encoded)", authMode: .owner)
    }

    /// Fetch an individual data chunk by index.
    ///
    /// - Parameters:
    ///   - lookupTableId: The lookup table ID
    ///   - chunkIndex: Zero-based chunk index
    ///   - version: Optional version number for cache consistency
    public func getChunk(lookupTableId: String, chunkIndex: Int, version: Int? = nil) async throws -> [String: AnyCodable] {
        let encoded = lookupTableId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? lookupTableId
        var query: [String: String]? = nil
        if let version {
            query = ["version": String(version)]
        }
        return try await http.get("/lookup-tables/\(encoded)/chunks/\(chunkIndex)", query: query, authMode: .owner)
    }

    /// Convenience method that fetches all chunks for a table and assembles
    /// the complete dataset by merging all chunk data objects.
    ///
    /// - Parameter lookupTableId: The lookup table ID
    /// - Returns: The complete dataset as a merged dictionary
    public func getFullDataset(lookupTableId: String) async throws -> [String: AnyCodable] {
        let detail = try await get(lookupTableId: lookupTableId)
        var result: [String: AnyCodable] = [:]

        for i in 0..<detail.chunkCount {
            let chunk = try await getChunk(lookupTableId: lookupTableId, chunkIndex: i, version: detail.version)
            for (key, value) in chunk {
                result[key] = value
            }
        }

        return result
    }
}
