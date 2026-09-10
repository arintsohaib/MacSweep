import Foundation

public struct LargeFileScanner: FindingsScanner {
    public let category = ScanCategory.largeFiles

    public init() {}

    public func scan(context: ScanContext) async throws -> [CleanupItem] {
        let threshold = context.configuration.minLargeFileSize
        let searchDirectories = [
            context.homeDirectory.appendingPathComponent("Downloads", isDirectory: true),
            context.homeDirectory.appendingPathComponent("Desktop", isDirectory: true),
        ]

        var items: [CleanupItem] = []

        for directory in searchDirectories {
            let children: [URL]
            do {
                children = try context.fileSystem.immediateChildren(of: directory)
            } catch {
                continue
            }

            for fileURL in children {
                try context.checkCancellation()
                if context.exclusions.isExcluded(fileURL) { continue }

                let meta: FileMetadata
                do {
                    meta = try context.fileSystem.stat(fileURL)
                } catch {
                    continue
                }

                // Only detect regular files, not subdirectories or symlinks
                guard meta.kind == .file, meta.size >= threshold else { continue }

                let snapshot = PathSnapshot(
                    url: meta.requestedURL,
                    kind: .file,
                    size: meta.size,
                    modificationDate: meta.modificationDate
                )
                let name = fileURL.lastPathComponent

                do {
                    let item = try CleanupItem(
                        category: category,
                        title: name,
                        reason: "Large file occupying \(MacByteFormat.format(meta.size)) in ~/\(directory.lastPathComponent), exceeding the \(MacByteFormat.format(threshold)) discovery threshold. Files in personal folders are never cleaned automatically; review it and move it yourself if you are sure.",
                        paths: [snapshot],
                        risk: .review,
                        confidence: .high,
                        evidence: [
                            Evidence(kind: .sizeThreshold, detail: "File size is \(MacByteFormat.format(meta.size)), meeting or exceeding the \(MacByteFormat.format(threshold)) limit."),
                            Evidence(kind: .pathConvention, detail: "Found in user directory ~/\(directory.lastPathComponent)."),
                        ],
                        recommendedAction: .reviewOnly,
                        selectedByDefault: false,
                        cleanupAllowed: false,
                        modifiedAt: meta.modificationDate
                    )
                    items.append(item)
                } catch {
                    continue
                }
            }
        }

        return items.sorted { $0.totalSize > $1.totalSize }
    }
}
