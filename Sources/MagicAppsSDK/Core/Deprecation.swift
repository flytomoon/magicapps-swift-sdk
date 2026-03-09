import Foundation

/// Metadata describing a deprecated SDK method.
///
/// Used to track deprecation history for documentation and migration guides.
///
/// Example:
/// ```swift
/// // The Swift SDK uses @available(*, deprecated) for compile-time warnings.
/// // This struct provides runtime metadata for tooling and documentation.
/// let info = DeprecationInfo(
///     methodName: "fetchApp",
///     since: "0.2.0",
///     message: "Use getAppInfo() instead",
///     removeIn: "1.0.0"
/// )
/// ```
public struct DeprecationInfo: Sendable {
    /// The name of the deprecated method.
    public let methodName: String
    /// The SDK version in which this method was deprecated.
    public let since: String
    /// Migration hint explaining what to use instead.
    public let message: String
    /// Optional version in which this method will be removed.
    public let removeIn: String?

    public init(methodName: String, since: String, message: String, removeIn: String? = nil) {
        self.methodName = methodName
        self.since = since
        self.message = message
        self.removeIn = removeIn
    }
}

/// Registry of deprecated methods in the Swift SDK.
///
/// Provides a central catalog of all deprecated methods for tooling,
/// documentation generation, and migration guide automation.
///
/// The Swift SDK primarily uses `@available(*, deprecated, message:)` for
/// compile-time deprecation warnings. This registry complements that with
/// runtime metadata including version info and removal timeline.
public enum DeprecationRegistry {
    /// All deprecated methods in the current SDK version.
    public static let entries: [DeprecationInfo] = [
        // Example entry (uncomment when actual deprecations exist):
        // DeprecationInfo(
        //     methodName: "fetchApp()",
        //     since: "0.2.0",
        //     message: "Use getAppInfo() instead",
        //     removeIn: "1.0.0"
        // ),
    ]

    /// Get deprecation info for a specific method.
    /// - Parameter methodName: The method name to look up.
    /// - Returns: The deprecation info, or nil if the method is not deprecated.
    public static func info(for methodName: String) -> DeprecationInfo? {
        return entries.first { $0.methodName == methodName }
    }

    /// All methods scheduled for removal in a given version.
    /// - Parameter version: The version to check.
    /// - Returns: Array of deprecation entries scheduled for removal in that version.
    public static func scheduledForRemoval(in version: String) -> [DeprecationInfo] {
        return entries.filter { $0.removeIn == version }
    }
}
