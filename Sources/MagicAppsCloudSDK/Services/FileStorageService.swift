import Foundation

// MARK: - File Storage Types

/// Request body for getting an upload URL.
public struct GetUploadUrlRequest: Encodable {
    public let filename: String
    public let contentType: String

    enum CodingKeys: String, CodingKey {
        case filename
        case contentType = "content_type"
    }

    public init(filename: String, contentType: String) {
        self.filename = filename
        self.contentType = contentType
    }
}

/// Response from requesting an upload URL.
public struct GetUploadUrlResponse: Decodable {
    public let uploadUrl: String?
    public let fileId: String?
    public let key: String?
    public let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case uploadUrl = "upload_url"
        case fileId = "file_id"
        case key
        case expiresIn = "expires_in"
    }
}

/// A user file record.
public struct UserFile: Decodable {
    public let fileId: String?
    public let filename: String?
    public let contentType: String?
    public let size: Int?
    public let url: String?
    public let createdAt: Double?
    public let updatedAt: Double?

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case filename
        case contentType = "content_type"
        case size
        case url
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Response from listing user files.
public struct ListFilesResponse: Decodable {
    public let files: [UserFile]?
    public let items: [UserFile]?

    /// Convenience accessor that returns files from whichever field the API uses.
    public var allFiles: [UserFile] {
        return files ?? items ?? []
    }
}

/// Response from deleting a file.
public struct DeleteFileResponse: Decodable {
    public let success: Bool?
    public let message: String?
}

// MARK: - File Storage Service (All Platforms)

/// File storage service module.
/// Provides file upload URL generation, listing, retrieval, and deletion.
/// Available on all platforms.
public class FileStorageService: ServiceModule {
    public let name = "files"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Get a pre-signed upload URL for a new file.
    ///
    /// Use the returned URL to upload the file directly to storage via HTTP PUT.
    ///
    /// - Parameters:
    ///   - filename: The name of the file to upload.
    ///   - contentType: The MIME type of the file (e.g., "image/jpeg").
    /// - Returns: A response containing the upload URL and file ID.
    public func getUploadUrl(filename: String, contentType: String) async throws -> GetUploadUrlResponse {
        let body = GetUploadUrlRequest(filename: filename, contentType: contentType)
        return try await http.post("/apps/\(http.appId)/files/upload-url", body: body)
    }

    /// List all files for the authenticated user.
    ///
    /// - Returns: A response containing the user's files.
    public func listFiles() async throws -> ListFilesResponse {
        return try await http.get("/apps/\(http.appId)/files")
    }

    /// Get metadata for a specific file.
    ///
    /// - Parameter fileId: The ID of the file to retrieve.
    /// - Returns: The file metadata.
    public func getFile(fileId: String) async throws -> UserFile {
        let encoded = fileId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileId
        return try await http.get("/apps/\(http.appId)/files/\(encoded)")
    }

    /// Delete a file.
    ///
    /// - Parameter fileId: The ID of the file to delete.
    /// - Returns: A response indicating whether the deletion was successful.
    public func deleteFile(fileId: String) async throws -> DeleteFileResponse {
        let encoded = fileId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileId
        return try await http.delete("/apps/\(http.appId)/files/\(encoded)")
    }
}
