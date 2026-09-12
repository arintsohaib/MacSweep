import Foundation

public struct CleanupEngine: Sendable {
    public let fileSystem: any FileSystem
    public let trash: any TrashService
    public let homeDirectory: URL
    public let protectedPaths: ProtectedPathRules

    public init(
        fileSystem: any FileSystem,
        trash: any TrashService,
        homeDirectory: URL,
        protectedPaths: ProtectedPathRules? = nil
    ) {
        let home = homeDirectory.standardizedFileURL.resolvingSymlinksInPath()
        self.fileSystem = fileSystem
        self.trash = trash
        self.homeDirectory = home
        self.protectedPaths = protectedPaths ?? ProtectedPathRules(homeDirectory: home)
    }

    public func cleanup(selectedItems: [CleanupItem]) async -> CleanupReport {
        let startedAt = Date()
        var results: [CleanupItemResult] = []
        for item in selectedItems {
            if Task.isCancelled {
                results.append(CleanupItemResult(
                    itemID: item.id,
                    status: .cancelled,
                    message: "Cleanup was cancelled before this item was processed. Nothing was moved."
                ))
                continue
            }
            results.append(process(item))
        }
        return CleanupReport(startedAt: startedAt, finishedAt: Date(), results: results)
    }

    private func process(_ item: CleanupItem) -> CleanupItemResult {
        if SystemOwnerRules.isProtectedOwner(item.application) {
            return CleanupItemResult(
                itemID: item.id,
                status: .rejected,
                errorCategory: .protected,
                message: "\(item.title) belongs to macOS or MacSweep and is never cleaned.",
                recoverySuggestion: "System-owned data is permanently protected."
            )
        }

        guard item.cleanupAllowed, item.risk != .protected else {
            return CleanupItemResult(
                itemID: item.id,
                status: .rejected,
                errorCategory: .protected,
                message: "\(item.title) is protected. Nothing was moved.",
                recoverySuggestion: "Protected items are never cleaned by MacSweep."
            )
        }

        var present: [PathSnapshot] = []
        for path in item.paths {
            switch revalidate(path) {
            case .ok:
                present.append(path)
            case .missing:
                continue
            case .rejected(let category, let message, let suggestion):
                return CleanupItemResult(
                    itemID: item.id,
                    status: .rejected,
                    errorCategory: category,
                    message: message,
                    recoverySuggestion: suggestion
                )
            }
        }

        if present.isEmpty {
            return CleanupItemResult(
                itemID: item.id,
                status: .alreadyAbsent,
                message: "\(item.title) is no longer on disk. Nothing was moved."
            )
        }

        var movedSize: Int64 = 0
        var movedCount = 0
        var failures: [(category: ErrorCategory, message: String)] = []
        for path in present {
            if Task.isCancelled {
                failures.append((category: .cancelled, message: "Cancelled before \(path.url.lastPathComponent) was moved."))
                continue
            }
            do {
                _ = try trash.move(toTrash: path.url)
                if fileSystem.exists(path.url) {
                    failures.append((category: .ioFailure, message: "Could not verify that \(path.url.lastPathComponent) was moved to the Trash."))
                } else {
                    movedCount += 1
                    movedSize += path.size
                }
            } catch let error as FileSystemError {
                failures.append((category: error.category, message: "Could not move \(path.url.lastPathComponent) to the Trash (\(error.category.userFacingName))."))
            } catch {
                failures.append((category: .unknown, message: "Could not move \(path.url.lastPathComponent) to the Trash."))
            }
        }

        if failures.isEmpty {
            return CleanupItemResult(
                itemID: item.id,
                status: .movedToTrash,
                message: "\(item.title) was moved to the Trash.",
                size: movedSize
            )
        }
        if movedCount == 0 {
            let first = failures[0]
            return CleanupItemResult(
                itemID: item.id,
                status: .failed,
                errorCategory: first.category,
                message: "Nothing was moved for \(item.title). \(first.message)",
                recoverySuggestion: "Retry after the problem is resolved."
            )
        }
        return CleanupItemResult(
            itemID: item.id,
            status: .failed,
            errorCategory: failures[0].category,
            message: "Partially cleaned \(item.title): \(movedCount) of \(present.count) locations moved to the Trash; \(failures.count) failed.",
            recoverySuggestion: "Review the remaining locations and retry.",
            size: movedSize
        )
    }

    private enum Revalidation {
        case ok
        case missing
        case rejected(category: ErrorCategory, message: String, suggestion: String?)
    }

    private func revalidate(_ snapshot: PathSnapshot) -> Revalidation {
        let meta: FileMetadata
        do {
            meta = try fileSystem.stat(snapshot.url)
        } catch let error as FileSystemError {
            switch error {
            case .notFound:
                return .missing
            case .permissionDenied:
                return .rejected(
                    category: .permissionDenied,
                    message: "Could not verify \(snapshot.url.lastPathComponent) because of limited permissions. Nothing was moved.",
                    suggestion: "The item was not cleaned. Retry when access is available."
                )
            case .ioFailure(let url, let detail):
                return .rejected(
                    category: .ioFailure,
                    message: "Could not verify \(url.lastPathComponent): \(detail).",
                    suggestion: "The item was not cleaned. Retry later."
                )
            case .cancelled:
                return .rejected(category: .cancelled, message: "Cleanup was cancelled.", suggestion: nil)
            }
        } catch {
            return .rejected(
                category: .unknown,
                message: "Unexpected problem while verifying \(snapshot.url.lastPathComponent).",
                suggestion: "The item was not cleaned."
            )
        }

        if !Self.isUnderHome(meta.resolvedURL, home: homeDirectory) {
            return .rejected(
                category: .protected,
                message: "\(snapshot.url.lastPathComponent) now points outside your home folder. Nothing was moved.",
                suggestion: "The item was not cleaned. Run a new scan and review again."
            )
        }
        if protectedPaths.isProtected(snapshot.url) || protectedPaths.isProtected(meta.resolvedURL) {
            return .rejected(
                category: .protected,
                message: "\(snapshot.url.lastPathComponent) is a protected location. Nothing was moved.",
                suggestion: "Protected locations are never cleaned by MacSweep."
            )
        }
        guard meta.kind == snapshot.kind else {
            return .rejected(
                category: .changedSinceScan,
                message: "\(snapshot.url.lastPathComponent) changed since the scan. Nothing was moved.",
                suggestion: "Run a new scan and review again."
            )
        }
        if meta.kind == .file, meta.size != snapshot.size || meta.modificationDate != snapshot.modificationDate {
            return .rejected(
                category: .changedSinceScan,
                message: "\(snapshot.url.lastPathComponent) changed since the scan. Nothing was moved.",
                suggestion: "Run a new scan and review again."
            )
        }
        return .ok
    }

    private static func isUnderHome(_ url: URL, home: URL) -> Bool {
        let path = url.standardizedFileURL.resolvingSymlinksInPath().path
        let homePath = home.path
        return path == homePath || path.hasPrefix(homePath + "/")
    }
}
