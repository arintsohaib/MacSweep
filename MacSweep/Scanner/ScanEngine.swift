import Foundation

public final class ScanEngine: @unchecked Sendable {
    private let scanners: [any FindingsScanner]

    public init(scanners: [any FindingsScanner]) {
        self.scanners = scanners.sorted { $0.category < $1.category }
    }

    public func scan(
        fileSystem: any FileSystem,
        applications: any ApplicationRegistry,
        exclusions: PathExclusions = PathExclusions(paths: []),
        configuration: ScanConfiguration = ScanConfiguration(),
        progress: any ProgressReporter,
        homeDirectory: URL,
        enabledCategories: Set<ScanCategory>? = nil
    ) async -> ScanResult {
        let operationID = UUID()
        let startedAt = Date()
        let diagnostics = DiagnosticCollector()
        let activeScanners = enabledCategories.map { enabled in
            scanners.filter { enabled.contains($0.category) }
        } ?? scanners

        let context = ScanContext(
            operationID: operationID,
            fileSystem: fileSystem,
            applications: applications,
            exclusions: exclusions,
            configuration: configuration,
            progress: progress,
            diagnostics: diagnostics,
            homeDirectory: homeDirectory
        )

        progress.report(ScanProgress(phase: .running, message: "Starting scan", fractionComplete: 0))

        var collected: [CleanupItem] = []
        var completedCount = 0
        await withTaskGroup(of: (category: ScanCategory, result: Result<[CleanupItem], Error>).self) { group in
            for scanner in activeScanners {
                group.addTask { [context] in
                    do {
                        let items = try await scanner.scan(context: context)
                        return (scanner.category, .success(items))
                    } catch is CancellationError {
                        return (scanner.category, .failure(ScanError.cancelled))
                    } catch let error as ScanError {
                        return (scanner.category, .failure(error))
                    } catch {
                        return (scanner.category, .failure(ScanError.failed(String(describing: error))))
                    }
                }
            }
            for await (category, result) in group {
                switch result {
                case .success(let items):
                    collected.append(contentsOf: items)
                case .failure(let error):
                    if error is CancellationError || (error as? ScanError) == .cancelled {
                        group.cancelAll()
                    } else {
                        diagnostics.record(
                            severity: .error,
                            category: .unknown,
                            message: "The \(category.displayName) scan failed and was skipped."
                        )
                    }
                }
                completedCount += 1
                let fraction = activeScanners.isEmpty ? 1.0 : Double(completedCount) / Double(activeScanners.count)
                progress.report(ScanProgress(
                    phase: .running,
                    currentCategory: category,
                    message: "Finished \(category.displayName)",
                    fractionComplete: fraction
                ))
            }
        }

        let wasCancelled = Task.isCancelled
        let items = Self.deduplicate(collected, diagnostics: diagnostics)
        let finishedAt = Date()
        progress.report(ScanProgress(
            phase: wasCancelled ? .cancelled : .complete,
            message: wasCancelled ? "Scan cancelled" : "Scan complete",
            fractionComplete: 1
        ))
        return ScanResult(
            operationID: operationID,
            startedAt: startedAt,
            finishedAt: finishedAt,
            items: items,
            diagnostics: diagnostics.all,
            isCancelled: wasCancelled
        )
    }

    static func deduplicate(_ items: [CleanupItem], diagnostics: DiagnosticCollector) -> [CleanupItem] {
        let ordered = items.sorted { a, b in
            if a.category != b.category { return a.category < b.category }
            if a.confidence != b.confidence { return a.confidence > b.confidence }
            if a.totalSize != b.totalSize { return a.totalSize < b.totalSize }
            return a.id.rawValue < b.id.rawValue
        }

        var keptProtected: [CleanupItem] = []
        for item in ordered where item.risk == .protected {
            if keptProtected.contains(where: { Self.pathSetsIntersect($0, item) }) { continue }
            keptProtected.append(item)
        }

        var keptCleanable: [CleanupItem] = []
        for item in ordered where item.risk != .protected {
            if keptProtected.contains(where: { Self.pathSetsIntersect($0, item) }) {
                diagnostics.record(
                    severity: .notice,
                    category: .protected,
                    message: "Skipped \(item.title) because it overlaps protected data."
                )
                continue
            }
            if keptCleanable.contains(where: { Self.pathSetsIntersect($0, item) }) {
                diagnostics.record(
                    severity: .notice,
                    category: .unknown,
                    message: "Skipped \(item.title) because it overlaps a larger finding."
                )
                continue
            }
            keptCleanable.append(item)
        }

        return (keptProtected + keptCleanable).sorted { a, b in
            if a.category != b.category { return a.category < b.category }
            if a.confidence != b.confidence { return a.confidence > b.confidence }
            if a.totalSize != b.totalSize { return a.totalSize < b.totalSize }
            return a.id.rawValue < b.id.rawValue
        }
    }

    static func pathSetsIntersect(_ a: CleanupItem, _ b: CleanupItem) -> Bool {
        for pathA in a.paths {
            for pathB in b.paths {
                if pathsTouch(pathA.url, pathB.url) {
                    return true
                }
            }
        }
        return false
    }

    static func pathsTouch(_ lhs: URL, _ rhs: URL) -> Bool {
        if lhs == rhs { return true }
        let lhsPrefix = lhs.path.hasSuffix("/") ? lhs.path : lhs.path + "/"
        let rhsPrefix = rhs.path.hasSuffix("/") ? rhs.path : rhs.path + "/"
        return rhs.path.hasPrefix(lhsPrefix) || lhs.path.hasPrefix(rhsPrefix)
    }
}
