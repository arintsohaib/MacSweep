import Foundation

public struct UninstalledAppRemnantsScanner: FindingsScanner {
    public let category = ScanCategory.uninstalledAppRemnants

    private struct AttributedPath {
        let bundleID: BundleIdentifier
        let snapshot: PathSnapshot
        let location: DataLocation
        let requiresReview: Bool
    }

    private struct UnattributedPath {
        let snapshot: PathSnapshot
        let location: DataLocation
    }

    public func scan(context: ScanContext) async throws -> [CleanupItem] {
        let installed = try context.applications.installedApplications()
        let installedIDs = Set(installed.compactMap { $0.bundleIdentifier?.normalized })
        let expectedNames = Self.expectedNames(of: installed)
        let library = context.homeDirectory.appendingPathComponent("Library", isDirectory: true)
        let protectedRules = ProtectedPathRules(homeDirectory: context.homeDirectory)
        let homePath = context.homeDirectory.standardizedFileURL.resolvingSymlinksInPath().path
        func isBlockedLocation(_ url: URL) -> Bool {
            if protectedRules.isProtectedOrContainsProtected(url) { return true }
            let resolved = url.standardizedFileURL.resolvingSymlinksInPath().path
            return resolved != homePath && !resolved.hasPrefix(homePath + "/")
        }

        var attributed: [String: [AttributedPath]] = [:]
        var unattributed: [UnattributedPath] = []

        for child in enumerate(library.appendingPathComponent("Containers", isDirectory: true), context: context) {
            try context.checkCancellation()
            let name = child.lastPathComponent
            guard let bundleID = BundleIDMapping.bundleID(fromFolderName: name),
                  !installedIDs.contains(bundleID.normalized),
                  !context.exclusions.isExcluded(child),
                  let snapshot = snapshot(of: child, context: context) else { continue }
            attributed[bundleID.normalized, default: []].append(AttributedPath(bundleID: bundleID, snapshot: snapshot, location: .container, requiresReview: false))
        }

        for child in enumerate(library.appendingPathComponent("Group Containers", isDirectory: true), context: context) {
            try context.checkCancellation()
            let name = child.lastPathComponent
            guard let bundleID = BundleIDMapping.bundleID(fromFolderName: name),
                  !installedIDs.contains(bundleID.normalized),
                  !context.exclusions.isExcluded(child),
                  let snapshot = snapshot(of: child, context: context) else { continue }
            if let ownerID = Self.stripGroupPrefix(bundleID), installedIDs.contains(ownerID.normalized) {
                continue
            }
            attributed[bundleID.normalized, default: []].append(AttributedPath(bundleID: bundleID, snapshot: snapshot, location: .groupContainer, requiresReview: true))
        }

        let nameBasedLocations: [(DataLocation, String)] = [
            (.applicationSupport, "Application Support"),
            (.caches, "Caches"),
            (.logs, "Logs"),
        ]
        for (location, folder) in nameBasedLocations {
            for child in enumerate(library.appendingPathComponent(folder, isDirectory: true), context: context) {
                try context.checkCancellation()
                let name = child.lastPathComponent
                if context.exclusions.isExcluded(child) { continue }
                if let bundleID = BundleIDMapping.bundleID(fromFolderName: name) {
                    if installedIDs.contains(bundleID.normalized) { continue }
                    guard let snapshot = snapshot(of: child, context: context) else { continue }
                    attributed[bundleID.normalized, default: []].append(AttributedPath(bundleID: bundleID, snapshot: snapshot, location: location, requiresReview: false))
                } else if expectedNames.contains(name.lowercased()) {
                    continue
                } else {
                    guard let snapshot = snapshot(of: child, context: context) else { continue }
                    unattributed.append(UnattributedPath(snapshot: snapshot, location: location))
                }
            }
        }

        for child in enumerate(library.appendingPathComponent("WebKit", isDirectory: true), context: context) {
            try context.checkCancellation()
            let name = child.lastPathComponent
            guard let bundleID = BundleIDMapping.bundleID(fromFolderName: name),
                  !installedIDs.contains(bundleID.normalized),
                  !context.exclusions.isExcluded(child),
                  let snapshot = snapshot(of: child, context: context) else { continue }
            attributed[bundleID.normalized, default: []].append(AttributedPath(bundleID: bundleID, snapshot: snapshot, location: .webKit, requiresReview: false))
        }

        for child in enumerate(library.appendingPathComponent("HTTPStorages", isDirectory: true), context: context) {
            try context.checkCancellation()
            let name = child.lastPathComponent
            let baseName = name.hasSuffix(".binarycookies") ? String(name.dropLast(".binarycookies".count)) : name
            guard let bundleID = BundleIDMapping.bundleID(fromFolderName: baseName),
                  !installedIDs.contains(bundleID.normalized),
                  !context.exclusions.isExcluded(child),
                  let snapshot = snapshot(of: child, context: context) else { continue }
            attributed[bundleID.normalized, default: []].append(AttributedPath(bundleID: bundleID, snapshot: snapshot, location: .httpStorages, requiresReview: false))
        }

        for child in enumerate(library.appendingPathComponent("Saved Application State", isDirectory: true), context: context) {
            try context.checkCancellation()
            let name = child.lastPathComponent
            let baseName = name.hasSuffix(".savedState") ? String(name.dropLast(".savedState".count)) : name
            guard let bundleID = BundleIDMapping.bundleID(fromFolderName: baseName),
                  !installedIDs.contains(bundleID.normalized),
                  !context.exclusions.isExcluded(child),
                  let snapshot = snapshot(of: child, context: context) else { continue }
            attributed[bundleID.normalized, default: []].append(AttributedPath(bundleID: bundleID, snapshot: snapshot, location: .savedState, requiresReview: false))
        }

        for child in enumerate(library.appendingPathComponent("Preferences", isDirectory: true), context: context) {
            try context.checkCancellation()
            let name = child.lastPathComponent
            let baseName = name.hasSuffix(".plist") ? String(name.dropLast(".plist".count)) : name
            guard let bundleID = BundleIDMapping.bundleID(fromFolderName: baseName),
                  !installedIDs.contains(bundleID.normalized),
                  !context.exclusions.isExcluded(child),
                  let snapshot = snapshot(of: child, context: context) else { continue }
            attributed[bundleID.normalized, default: []].append(AttributedPath(bundleID: bundleID, snapshot: snapshot, location: .preferences, requiresReview: false))
        }

        for child in enumerate(library.appendingPathComponent("LaunchAgents", isDirectory: true), context: context) {
            try context.checkCancellation()
            let name = child.lastPathComponent
            guard name.hasSuffix(".plist") else { continue }
            let baseName = String(name.dropLast(".plist".count))
            guard let bundleID = BundleIDMapping.bundleID(fromFolderName: baseName),
                  !installedIDs.contains(bundleID.normalized),
                  !context.exclusions.isExcluded(child),
                  let snapshot = snapshot(of: child, context: context) else { continue }
            attributed[bundleID.normalized, default: []].append(AttributedPath(bundleID: bundleID, snapshot: snapshot, location: .launchAgents, requiresReview: true))
        }

        var items: [CleanupItem] = []
        for (_, paths) in attributed.sorted(by: { $0.key < $1.key }) {
            guard let bundleID = BundleIdentifier(rawValue: paths[0].bundleID.rawValue) else { continue }
            let touchesProtected = paths.contains { isBlockedLocation($0.snapshot.url) }
            let requiresReview = paths.contains { $0.requiresReview } || touchesProtected
            let risk: RiskLevel = requiresReview ? .review : .low
            let confidence: Confidence = requiresReview ? .medium : .high
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
                    risk: risk,
                    confidence: confidence,
                    evidence: Self.evidence(bundleID: bundleID, paths: paths),
                    recommendedAction: touchesProtected ? .reviewOnly : .moveToTrash,
                    selectedByDefault: !touchesProtected && risk == .low,
                    cleanupAllowed: !touchesProtected,
                    modifiedAt: modifiedAt
                )
                items.append(item)
            } catch {
                context.diagnostics.record(severity: .error, category: .invalidItem, message: "Skipped a malformed leftover finding for \(title).")
            }
        }

        for unattributedPath in unattributed.sorted(by: { $0.snapshot.url.path < $1.snapshot.url.path }) {
            if isBlockedLocation(unattributedPath.snapshot.url) { continue }
            let name = unattributedPath.snapshot.url.lastPathComponent
            do {
                let item = try CleanupItem(
                    category: category,
                    title: name,
                    reason: "A folder in the \(unattributedPath.location.displayName) data location that matches no installed application.",
                    paths: [unattributedPath.snapshot],
                    risk: .review,
                    confidence: .low,
                    evidence: [
                        Evidence(kind: .directoryName, detail: "The folder name does not match any installed application."),
                        Evidence(kind: .pathConvention, detail: "Located in a known application data location."),
                    ],
                    recommendedAction: .moveToTrash,
                    selectedByDefault: false,
                    cleanupAllowed: true,
                    modifiedAt: unattributedPath.snapshot.modificationDate
                )
                items.append(item)
            } catch {
                context.diagnostics.record(severity: .error, category: .invalidItem, message: "Skipped a malformed leftover finding for \(name).")
            }
        }

        return items
    }

    private static func expectedNames(of installed: [ApplicationIdentity]) -> Set<String> {
        var names = Set<String>()
        for app in installed {
            names.insert(app.name.lowercased())
            if let bundleID = app.bundleIdentifier {
                for name in BundleIDMapping.expectedFolderNames(bundleID: bundleID, displayName: app.name) {
                    names.insert(name.lowercased())
                }
            }
        }
        return names
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
        var reason = "Data for \(bundleID.rawValue) remains on disk, but the application is no longer installed."
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
