import Foundation

// MARK: - Lookup Table Types

// LookupTableSummary, LookupTableChunk, and LookupTableDetail types
// are defined in GeneratedTypes.swift

/// Response from listing lookup tables.
public struct LookupTableListResponse: Decodable {
    public let items: [LookupTableSummary]
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

        let count = detail.chunkCount ?? 0
        for i in 0..<count {
            let chunk = try await getChunk(lookupTableId: lookupTableId, chunkIndex: i, version: detail.version)
            for (key, value) in chunk {
                result[key] = value
            }
        }

        return result
    }
}
