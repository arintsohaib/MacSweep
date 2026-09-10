import Foundation

public enum ScanCategory: String, CaseIterable, Codable, Sendable, Identifiable, Comparable {
    case uninstalledAppRemnants
    case applicationCaches
    case applicationSupport
    case webStorage
    case logs
    case savedState
    case launchMetadata
    case developerCaches
    case largeFiles
    case reviewOnly

    public var id: String { rawValue }

    public var index: Int {
        Self.allCases.firstIndex(of: self) ?? .max
    }

    public static func < (lhs: ScanCategory, rhs: ScanCategory) -> Bool {
        lhs.index < rhs.index
    }

    public var displayName: String {
        switch self {
        case .uninstalledAppRemnants: "Uninstalled Apps"
        case .applicationCaches: "Caches"
        case .applicationSupport: "Application Support"
        case .webStorage: "Web Storage"
        case .logs: "Logs"
        case .savedState: "Saved State"
        case .launchMetadata: "Launch Metadata"
        case .developerCaches: "Developer"
        case .largeFiles: "Large Files"
        case .reviewOnly: "Protected / Review"
        }
    }
}
