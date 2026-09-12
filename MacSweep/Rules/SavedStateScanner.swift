import Foundation

public struct SavedStateScanner: FindingsScanner {
    public let category = ScanCategory.savedState

    public init() {}

    public func scan(context: ScanContext) async throws -> [CleanupItem] {
        let stateDir = context.homeDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Saved Application State", isDirectory: true)

        let children: [URL]
        do {
            children = try context.fileSystem.immediateChildren(of: stateDir)
        } catch let error as FileSystemError {
            if case .permissionDenied = error {
                context.diagnostics.record(
                    severity: .warning,
                    category: .permissionDenied,
                    path: stateDir,
                    message: "Could not scan Saved Application State due to permission restrictions."
                )
            }
            return []
        } catch {
            return []
        }

        var items: [CleanupItem] = []
        for child in children {
            try context.checkCancellation()
            let name = child.lastPathComponent
            guard name.hasSuffix(".savedState") else { continue }
            if context.exclusions.isExcluded(child) { continue }

            let meta: FileMetadata
            do {
                meta = try context.fileSystem.stat(child)
            } catch {
                continue
            }

            let size: Int64
            switch meta.kind {
            case .directory:
                size = (try? context.fileSystem.totalSize(of: meta.requestedURL)) ?? 0
            case .file:
                size = meta.size
            case .symbolicLink, .other:
                continue
            }

            guard size > 0 else { continue }

            let snapshot = PathSnapshot(
                url: meta.requestedURL,
                kind: meta.kind,
                size: size,
                modificationDate: meta.modificationDate
            )
            let baseName = String(name.dropLast(".savedState".count))
            if let bundleID = BundleIDMapping.bundleID(fromFolderName: baseName), SystemOwnerRules.isSystemOwned(bundleID) { continue }
            let appTitle = baseName.split(separator: ".").last.map(String.init) ?? baseName

            do {
                let item = try CleanupItem(
                    category: category,
                    title: "\(appTitle) Saved State",
                    reason: "Saved window and open document state for \(baseName). Deleting this resets the application to its default initial window on next launch.",
                    paths: [snapshot],
                    risk: .review,
                    confidence: .medium,
                    evidence: [
                        Evidence(kind: .pathConvention, detail: "Located in ~/Library/Saved Application State."),
                        Evidence(kind: .sizeThreshold, detail: "Occupies \(MacByteFormat.format(size)) on disk."),
                    ],
                    recommendedAction: .moveToTrash,
                    selectedByDefault: false,
                    cleanupAllowed: true,
                    modifiedAt: meta.modificationDate
                )
                items.append(item)
            } catch {
                continue
            }
        }
        return items
    }
}
