import Foundation

public struct ApplicationCacheScanner: FindingsScanner {
    public let category = ScanCategory.applicationCaches

    public init() {}

    public func scan(context: ScanContext) async throws -> [CleanupItem] {
        let cachesDir = context.homeDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)

        let children: [URL]
        do {
            children = try context.fileSystem.immediateChildren(of: cachesDir)
        } catch let error as FileSystemError {
            if case .permissionDenied = error {
                context.diagnostics.record(
                    severity: .warning,
                    category: .permissionDenied,
                    path: cachesDir,
                    message: "Could not scan ~/Library/Caches due to permission restrictions."
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

            do {
                let item = try CleanupItem(
                    category: category,
                    title: "\(title) Cache",
                    reason: "Application cache data in ~/Library/Caches. Caches will regenerate when the application runs, but initial launch or indexing may take slightly longer.",
                    paths: [snapshot],
                    risk: .review,
                    confidence: .medium,
                    evidence: [
                        Evidence(kind: .pathConvention, detail: "Located in ~/Library/Caches."),
                        Evidence(kind: .sizeThreshold, detail: "Contains \(MacByteFormat.format(size)) of regenerable cache data."),
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
