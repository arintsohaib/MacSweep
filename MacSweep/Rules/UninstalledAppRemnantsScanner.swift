import Foundation

public struct UninstalledAppRemnantsScanner: FindingsScanner {
    public let category = ScanCategory.uninstalledAppRemnants

    private struct Candidate {
        let bundleID: BundleIdentifier
        let snapshot: PathSnapshot
        let location: DataLocation
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

        // A container/folder is only a leftover when its identifier belongs to no
        // installed application. Extension identifiers (`<app>.<extension>`),
        // team-prefixed identifiers, and app-group prefixes are all resolved back
        // to the owning application before this decision.
        var resolvedLookup: [String: Bool] = [:]
        func isInstalled(_ bundleID: BundleIdentifier) -> Bool {
            if SystemOwnerRules.isOwnedByInstalled(bundleID.rawValue, installed: installedIDs) { return true }
            if let cached = resolvedLookup[bundleID.normalized] { return cached }
            let resolved = (try? context.applications.installedApplication(withBundleIdentifier: bundleID)) != nil
            resolvedLookup[bundleID.normalized] = resolved
            return resolved
        }

        func isRemnantCandidate(_ bundleID: BundleIdentifier) -> Bool {
            if SystemOwnerRules.isSystemOwned(bundleID) { return false }
            if isInstalled(bundleID) { return false }
            return true
        }

        var candidates: [Candidate] = []
        func collect(_ child: URL, location: DataLocation) throws {
            try context.checkCancellation()
            guard let bundleID = BundleIDMapping.bundleID(fromFolderName: child.lastPathComponent),
                  isRemnantCandidate(bundleID),
                  !context.exclusions.isExcluded(child),
                  let snapshot = snapshot(of: child, context: context) else { return }
            candidates.append(Candidate(bundleID: bundleID, snapshot: snapshot, location: location))
        }

        // Only sandbox containers and Application Support folders are considered.
        // Group Containers, LaunchAgents, Caches, Logs, WebKit, HTTPStorages and
        // Saved Application State are either shared ownership, system-managed, or
        // already covered by dedicated scanners, and their folder names cannot
        // reliably prove that an application is gone.
        for child in enumerate(library.appendingPathComponent("Containers", isDirectory: true), context: context) {
            try collect(child, location: .container)
        }
        for child in enumerate(library.appendingPathComponent("Application Support", isDirectory: true), context: context) {
            try collect(child, location: .applicationSupport)
        }

        var grouped: [String: [Candidate]] = [:]
        for candidate in candidates {
            grouped[candidate.bundleID.normalized, default: []].append(candidate)
        }

        var items: [CleanupItem] = []
        for (_, group) in grouped.sorted(by: { $0.key < $1.key }) {
            guard let bundleID = BundleIdentifier(rawValue: group[0].bundleID.rawValue) else { continue }
            let touchesProtected = group.contains { isBlockedLocation($0.snapshot.url) }
            let title = Self.title(for: bundleID)
            let modifiedAt = group.compactMap { $0.snapshot.modificationDate }.max()
            do {
                var reason = "Data for \(bundleID.rawValue) remains on disk, but no installed application uses this identifier. Review each location; MacSweep does not remove application data automatically."
                if touchesProtected {
                    reason += " Some locations are permanently protected."
                }
                let item = try CleanupItem(
                    category: category,
                    application: ApplicationIdentity(bundleIdentifier: bundleID, name: title, isInstalled: false),
                    title: title,
                    reason: reason,
                    paths: group.map { $0.snapshot },
                    // Leftovers are informational only: application data may still
                    // be shared with helpers or services, and macOS protects app
                    // containers. MacSweep never removes these automatically.
                    risk: .review,
                    confidence: .medium,
                    evidence: Self.evidence(bundleID: bundleID, locations: group.map { $0.location }),
                    recommendedAction: .reviewOnly,
                    selectedByDefault: false,
                    cleanupAllowed: false,
                    modifiedAt: modifiedAt
                )
                items.append(item)
            } catch {
                context.diagnostics.record(severity: .error, category: .invalidItem, message: "Skipped a malformed leftover finding for \(title).")
            }
        }

        return items
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

    private static func evidence(bundleID: BundleIdentifier, locations: [DataLocation]) -> [Evidence] {
        var result: [Evidence] = [
            Evidence(kind: .bundleIdentifierMatch, detail: "Data is stored under the bundle identifier \(bundleID.rawValue)."),
            Evidence(kind: .applicationAbsent, detail: "No installed application or app extension uses this identifier."),
            Evidence(kind: .pathConvention, detail: "Found in: " + Set(locations.map { $0.displayName }).sorted().joined(separator: ", ") + "."),
        ]
        if locations.contains(.container) {
            result.append(Evidence(kind: .other, detail: "Sandbox containers are managed by macOS and may be protected from removal."))
        }
        return result
    }
}
