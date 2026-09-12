import Foundation

public struct UserSettings: Codable, Sendable, Equatable {
    public var version: Int
    public var enabledCategories: Set<ScanCategory>
    public var minLargeFileSize: Int64
    public var excludedPaths: [String]
    public var confirmBeforeCleanup: Bool

    public init(
        version: Int = 1,
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
}
