import Foundation

/// Classifies bundle identifiers that belong to macOS itself, or to MacSweep,
/// and normalizes app-group / container identifiers so ownership can be tested
/// reliably.
///
/// "Uninstalled application" detection relies on the absence of an installed
/// app bundle, but macOS ships hundreds of background agents, daemons,
/// frameworks, and internal components that have no app bundle in the standard
/// application folders. App extensions and app groups also use identifiers that
/// differ from the owning app's bundle identifier. Treating any of these as
/// removable leftovers destroys system and application data.
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

    /// Strips `group.` / `groups.` and 10-character Apple team prefixes from an
    /// identifier so the underlying owner can be tested. Repeated until stable,
    /// because names such as `243LU875E5.groups.com.apple.podcasts` nest both.
    public static func normalizedOwner(_ identifier: String) -> String {
        var value = identifier.lowercased()
        var changed = true
        while changed {
            changed = false
            if value.hasPrefix("group.") {
                value = String(value.dropFirst("group.".count))
                changed = true
            } else if value.hasPrefix("groups.") {
                value = String(value.dropFirst("groups.".count))
                changed = true
            } else if let range = value.range(of: "^[a-z0-9]{10}\\.", options: .regularExpression) {
                value = String(value[range.upperBound...])
                changed = true
            }
        }
        return value
    }

    /// True for Apple/system-owned identifiers and for MacSweep itself.
    public static func isSystemOwned(bundleID: String) -> Bool {
        let identifier = normalizedOwner(bundleID)
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

    /// Extracts a bundle-identifier-looking name from a file or folder name,
    /// stripping common suffixes macOS uses (`com.apple.dock.plist`,
    /// `com.apple.dock.savedState`, `com.apple.Safari.binarycookies`).
    public static func bundleIDCandidate(fromFileName name: String) -> String? {
        var value = name
        for suffix in [".plist", ".savedState", ".binarycookies"] where value.hasSuffix(suffix) {
            value = String(value.dropLast(suffix.count))
        }
        return value.isEmpty ? nil : value
    }

    /// True when a path's own name identifies system-owned data (for example
    /// `~/Library/Preferences/com.apple.dock.plist` or a `com.apple.*` container).
    /// Used as a last line of defense at cleanup time.
    public static func isSystemOwnedPath(_ url: URL) -> Bool {
        guard let candidate = bundleIDCandidate(fromFileName: url.lastPathComponent),
              BundleIdentifier(rawValue: candidate) != nil else {
            return false
        }
        return isSystemOwned(bundleID: candidate)
    }

    /// True when a finding is owned by a specific bundle identifier that the
    /// system (or MacSweep) owns and therefore must be protected from cleanup.
    public static func isProtectedOwner(_ application: ApplicationIdentity?) -> Bool {
        guard let bundleID = application?.bundleIdentifier else { return false }
        return isSystemOwned(bundleID)
    }

    /// True when `identifier` is, or is a child (app extension) of, any of the
    /// supplied installed identifiers. Extensions are named `<appID>.<extension>`,
    /// so prefix matching on a dot boundary is used.
    public static func isOwnedByInstalled(_ identifier: String, installed: Set<String>) -> Bool {
        let candidate = normalizedOwner(identifier)
        guard !candidate.isEmpty else { return false }
        for installedID in installed {
            let owner = normalizedOwner(installedID)
            if candidate == owner { return true }
            if candidate.hasPrefix(owner + ".") { return true }
            if candidate.hasSuffix("." + owner) { return true }
        }
        return false
    }
}
