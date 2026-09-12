import Foundation

public struct UserSettings: Codable, Sendable, Equatable {
    /// Bump when a migration should run on load.
    public static let currentVersion = 2

    public var version: Int
    public var enabledCategories: Set<ScanCategory>
    public var minLargeFileSize: Int64
    public var excludedPaths: [String]
    public var confirmBeforeCleanup: Bool

    public init(
        version: Int = UserSettings.currentVersion,
        enabledCategories: Set<ScanCategory> = CleanupMode.basic.scanCategories,
        minLargeFileSize: Int64 = 512 * 1024 * 1024,
        excludedPaths: [String] = [],
        confirmBeforeCleanup: Bool = true
    ) {
        self.version = version
        self.enabledCategories = enabledCategories
        self.minLargeFileSize = minLargeFileSize
        self.excludedPaths = excludedPaths
        self.confirmBeforeCleanup = confirmBeforeCleanup
    }

    public static var `default`: UserSettings {
        UserSettings()
    }

    /// Migrates pre-0.4.0 settings that enabled every scan category to the safer
    /// Basic profile. Users can re-enable advanced categories in Settings or by
    /// choosing Advanced Clean.
    public func migratedToCurrentVersion() -> UserSettings {
        guard version < Self.currentVersion else { return self }
        var updated = self
        updated.version = Self.currentVersion
        updated.enabledCategories = CleanupMode.basic.scanCategories
        return updated
    }
}
