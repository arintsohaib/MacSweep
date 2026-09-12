import Foundation

public struct UninstalledAppRemnantsScanner: FindingsScanner {
    public let category = ScanCategory.uninstalledAppRemnants

    private struct AttributedPath {
        let bundleID: BundleIdentifier
        let snapshot: PathSnapshot
        let location: DataLocation
        let requiresReview: Bool
    }

    public func scan(context: ScanContext) async throws -> [CleanupItem] {
        let installed = try context.applications.installedApplications()
        let installedIDs = Set(installed.compactMap { $0.bundleIdentifier?.normalized })
        let library = context.homeDirectory.appendingPathComponent("Library", isDirectory: true)
        let protectedRules = ProtectedPathRules(homeDirectory: context.homeDirectory)
        let homePath = context.homeDirectory.standardizedFileURL.resolvingSymlinksInPath().path
        func isBlockedLocation(_ url: URL) -> Bool {
            if protectedRules.isProtectedOrContainsProtected(url) { return true }
            let resolved = url.standardizedFileURL.resolvingSymlinksInPath().path
            return resolved != homePath && !resolved.hasPrefix(homePath + "/")
        }

        // Resolve each candidate identifier at most once. LaunchServices knows about
        // applications installed anywhere, not just in the default folders.
        var installedLookup: [String: Bool] = [:]
        func isInstalled(_ bundleID: BundleIdentifier) -> Bool {
            if installedIDs.contains(bundleID.normalized) { return true }
            if let cached = installedLookup[bundleID.normalized] { return cached }
            let resolved = (try? context.applications.installedApplication(withBundleIdentifier: bundleID)) != nil
            installedLookup[bundleID.normalized] = resolved
            return resolved
        }

        // A folder is only a leftover candidate when it names a genuine third-party
        // application identifier that is truly absent. Apple/system-owned identifiers
        // (com.apple.*, ...) and MacSweep itself are never leftovers: macOS ships
        // hundreds of background components that have no app bundle, and removing
        // their data silently resets user configuration.
        func isRemnantCandidate(_ bundleID: BundleIdentifier) -> Bool {
            guard !SystemOwnerRules.isSystemOwned(bundleID) else { return false }
            if isInstalled(bundleID) { return false }
            if let ownerID = Self.stripGroupPrefix(bundleID), isInstalled(ownerID) { return false }
            return true
        }

        var attributed: [String: [AttributedPath]] = [:]
        func collect(_ child: URL, location: DataLocation, requiresReview: Bool) throws {
            try context.checkCancellation()
            let baseName = Self.baseName(for: child.lastPathComponent, location: location)
            guard let bundleID = BundleIDMapping.bundleID(fromFolderName: baseName),
                  isRemnantCandidate(bundleID),
                  !context.exclusions.isExcluded(child),
                  let snapshot = snapshot(of: child, context: context) else { return }
            attributed[bundleID.normalized, default: []].append(
                AttributedPath(bundleID: bundleID, snapshot: snapshot, location: location, requiresReview: requiresReview)
            )
        }

        for child in enumerate(library.appendingPathComponent("Containers", isDirectory: true), context: context) {
            try collect(child, location: .container, requiresReview: false)
        }
        for child in enumerate(library.appendingPathComponent("Group Containers", isDirectory: true), context: context) {
            try collect(child, location: .groupContainer, requiresReview: true)
        }
        for child in enumerate(library.appendingPathComponent("Application Support", isDirectory: true), context: context) {
            try collect(child, location: .applicationSupport, requiresReview: false)
        }
        for child in enumerate(library.appendingPathComponent("Caches", isDirectory: true), context: context) {
            try collect(child, location: .caches, requiresReview: false)
        }
        for child in enumerate(library.appendingPathComponent("Logs", isDirectory: true), context: context) {
            try collect(child, location: .logs, requiresReview: false)
        }
        for child in enumerate(library.appendingPathComponent("WebKit", isDirectory: true), context: context) {
            try collect(child, location: .webKit, requiresReview: false)
        }
        for child in enumerate(library.appendingPathComponent("HTTPStorages", isDirectory: true), context: context) {
            try collect(child, location: .httpStorages, requiresReview: false)
        }
        for child in enumerate(library.appendingPathComponent("Saved Application State", isDirectory: true), context: context) {
            try collect(child, location: .savedState, requiresReview: false)
        }
        for child in enumerate(library.appendingPathComponent("LaunchAgents", isDirectory: true), context: context) {
            try collect(child, location: .launchAgents, requiresReview: true)
        }
        // ~/Library/Preferences is intentionally not scanned: preferences are user
        // settings, not reclaimable storage. macOS silently resets configuration
        // (default apps, Dock, Finder, ...) when preference files are removed.

        var items: [CleanupItem] = []
        for (_, paths) in attributed.sorted(by: { $0.key < $1.key }) {
            guard let bundleID = BundleIdentifier(rawValue: paths[0].bundleID.rawValue) else { continue }
            let touchesProtected = paths.contains { isBlockedLocation($0.snapshot.url) }
            let confidence: Confidence = (paths.contains { $0.requiresReview } || touchesProtected) ? .medium : .high
            let title = Self.title(for: bundleID)
            let modifiedAt = paths.compactMap { $0.snapshot.modificationDate }.max()
            do {
                var reason = Self.reason(bundleID: bundleID, paths: paths)
                if touchesProtected {
                    reason += " Some locations are permanently protected, so only review is offered."
                }
                let item = try CleanupItem(
                    category: category,
                    application: ApplicationIdentity(bundleIdentifier: bundleID, name: title, isInstalled: false),
                    title: title,
                    reason: reason,
                    paths: paths.map { $0.snapshot },
                    // Leftovers are only ever offered for explicit review: never
                    // pre-selected, always review risk.
                    risk: .review,
                    confidence: confidence,
                    evidence: Self.evidence(bundleID: bundleID, paths: paths),
                    recommendedAction: touchesProtected ? .reviewOnly : .moveToTrash,
                    selectedByDefault: false,
                    cleanupAllowed: !touchesProtected,
                    modifiedAt: modifiedAt
                )
                items.append(item)
            } catch {
                context.diagnostics.record(severity: .error, category: .invalidItem, message: "Skipped a malformed leftover finding for \(title).")
            }
        }

        return items
    }

    private static func baseName(for name: String, location: DataLocation) -> String {
        switch location {
        case .httpStorages:
            return name.hasSuffix(".binarycookies") ? String(name.dropLast(".binarycookies".count)) : name
        case .savedState:
            return name.hasSuffix(".savedState") ? String(name.dropLast(".savedState".count)) : name
        case .launchAgents:
            return name.hasSuffix(".plist") ? String(name.dropLast(".plist".count)) : name
        default:
            return name
        }
    }

    private static func stripGroupPrefix(_ bundleID: BundleIdentifier) -> BundleIdentifier? {
        let raw = bundleID.rawValue
        guard raw.lowercased().hasPrefix("group.") else { return nil }
        return BundleIdentifier(rawValue: String(raw.dropFirst("group.".count)))
    }

    private func enumerate(_ url: URL, context: ScanContext) -> [URL] {
        do {
            return try context.fileSystem.immediateChildren(of: url)
        } catch let error as FileSystemError {
            if case .permissionDenied = error {
                context.diagnostics.record(
                    severity: .warning,
                    category: .permissionDenied,
                    path: url,
                    message: "Some leftovers may be hidden: MacSweep could not read \(url.lastPathComponent) because of limited permissions."
                )
            }
            return []
        } catch {
            return []
        }
    }

    private func snapshot(of url: URL, context: ScanContext) -> PathSnapshot? {
        let meta: FileMetadata
        do {
            meta = try context.fileSystem.stat(url)
        } catch let error as FileSystemError {
            if case .notFound = error {
                return nil
            }
            if case .permissionDenied = error {
                context.diagnostics.record(
                    severity: .warning,
                    category: .permissionDenied,
                    path: url,
                    message: "Could not measure the size of \(url.lastPathComponent) because of limited permissions."
                )
            }
            return nil
        } catch {
            return nil
        }
        let size: Int64
        switch meta.kind {
        case .directory:
            size = (try? context.fileSystem.totalSize(of: meta.requestedURL)) ?? 0
        case .file:
            size = meta.size
        case .symbolicLink, .other:
            size = 0
        }
        return PathSnapshot(url: meta.requestedURL, kind: meta.kind, size: size, modificationDate: meta.modificationDate)
    }

    private static func title(for bundleID: BundleIdentifier) -> String {
        let segments = bundleID.rawValue.split(separator: ".")
        let last = segments.last.map(String.init) ?? bundleID.rawValue
        return last
    }

    private static func reason(bundleID: BundleIdentifier, paths: [AttributedPath]) -> String {
        var reason = "Data for \(bundleID.rawValue) remains on disk, but the application is no longer installed. Review each location before cleanup."
        if paths.contains(where: { $0.location == .groupContainer }) {
            reason += " It includes a shared group container that other applications may still use."
        }
        if paths.contains(where: { $0.location == .launchAgents }) {
            reason += " It includes launch metadata that may belong to a helper component."
        }
        return reason
    }

    private static func evidence(bundleID: BundleIdentifier, paths: [AttributedPath]) -> [Evidence] {
        var result: [Evidence] = [
            Evidence(kind: .bundleIdentifierMatch, detail: "Data is stored under the bundle identifier \(bundleID.rawValue)."),
            Evidence(kind: .applicationAbsent, detail: "No installed application has this bundle identifier."),
            Evidence(kind: .pathConvention, detail: "Found in: " + paths.map { $0.location.displayName }.sorted().joined(separator: ", ") + "."),
        ]
        if paths.contains(where: { $0.location == .groupContainer }) {
            result.append(Evidence(kind: .sharedOwnership, detail: "Group containers can be shared between multiple applications."))
        }
        return result
    }
}
