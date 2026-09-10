import Foundation

public struct ProtectedPathRules: Sendable {
    private let prefixRoots: [String]
    private let exactRoots: Set<String>

    public init(homeDirectory: URL) {
        let home = homeDirectory.standardizedFileURL.resolvingSymlinksInPath()
        let systemRoots = [
            "/System", "/usr", "/bin", "/sbin", "/etc", "/opt", "/Library",
            "/Applications", "/Network", "/CoreServices", "/private", "/Volumes",
        ]
        let sensitive: [String] = [
            "Documents", "Desktop", "Downloads", "Movies", "Music", "Pictures", "Public",
            ".ssh", ".gnupg", ".aws",
            "Library/Keychains", "Library/Mail", "Library/Messages", "Library/Safari",
            "Library/Application Support/Google/Chrome",
            "Library/Application Support/com.apple.AddressBook",
        ]
        prefixRoots = (systemRoots + sensitive.map { home.appendingPathComponent($0).standardizedFileURL.path }).sorted()
        exactRoots = ["/", home.path]
    }

    public func isProtected(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.resolvingSymlinksInPath().path
        guard !path.isEmpty else { return true }
        if exactRoots.contains(path) {
            return true
        }
        return prefixRoots.contains { root in
            path == root || path.hasPrefix(root + "/")
        }
    }

    /// True when the location is protected or is an ancestor of a protected root.
    /// Moving an ancestor to the Trash would remove protected content with it,
    /// so ancestors must be treated as protected too.
    public func isProtectedOrContainsProtected(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.resolvingSymlinksInPath().path
        guard !path.isEmpty else { return true }
        if isProtected(url) { return true }
        return prefixRoots.contains { root in
            root.hasPrefix(path + "/")
        }
    }
}
