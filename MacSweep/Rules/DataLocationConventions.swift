import Foundation

public enum DataLocationConventions {
    public static func url(
        location: DataLocation,
        libraryDirectory: URL,
        bundleID: BundleIdentifier,
        folderName: String
    ) -> URL {
        switch location {
        case .applicationSupport:
            return libraryDirectory
                .appendingPathComponent("Application Support", isDirectory: true)
                .appendingPathComponent(folderName, isDirectory: true)
        case .caches:
            return libraryDirectory
                .appendingPathComponent("Caches", isDirectory: true)
                .appendingPathComponent(folderName, isDirectory: true)
        case .container:
            return libraryDirectory
                .appendingPathComponent("Containers", isDirectory: true)
                .appendingPathComponent(bundleID.rawValue, isDirectory: true)
        case .groupContainer:
            return libraryDirectory
                .appendingPathComponent("Group Containers", isDirectory: true)
                .appendingPathComponent(bundleID.rawValue, isDirectory: true)
        case .preferences:
            return libraryDirectory
                .appendingPathComponent("Preferences", isDirectory: true)
                .appendingPathComponent(bundleID.rawValue + ".plist")
        case .webKit:
            return libraryDirectory
                .appendingPathComponent("WebKit", isDirectory: true)
                .appendingPathComponent(bundleID.rawValue, isDirectory: true)
        case .httpStorages:
            return libraryDirectory
                .appendingPathComponent("HTTPStorages", isDirectory: true)
                .appendingPathComponent(bundleID.rawValue)
        case .savedState:
            return libraryDirectory
                .appendingPathComponent("Saved Application State", isDirectory: true)
                .appendingPathComponent(bundleID.rawValue + ".savedState")
        case .logs:
            return libraryDirectory
                .appendingPathComponent("Logs", isDirectory: true)
                .appendingPathComponent(folderName, isDirectory: true)
        case .launchAgents:
            return libraryDirectory
                .appendingPathComponent("LaunchAgents", isDirectory: true)
                .appendingPathComponent(bundleID.rawValue + ".plist")
        }
    }
}
