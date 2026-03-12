import Foundation

/// Structured error payload from the MagicApps API.
public struct ApiErrorPayload: Decodable {
    public let statusCode: Int?
    public let error: String?
    public let message: String?
    public let code: String?
    public let requestId: String?

    enum CodingKeys: String, CodingKey {
        case statusCode
        case error
        case message
        case code
        case requestId = "request_id"
    }
}

/// Base error type for all SDK errors.
public enum SdkError: Error, CustomStringConvertible {
    /// 401 Unauthorized - Authentication required or token expired.
    case unauthorized(String, ApiErrorPayload?)
    /// 403 Forbidden - Authenticated but insufficient permissions.
    case forbidden(String, ApiErrorPayload?)
    /// 404 Not Found - Resource does not exist.
    case notFound(String, ApiErrorPayload?)
    /// 429 Too Many Requests - Rate limit exceeded.
    case rateLimited(String, ApiErrorPayload?)
    /// 5xx Server Error.
    case serverError(Int, String, ApiErrorPayload?)
    /// Other API error with status code.
    case apiError(Int, String, ApiErrorPayload?)
    /// Network error - request failed before reaching server.
    case networkError(String, Error?)
    /// Configuration error.
    case configError(String)
    /// Platform error - module not available on current platform.
    case platformError(moduleName: String, currentPlatform: String, supportedPlatforms: [String])
    /// Certificate pinning failure - the server certificate did not match any pinned public key.
    /// This indicates a potential man-in-the-middle attack or a certificate rotation that
    /// requires updating the SDK's pin configuration. There is no silent fallback.
    case certificatePinningFailure(host: String)

    public var description: String {
        switch self {
        case .unauthorized(let msg, _): return "Unauthorized: \(msg)"
        case .forbidden(let msg, _): return "Forbidden: \(msg)"
        case .notFound(let msg, _): return "Not Found: \(msg)"
        case .rateLimited(let msg, _): return "Rate Limited: \(msg)"
        case .serverError(let status, let msg, _): return "Server Error (\(status)): \(msg)"
        case .apiError(let status, let msg, _): return "API Error (\(status)): \(msg)"
        case .networkError(let msg, _): return "Network Error: \(msg)"
        case .configError(let msg): return "Config Error: \(msg)"
        case .platformError(let name, let current, let supported):
            return "Platform Error: \(name) not available on \(current). Supported: \(supported.joined(separator: ", "))"
        case .certificatePinningFailure(let host):
            return "Certificate Pinning Failure: The server certificate for \(host) did not match any pinned public key. " +
                "This may indicate a man-in-the-middle attack or a certificate rotation. " +
                "Update your CertificatePinningConfig pins or contact support."
        }
    }

    /// Create a typed SdkError from a status code and payload.
    public static func from(status: Int, payload: ApiErrorPayload?) -> SdkError {
        let message = payload?.message ?? payload?.error ?? "Request failed with status \(status)"
        switch status {
        case 401: return .unauthorized(message, payload)
        case 403: return .forbidden(message, payload)
        case 404: return .notFound(message, payload)
        case 429: return .rateLimited(message, payload)
        case 500...599: return .serverError(status, message, payload)
        default: return .apiError(status, message, payload)
        }
    }
}
