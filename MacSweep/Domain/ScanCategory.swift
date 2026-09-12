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

    /// How a category behaves when the user selects an item for cleanup.
    public enum CleanupRisk: Sendable {
        /// Never cleaned: shown for information only.
        case informational
        /// Moved to the Trash only after explicit selection; items are not pre-selected.
        case review
    }

    public var cleanupRisk: CleanupRisk {
        switch self {
        case .uninstalledAppRemnants, .largeFiles, .reviewOnly:
            return .informational
        case .applicationCaches, .applicationSupport, .webStorage, .logs, .savedState, .launchMetadata, .developerCaches:
            return .review
        }
    }

    /// Short explanation of what the category scans, shown in Settings.
    public var settingsSummary: String {
        switch self {
        case .uninstalledAppRemnants:
            "Leftover sandbox containers and Application Support folders from apps you have removed."
        case .applicationCaches:
            "Per-application caches stored in ~/Library/Caches."
        case .applicationSupport:
            "Application data folders in ~/Library/Application Support."
        case .webStorage:
            "WebKit storage and HTTP cookies held per app or web site."
        case .logs:
            "Per-application log files in ~/Library/Logs."
        case .savedState:
            "Saved window and document state in ~/Library/Saved Application State."
        case .launchMetadata:
            "Login items and launch agents that start apps or background helpers."
        case .developerCaches:
            "Build caches: Xcode DerivedData, simulators, Homebrew, npm, Yarn, pip, Gradle, Playwright."
        case .largeFiles:
            "Files in ~/Downloads and ~/Desktop larger than your minimum size."
        case .reviewOnly:
            "Protected locations that are never cleaned."
        }
    }

    /// What cleanup means for the category and its risk, shown in Settings.
    public var settingsCleanupNote: String {
        switch self {
        case .uninstalledAppRemnants:
            "Informational only — never cleaned. Shared group containers, launch agents, and Apple/system data are excluded."
        case .applicationCaches:
            "Review risk, never pre-selected. Caches regenerate, but apps may be slower or re-download data on next launch."
        case .applicationSupport:
            "No scan rule in this version. Application Support is only reported as part of Uninstalled Apps findings."
        case .webStorage:
            "Review risk, never pre-selected. Removing this can sign you out of web sites and re-download assets."
        case .logs:
            "Review risk, never pre-selected. Diagnostic logs are low impact to remove."
        case .savedState:
            "Review risk, never pre-selected. Apps reopen with default windows on next launch."
        case .launchMetadata:
            "No scan rule in this version. Launch agents are excluded because updaters and helpers of installed apps cannot be told apart from abandoned ones."
        case .developerCaches:
            "Review risk, never pre-selected. Regenerable, but the next build or install is slower and re-downloads. Docker VM storage is protected."
        case .largeFiles:
            "Informational only — never cleaned. Personal files are yours to review and remove."
        case .reviewOnly:
            "Always protected. Shown for transparency."
        }
    }
}
