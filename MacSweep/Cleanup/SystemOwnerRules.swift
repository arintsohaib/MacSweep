import Foundation

/// Classifies bundle identifiers that belong to macOS itself, or to MacSweep,
/// and therefore must never be treated as removable application leftovers.
///
/// "Uninstalled application" detection relies on the absence of an installed
/// app bundle, but macOS ships hundreds of background agents, daemons,
/// frameworks, and internal components that have no app bundle in the standard
/// application folders. Treating those as leftovers and moving their data to
/// the Trash destroys system configuration (default apps, Finder/Dock prefs,
/// notification and sharing state, ...), which macOS then silently resets.
/// This guard is the single source of truth for "owned by the system".
public enum SystemOwnerRules {
    /// MacSweep's own bundle identifier prefix. The app must never touch its own data.
    public static let selfBundlePrefix = "com.macsweep."

    /// Apple and core-OS bundle identifier prefixes that are never user data.
    private static let systemPrefixes: [String] = [
        "com.apple.",
        "com.apple",
        "org.cups.",
        "com.openssh.",
        "com.apple.security.",
    ]

    /// True for Apple/system-owned identifiers and for MacSweep itself.
    public static func isSystemOwned(bundleID: String) -> Bool {
        var identifier = bundleID.lowercased()
        // Group containers are named "group.<bundle id>"; normalise to the owner id.
        if identifier.hasPrefix("group.") {
            identifier = String(identifier.dropFirst("group.".count))
        }
        guard !identifier.isEmpty else { return false }
        if identifier.hasPrefix(selfBundlePrefix) { return true }
        for prefix in systemPrefixes where identifier == prefix || identifier.hasPrefix(prefix) {
            return true
        }
        return false
    }

    public static func isSystemOwned(_ bundleID: BundleIdentifier) -> Bool {
        isSystemOwned(bundleID: bundleID.rawValue)
    }

    /// True when a finding is owned by a specific bundle identifier that the
    /// system (or MacSweep) owns and therefore must be protected from cleanup.
    public static func isProtectedOwner(_ application: ApplicationIdentity?) -> Bool {
        guard let bundleID = application?.bundleIdentifier else { return false }
        return isSystemOwned(bundleID)
    }
}
