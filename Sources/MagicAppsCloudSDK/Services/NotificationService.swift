import Foundation

// MARK: - Notification Types

/// Request body for registering a device for push notifications.
public struct RegisterDeviceRequest: Encodable {
    public let token: String
    public let platform: String
    public let deviceId: String

    enum CodingKeys: String, CodingKey {
        case token
        case platform
        case deviceId = "device_id"
    }

    public init(token: String, platform: String, deviceId: String) {
        self.token = token
        self.platform = platform
        self.deviceId = deviceId
    }
}

/// Response from registering a device for push notifications.
public struct RegisterDeviceResponse: Decodable {
    public let success: Bool?
    public let deviceId: String?
    public let message: String?

    enum CodingKeys: String, CodingKey {
        case success
        case deviceId = "device_id"
        case message
    }
}

/// Response from unregistering a device.
public struct UnregisterDeviceResponse: Decodable {
    public let success: Bool?
    public let message: String?
}

// MARK: - Notification Service (All Platforms)

/// Push notification registration service module.
/// Provides device registration and unregistration for push notifications.
/// Available on all platforms.
public class NotificationService: ServiceModule {
    public let name = "notifications"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Register a device for push notifications.
    ///
    /// - Parameters:
    ///   - token: The push notification token (APNs token or FCM token).
    ///   - platform: The platform identifier (e.g., "ios", "android").
    ///   - deviceId: A unique identifier for the device.
    /// - Returns: A response indicating whether the registration was successful.
    public func registerDevice(
        token: String,
        platform: String,
        deviceId: String
    ) async throws -> RegisterDeviceResponse {
        let body = RegisterDeviceRequest(token: token, platform: platform, deviceId: deviceId)
        return try await http.post("/apps/\(http.appId)/notifications/register", body: body)
    }

    /// Unregister a device from push notifications.
    ///
    /// - Parameter deviceId: The device ID to unregister.
    /// - Returns: A response indicating whether the unregistration was successful.
    public func unregisterDevice(deviceId: String) async throws -> UnregisterDeviceResponse {
        let encoded = deviceId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? deviceId
        return try await http.delete("/apps/\(http.appId)/notifications/register/\(encoded)")
    }
}
