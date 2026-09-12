import Foundation

public struct LogScanner: FindingsScanner {
    public let category = ScanCategory.logs

    public init() {}

    public func scan(context: ScanContext) async throws -> [CleanupItem] {
        let logsDir = context.homeDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)

        let children: [URL]
        do {
            children = try context.fileSystem.immediateChildren(of: logsDir)
        } catch let error as FileSystemError {
            if case .permissionDenied = error {
                context.diagnostics.record(
                    severity: .warning,
                    category: .permissionDenied,
                    path: logsDir,
                    message: "Could not scan ~/Library/Logs due to permission restrictions."
                )
            }
            return []
        } catch {
            return []
        }

        var items: [CleanupItem] = []
        for child in children {
            try context.checkCancellation()
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
            let title = child.lastPathComponent
            if let bundleID = BundleIDMapping.bundleID(fromFolderName: title), SystemOwnerRules.isSystemOwned(bundleID) { continue }

            do {
                let item = try CleanupItem(
                    category: category,
                    title: "\(title) Logs",
                    reason: "Application logs and diagnostic traces in ~/Library/Logs. Removing old logs frees storage without affecting software functionality.",
                    paths: [snapshot],
                    risk: .review,
                    confidence: .medium,
                    evidence: [
                        Evidence(kind: .pathConvention, detail: "Located in ~/Library/Logs."),
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
