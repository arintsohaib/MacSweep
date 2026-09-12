import Foundation

public struct WebStorageScanner: FindingsScanner {
    public let category = ScanCategory.webStorage

    public init() {}

    public func scan(context: ScanContext) async throws -> [CleanupItem] {
        let library = context.homeDirectory.appendingPathComponent("Library", isDirectory: true)
        let targets = [
            ("WebKit", library.appendingPathComponent("WebKit", isDirectory: true)),
            ("HTTPStorages", library.appendingPathComponent("HTTPStorages", isDirectory: true)),
        ]

        var items: [CleanupItem] = []

        for (label, dir) in targets {
            let children: [URL]
            do {
                children = try context.fileSystem.immediateChildren(of: dir)
            } catch let error as FileSystemError {
                if case .permissionDenied = error {
                    context.diagnostics.record(
                        severity: .warning,
                        category: .permissionDenied,
                        path: dir,
                        message: "Could not scan \(label) due to permission restrictions."
                    )
                }
                continue
            } catch {
                continue
            }

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
                let name = child.lastPathComponent
                if let bundleID = BundleIDMapping.bundleID(fromFolderName: name), SystemOwnerRules.isSystemOwned(bundleID) { continue }
                let appName = name.split(separator: ".").last.map(String.init) ?? name

                do {
                    let item = try CleanupItem(
                        category: category,
                        title: "\(appName) \(label)",
                        reason: "Cached web content, network cookies, and IndexedDB storage for \(name). Removing this may log you out of associated web services or require assets to be downloaded again.",
                        paths: [snapshot],
                        risk: .review,
                        confidence: .medium,
                        evidence: [
                            Evidence(kind: .pathConvention, detail: "Located in ~/Library/\(label)."),
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
        }
        return items
    }
}
