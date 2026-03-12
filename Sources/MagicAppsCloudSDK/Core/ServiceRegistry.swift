import Foundation

/// Platform identifiers for conditional module availability.
public enum SdkPlatform: String, CaseIterable {
    case ios
    case android
    case web
}

/// Protocol that all service modules implement.
public protocol ServiceModule {
    /// The name of this service module.
    var name: String { get }
    /// Platforms this module is available on (empty = all platforms).
    var platforms: [SdkPlatform] { get }
}

/// Registry that manages service modules and enforces platform-conditional availability.
public class ServiceRegistry {
    private var modules: [String: any ServiceModule] = [:]
    private let platform: SdkPlatform

    init(platform: SdkPlatform) {
        self.platform = platform
    }

    /// Register a service module.
    func register(_ module: any ServiceModule) {
        modules[module.name] = module
    }

    /// Get a registered service module by name.
    /// Throws PlatformError if the module is not available on the current platform.
    func get<T: ServiceModule>(_ name: String) throws -> T? {
        guard let module = modules[name] else { return nil }

        if !module.platforms.isEmpty && !module.platforms.contains(platform) {
            throw SdkError.platformError(
                moduleName: name,
                currentPlatform: platform.rawValue,
                supportedPlatforms: module.platforms.map(\.rawValue)
            )
        }

        return module as? T
    }

    /// Check if a module is available on the current platform.
    func has(_ name: String) -> Bool {
        guard let module = modules[name] else { return false }
        if !module.platforms.isEmpty && !module.platforms.contains(platform) {
            return false
        }
        return true
    }

    /// List all modules available on the current platform.
    func listAvailable() -> [any ServiceModule] {
        modules.values.filter { module in
            module.platforms.isEmpty || module.platforms.contains(platform)
        }
    }

    /// Get the current platform.
    func getPlatform() -> SdkPlatform {
        return platform
    }
}
