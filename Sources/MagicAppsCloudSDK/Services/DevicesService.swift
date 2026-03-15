import Foundation

// MARK: - Device Types

// Device type is defined in GeneratedTypes.swift

/// Response from the device catalog endpoint.
public struct DeviceCatalogResponse: Decodable {
    public let devices: [Device]?
    public let items: [Device]?
    public let count: Int?

    /// Convenience accessor that returns devices from whichever field the API uses.
    public var allDevices: [Device] {
        return devices ?? items ?? []
    }
}

// MARK: - Devices Service (All Platforms)

/// Devices service module.
/// Provides read-only access to the merged device catalog
/// including hardcoded, catalog, and user-submitted devices.
/// Available on all platforms.
public class DevicesService: ServiceModule {
    public let name = "devices"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Fetch the device catalog for the current app.
    /// Returns the merged catalog combining hardcoded, catalog, and user-submitted devices.
    ///
    /// - Returns: The device catalog response with all devices.
    public func list() async throws -> DeviceCatalogResponse {
        return try await http.get("/apps/\(http.appId)/devices", authMode: .none)
    }

    /// Convenience: get a flat list of all devices.
    public func getAll() async throws -> [Device] {
        let response = try await list()
        return response.allDevices
    }
}
