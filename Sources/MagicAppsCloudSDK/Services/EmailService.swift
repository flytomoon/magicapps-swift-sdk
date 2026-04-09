import Foundation

// MARK: - Email Image Types

/// Request body for creating an email image token.
struct CreateImageTokenRequest: Encodable {
    let ttlSeconds: Int?
    let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case ttlSeconds = "ttl_seconds"
        case metadata
    }
}

/// Response from creating an email image token.
public struct CreateImageTokenResponse: Decodable {
    /// The generated token identifier.
    public let token: String
    /// The URL where the image will be served once uploaded.
    public let imageUrl: String
    /// Unix timestamp (seconds) when the token expires.
    public let expiresAt: Int

    enum CodingKeys: String, CodingKey {
        case token
        case imageUrl = "image_url"
        case expiresAt = "expires_at"
    }
}

/// Request body for uploading an image to a token.
struct UploadImageRequest: Encodable {
    let imageJpegBase64: String
    let transform: String?
    let query: String?
    let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case imageJpegBase64 = "image_jpeg_base64"
        case transform, query, metadata
    }
}

// MARK: - Email Text Types

/// Request body for creating an email text token.
struct CreateTextTokenRequest: Encodable {
    let ttlSeconds: Int?
    let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case ttlSeconds = "ttl_seconds"
        case metadata
    }
}

/// Response from creating an email text token.
public struct CreateTextTokenResponse: Decodable {
    /// The generated token identifier.
    public let token: String
    /// The URL where the text will be served once uploaded.
    public let textUrl: String
    /// Unix timestamp (seconds) when the token expires.
    public let expiresAt: Int

    enum CodingKeys: String, CodingKey {
        case token
        case textUrl = "text_url"
        case expiresAt = "expires_at"
    }
}

/// Request body for uploading text to a token.
///
/// The primary field is `sentence`, not `text`.
/// The backend ignores the `text` field — always use `sentence`.
struct UploadTextRequest: Encodable {
    let sentence: String
    let metadata: [String: AnyCodable]?
}

// MARK: - Email Token Status

/// Status of an email token (image or text).
public struct EmailTokenStatus: Decodable {
    /// The token identifier.
    public let token: String
    /// The type of token: `"image"` or `"text"`.
    public let type: String
    /// Current state of the token (e.g., `"pending"`, `"ready"`, `"consumed"`, `"expired"`).
    public let state: String
    /// Unix timestamp when the token became ready (content uploaded), if applicable.
    public let readyAt: Int?
    /// Unix timestamp when the token was consumed (content accessed), if applicable.
    public let consumedAt: Int?
    /// Unix timestamp when the token expires.
    public let expiresAt: Int?
    /// Unix timestamp of the last state change.
    public let updatedAt: Int?

    enum CodingKeys: String, CodingKey {
        case token, type, state
        case readyAt = "ready_at"
        case consumedAt = "consumed_at"
        case expiresAt = "expires_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Email Service

/// Email image and text service module.
///
/// Wraps the email_images Lambda endpoints for creating tokens,
/// uploading image/text content, and checking token status.
///
/// All methods use `.owner` authentication.
/// Available on all platforms.
public class EmailService: ServiceModule {
    public let name = "email"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Create a token for an email image.
    ///
    /// The returned `imageUrl` is the URL where the image will be publicly
    /// accessible once uploaded via ``uploadImage(token:imageData:transform:query:metadata:)``.
    ///
    /// - Parameters:
    ///   - ttlSeconds: Optional time-to-live in seconds for the token.
    ///   - metadata: Optional metadata dictionary to attach to the token.
    /// - Returns: The created token, image URL, and expiration timestamp.
    public func createImageToken(
        ttlSeconds: Int? = nil,
        metadata: [String: AnyCodable]? = nil
    ) async throws -> CreateImageTokenResponse {
        let body = CreateImageTokenRequest(ttlSeconds: ttlSeconds, metadata: metadata)
        return try await http.post(
            "/apps/\(http.appId)/routines/email-image/tokens",
            body: body,
            authMode: .owner
        )
    }

    /// Upload a JPEG image to a previously created image token.
    ///
    /// The `imageData` parameter accepts raw JPEG bytes as `Data`.
    /// This SDK intentionally does **not** accept `UIImage` because it targets
    /// all Apple platforms (macOS, tvOS, watchOS), not just iOS.
    /// Callers should convert `UIImage` to JPEG `Data` themselves:
    /// ```swift
    /// let jpegData = myUIImage.jpegData(compressionQuality: 0.8)!
    /// try await client.email.uploadImage(token: tok, imageData: jpegData)
    /// ```
    ///
    /// - Parameters:
    ///   - token: The image token returned by ``createImageToken(ttlSeconds:metadata:)``.
    ///   - imageData: Raw JPEG bytes. Do **not** pass a `UIImage` — convert to `Data` first.
    ///   - transform: Optional transform mode. When omitted or `"image"`, the raw JPEG is served.
    ///                 Other transform values may resize or reformat the image.
    ///   - query: Optional query string for transform parameters.
    ///            **Required** when `transform` is not `"image"` — the query tells the
    ///            server how to apply the transform.
    ///   - metadata: Optional metadata dictionary to attach to the upload.
    public func uploadImage(
        token: String,
        imageData: Data,
        transform: String? = nil,
        query: String? = nil,
        metadata: [String: AnyCodable]? = nil
    ) async throws {
        let base64 = imageData.base64EncodedString()
        let body = UploadImageRequest(
            imageJpegBase64: base64,
            transform: transform,
            query: query,
            metadata: metadata
        )
        let _: EmptyResponse = try await http.post(
            "/apps/\(http.appId)/routines/email-image/\(token)",
            body: body,
            authMode: .owner
        )
    }

    /// Create a token for email text content.
    ///
    /// The returned `textUrl` is the URL where the text will be publicly
    /// accessible once uploaded via ``uploadText(token:sentence:metadata:)``.
    ///
    /// - Parameters:
    ///   - ttlSeconds: Optional time-to-live in seconds for the token.
    ///   - metadata: Optional metadata dictionary to attach to the token.
    /// - Returns: The created token, text URL, and expiration timestamp.
    public func createTextToken(
        ttlSeconds: Int? = nil,
        metadata: [String: AnyCodable]? = nil
    ) async throws -> CreateTextTokenResponse {
        let body = CreateTextTokenRequest(ttlSeconds: ttlSeconds, metadata: metadata)
        return try await http.post(
            "/apps/\(http.appId)/routines/email-text/tokens",
            body: body,
            authMode: .owner
        )
    }

    /// Upload text content to a previously created text token.
    ///
    /// The primary field is `sentence` — the backend ignores the `text` field.
    ///
    /// - Parameters:
    ///   - token: The text token returned by ``createTextToken(ttlSeconds:metadata:)``.
    ///   - sentence: The text content to upload.
    ///   - metadata: Optional metadata dictionary to attach to the upload.
    public func uploadText(
        token: String,
        sentence: String,
        metadata: [String: AnyCodable]? = nil
    ) async throws {
        let body = UploadTextRequest(sentence: sentence, metadata: metadata)
        let _: EmptyResponse = try await http.post(
            "/apps/\(http.appId)/routines/email-text/\(token)",
            body: body,
            authMode: .owner
        )
    }

    /// Check the status of an email token (image or text).
    ///
    /// Returns the token's current state, type, and lifecycle timestamps.
    ///
    /// - Parameter token: The token identifier to check.
    /// - Returns: The token's status including state, type, and timestamps.
    public func getTokenStatus(token: String) async throws -> EmailTokenStatus {
        return try await http.get(
            "/apps/\(http.appId)/routines/email-status/\(token)",
            authMode: .owner
        )
    }

    /// Send tokenized content via email.
    ///
    /// - Parameters:
    ///   - to: The recipient email address.
    ///   - token: The content token (image or text) to include in the email.
    ///   - subject: The email subject line.
    ///   - senderName: Optional display name for the sender.
    /// - Returns: The send result including message ID and status.
    public func send(
        to: String,
        token: String,
        subject: String,
        senderName: String? = nil
    ) async throws -> EmailSendResponse {
        var body: [String: AnyCodable] = [
            "to": AnyCodable(to),
            "token": AnyCodable(token),
            "subject": AnyCodable(subject),
        ]
        if let name = senderName {
            body["sender_name"] = AnyCodable(name)
        }
        return try await http.post(
            "/apps/\(http.appId)/routines/email-send",
            body: body,
            authMode: .owner
        )
    }
}

/// Response from sending an email.
public struct EmailSendResponse: Decodable {
    /// The SES message identifier.
    public let messageId: String
    /// The delivery status (e.g., `"sent"`).
    public let status: String

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case status
    }
}
