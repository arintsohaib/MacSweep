import Foundation

/// A high-level cleanup intent offered on the Overview.
///
/// MacSweep always recommends and the user always decides: a mode only chooses
/// which categories are scanned and (for Basic) which regenerable items are
/// pre-selected. Every item still has to be confirmed in the review sheet
/// before anything is moved to the Trash.
public enum CleanupMode: String, CaseIterable, Sendable, Identifiable {
    /// Safe, regenerable storage only: caches and logs. Leftovers and large
    /// files are shown for review but are never selected or cleaned.
    case basic
    /// Every category, including developer caches, web storage and saved state.
    /// Nothing is pre-selected or removed without review.
    case advanced

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .basic: "Basic Clean"
        case .advanced: "Advanced Clean"
        }
    }

    public var systemImage: String {
        switch self {
        case .basic: "sparkles"
        case .advanced: "slider.horizontal.3"
        }
    }

    public var summary: String {
        switch self {
        case .basic:
            "Reclaims caches and logs that regenerate on their own. Uninstalled-app leftovers and large files are shown for review only — nothing personal or system-owned is removed."
        case .advanced:
            "Scans every category, including developer caches, web storage and saved state. Nothing is removed until you review and confirm; removing them can slow the next build or sign you out of web sites."
        }
    }

    /// Categories scanned for this mode.
    public var scanCategories: Set<ScanCategory> {
        switch self {
        case .basic:
            [.applicationCaches, .logs, .uninstalledAppRemnants, .largeFiles]
        case .advanced:
            Set(ScanCategory.allCases)
        }
    }

    /// Categories whose items may be pre-selected after a Basic scan. These are
    /// regenerable and cause no data loss. Empty for Advanced.
    public var autoSelectCategories: Set<ScanCategory> {
        switch self {
        case .basic: [.applicationCaches, .logs]
        case .advanced: []
        }
    }
}
