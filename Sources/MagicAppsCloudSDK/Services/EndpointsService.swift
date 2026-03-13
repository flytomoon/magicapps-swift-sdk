import Foundation
import CommonCrypto

// MARK: - Endpoint Types

/// Response from creating a new webhook endpoint.
public struct CreateEndpointResponse: Decodable {
    public let slug: String
    public let status: String
    public let expiresAt: Int
    public let endpointPath: String
    public let hmacSecret: String?
    public let hmacRequired: Bool?

    enum CodingKeys: String, CodingKey {
        case slug, status
        case expiresAt = "expires_at"
        case endpointPath = "endpoint_path"
        case hmacSecret = "hmac_secret"
        case hmacRequired = "hmac_required"
    }
}

/// Response from revoking and replacing an endpoint.
public struct RevokeAndReplaceResponse: Decodable {
    public let oldSlug: String
    public let newSlug: String
    public let newEndpointPath: String
    public let revokedExpiresAt: Int
    public let newExpiresAt: Int
    public let hmacSecret: String?
    public let hmacRequired: Bool?

    enum CodingKeys: String, CodingKey {
        case oldSlug = "old_slug"
        case newSlug = "new_slug"
        case newEndpointPath = "new_endpoint_path"
        case revokedExpiresAt = "revoked_expires_at"
        case newExpiresAt = "new_expires_at"
        case hmacSecret = "hmac_secret"
        case hmacRequired = "hmac_required"
    }
}

/// Response from revoking an endpoint.
public struct RevokeEndpointResponse: Decodable {
    public let slug: String
    public let revoked: Bool
}

/// Response from posting an event to a slug.
public struct PostEventResponse: Decodable {
    public let slug: String
    public let timestamp: Int
    public let expiresAt: Int

    enum CodingKeys: String, CodingKey {
        case slug, timestamp
        case expiresAt = "expires_at"
    }
}

/// A consumed event from an endpoint slug.
public struct ConsumedEvent: Decodable {
    public let slug: String
    public let timestamp: Int?
    public let createdAt: Int?
    public let expiresAt: Int?
    public let text: String?
    public let keywords: [String]?
    public let rawText: String?
    public let metadata: [String: AnyCodable]?
    public let empty: Bool?

    enum CodingKeys: String, CodingKey {
        case slug, timestamp, text, keywords, metadata, empty
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case rawText = "raw_text"
    }
}

// MARK: - HMAC Helpers

/// HMAC signature headers for authenticated event delivery.
public struct HmacSignatureHeaders {
    public let signature: String
    public let timestamp: String
}

/// Generate HMAC signature headers for posting a signed event.
///
/// The signature is computed as: HMAC-SHA256(secret, "slug:timestamp:body")
///
/// - Parameters:
///   - slug: The endpoint slug
///   - body: The JSON body string being sent
///   - secret: The HMAC secret from the endpoint
///   - timestampSec: Optional Unix timestamp in seconds (defaults to now)
/// - Returns: HmacSignatureHeaders with signature and timestamp
public func generateHmacSignature(
    slug: String,
    body: String,
    secret: String,
    timestampSec: Int? = nil
) -> HmacSignatureHeaders {
    let ts = timestampSec ?? Int(Date().timeIntervalSince1970)
    let message = "\(slug):\(ts):\(body)"
    let signature = hmacSHA256(key: secret, message: message)
    return HmacSignatureHeaders(signature: signature, timestamp: String(ts))
}

/// Verify an HMAC signature on an incoming webhook payload.
///
/// - Parameters:
///   - slug: The endpoint slug
///   - body: The raw body string received
///   - signature: The X-Signature header value
///   - timestamp: The X-Timestamp header value
///   - secret: The HMAC secret for this endpoint
///   - maxSkewSeconds: Maximum allowed clock skew in seconds (default: 300)
/// - Returns: true if the signature is valid and timestamp is within range
public func verifyHmacSignature(
    slug: String,
    body: String,
    signature: String,
    timestamp: String,
    secret: String,
    maxSkewSeconds: Int = 300
) -> Bool {
    guard let ts = Int(timestamp) else { return false }
    let nowSec = Int(Date().timeIntervalSince1970)
    guard abs(nowSec - ts) <= maxSkewSeconds else { return false }

    let message = "\(slug):\(ts):\(body)"
    let expected = hmacSHA256(key: secret, message: message)

    // Constant-time comparison
    guard expected.count == signature.count else { return false }
    let expectedBytes = Array(expected.utf8)
    let signatureBytes = Array(signature.utf8)
    var mismatch: UInt8 = 0
    for i in 0..<expectedBytes.count {
        mismatch |= expectedBytes[i] ^ signatureBytes[i]
    }
    return mismatch == 0
}

private func hmacSHA256(key: String, message: String) -> String {
    let keyData = Array(key.utf8)
    let messageData = Array(message.utf8)
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyData, keyData.count, messageData, messageData.count, &digest)

    return digest.map { String(format: "%02x", $0) }.joined()
}

// MARK: - Endpoints Service

/// Endpoints and Events service module.
/// Manages webhook endpoints and event consumption via the platform's
/// slug-based endpoint system.
/// Available on all platforms.
public class EndpointsService: ServiceModule {
    public let name = "endpoints"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Create a new webhook endpoint.
    /// Returns the slug, endpoint_path, and optionally an hmac_secret.
    public func create() async throws -> CreateEndpointResponse {
        return try await http.post("/apps/\(http.appId)/endpoints", body: EmptyBody(), authMode: .owner)
    }

    /// Revoke an existing endpoint and create a replacement.
    /// The old slug enters a grace period before full removal.
    public func revokeAndReplace(oldSlug: String) async throws -> RevokeAndReplaceResponse {
        let body = "{\"old_slug\":\"\(oldSlug)\"}"
        return try await http.post("/apps/\(http.appId)/endpoints/revoke_and_replace", bodyString: body, authMode: .owner)
    }

    /// Revoke an endpoint without creating a replacement.
    public func revoke(slug: String) async throws -> RevokeEndpointResponse {
        let body = "{\"slug\":\"\(slug)\"}"
        return try await http.post("/apps/\(http.appId)/endpoints/revoke", bodyString: body, authMode: .owner)
    }

    /// Post an event to an endpoint slug.
    /// Optionally include HMAC signature headers for authenticated delivery.
    public func postEvent(slug: String, payload: [String: AnyCodable], hmacSecret: String? = nil) async throws -> PostEventResponse {
        let encoder = JSONEncoder()
        let payloadData = try encoder.encode(payload)
        let payloadString = String(data: payloadData, encoding: .utf8) ?? "{}"

        var headers: [String: String]? = nil
        if let secret = hmacSecret {
            let sig = generateHmacSignature(slug: slug, body: payloadString, secret: secret)
            headers = [
                "X-Signature": sig.signature,
                "X-Timestamp": sig.timestamp
            ]
        }

        return try await http.post("/events/\(slug)", bodyString: payloadString, authMode: .none, headers: headers)
    }

    /// Consume an event from an endpoint slug (single-slot, consume-on-read).
    /// The event is deleted from the server after being read.
    public func consumeEvent(slug: String) async throws -> ConsumedEvent {
        return try await http.get("/events/\(slug)", authMode: .none)
    }
}

// EmptyBody is defined in AuthService.swift
