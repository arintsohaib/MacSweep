import Foundation
import Testing

@testable import MacSweep

@Suite("LogScanner")
struct LogScannerTests {
    private let home = URL(fileURLWithPath: "/Users/u")

    @Test("discovers logs with review risk")
    func discoversLogs() async throws {
        let fs = InMemoryFileSystem()
        let logDir = "/Users/u/Library/Logs/DiagnosticReports"
        fs.addDirectory(logDir)
        fs.addFile("\(logDir)/crash.ips", size: 40_000)

        let context = ScanContext(
            operationID: UUID(),
            fileSystem: fs,
            applications: MockApplicationRegistry(),
            exclusions: PathExclusions(paths: []),
            progress: CollectingProgressReporter(),
            diagnostics: DiagnosticCollector(),
            homeDirectory: home
        )

        let scanner = LogScanner()
        let items = try await scanner.scan(context: context)

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.category == .logs)
        #expect(item.risk == .review)
        #expect(!item.selectedByDefault)
        #expect(item.cleanupAllowed)
        #expect(item.totalSize == 40_000)
    }

    @Test("empty log directories are skipped")
    func emptyLogsSkipped() async throws {
        let fs = InMemoryFileSystem()
        fs.addDirectory("/Users/u/Library/Logs/EmptyApp")

        let context = ScanContext(
            operationID: UUID(),
            fileSystem: fs,
            applications: MockApplicationRegistry(),
            exclusions: PathExclusions(paths: []),
            progress: CollectingProgressReporter(),
            diagnostics: DiagnosticCollector(),
            homeDirectory: home
        )

        let scanner = LogScanner()
        let items = try await scanner.scan(context: context)

        #expect(items.isEmpty)
    }
}
