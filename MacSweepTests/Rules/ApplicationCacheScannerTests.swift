import Foundation
import Testing

@testable import MacSweep

@Suite("ApplicationCacheScanner")
struct ApplicationCacheScannerTests {
    private let home = URL(fileURLWithPath: "/Users/u")

    private func makeContext(fileSystem: InMemoryFileSystem, exclusions: PathExclusions = PathExclusions(paths: [])) -> ScanContext {
        ScanContext(
            operationID: UUID(),
            fileSystem: fileSystem,
            applications: MockApplicationRegistry(),
            exclusions: exclusions,
            progress: CollectingProgressReporter(),
            diagnostics: DiagnosticCollector(),
            homeDirectory: home
        )
    }

    @Test("discovers application caches with review risk")
    func discoversCaches() async throws {
        let fs = InMemoryFileSystem()
        let cachePath = "/Users/u/Library/Caches/com.example.Browser"
        fs.addDirectory(cachePath)
        fs.addFile("\(cachePath)/Cache.db", size: 5_000_000)

        let context = makeContext(fileSystem: fs)
        let scanner = ApplicationCacheScanner()
        let items = try await scanner.scan(context: context)

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.category == .applicationCaches)
        #expect(item.risk == .review)
        #expect(!item.selectedByDefault)
        #expect(item.cleanupAllowed)
        #expect(item.totalSize == 5_000_000)
    }

    @Test("empty or zero-byte cache directories are skipped")
    func emptyCachesSkipped() async throws {
        let fs = InMemoryFileSystem()
        fs.addDirectory("/Users/u/Library/Caches/EmptyApp")

        let context = makeContext(fileSystem: fs)
        let scanner = ApplicationCacheScanner()
        let items = try await scanner.scan(context: context)

        #expect(items.isEmpty)
    }

    @Test("excluded cache folders are not reported")
    func exclusionsRespected() async throws {
        let fs = InMemoryFileSystem()
        let cachePath = "/Users/u/Library/Caches/com.example.Excluded"
        fs.addDirectory(cachePath)
        fs.addFile("\(cachePath)/data.bin", size: 1000)

        let exclusions = PathExclusions(paths: [URL(fileURLWithPath: cachePath)])
        let context = makeContext(fileSystem: fs, exclusions: exclusions)
        let scanner = ApplicationCacheScanner()
        let items = try await scanner.scan(context: context)

        #expect(items.isEmpty)
    }
}
