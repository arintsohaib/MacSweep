import Foundation
import Testing

@testable import MacSweep

@Suite("ScanEngine")
struct ScanEngineTests {
    @Test("runs are deterministic")
    func deterministic() async throws {
        let scanner = StaticScanner(category: .logs, items: [
            try ScannerFixtures.item(category: .logs, path: "/Users/u/Library/Logs/b.log", title: "b"),
            try ScannerFixtures.item(category: .logs, path: "/Users/u/Library/Logs/a.log", title: "a"),
        ])
        let engine = ScanEngine(scanners: [scanner])
        let first = await engine.scan(fileSystem: InMemoryFileSystem(), applications: MockApplicationRegistry(), progress: CollectingProgressReporter(), homeDirectory: URL(fileURLWithPath: "/Users/u"))
        let second = await engine.scan(fileSystem: InMemoryFileSystem(), applications: MockApplicationRegistry(), progress: CollectingProgressReporter(), homeDirectory: URL(fileURLWithPath: "/Users/u"))
        #expect(first.items.map(\.id) == second.items.map(\.id))
        #expect(first.items.map(\.category) == second.items.map(\.category))
    }

    @Test("overlapping findings are deduplicated in favor of the higher priority category")
    func deduplication() async throws {
        let cacheScanner = StaticScanner(category: .applicationCaches, items: [
            try ScannerFixtures.item(category: .applicationCaches, path: "/Users/u/Library/Caches/App", title: "App cache"),
        ])
        let largeScanner = StaticScanner(category: .largeFiles, items: [
            try ScannerFixtures.item(category: .largeFiles, path: "/Users/u/Library/Caches/App/huge.tmp", title: "huge file"),
        ])
        let engine = ScanEngine(scanners: [largeScanner, cacheScanner])
        let result = await engine.scan(fileSystem: InMemoryFileSystem(), applications: MockApplicationRegistry(), progress: CollectingProgressReporter(), homeDirectory: URL(fileURLWithPath: "/Users/u"))
        #expect(result.items.count == 1)
        #expect(result.items.first?.category == .applicationCaches)
        #expect(result.diagnostics.contains { $0.category == .unknown && $0.severity == .notice })
    }

    @Test("cleanable findings overlapping protected data are dropped")
    func protectedOverlap() async throws {
        let logsScanner = StaticScanner(category: .logs, items: [
            try ScannerFixtures.item(category: .logs, path: "/Users/u/Library/Logs/App", title: "App logs"),
        ])
        let protectedScanner = StaticScanner(category: .reviewOnly, items: [
            try ScannerFixtures.item(category: .reviewOnly, path: "/Users/u/Library/Logs/App/credential.log", risk: .protected, title: "sensitive log"),
        ])
        let engine = ScanEngine(scanners: [logsScanner, protectedScanner])
        let result = await engine.scan(fileSystem: InMemoryFileSystem(), applications: MockApplicationRegistry(), progress: CollectingProgressReporter(), homeDirectory: URL(fileURLWithPath: "/Users/u"))
        #expect(result.items.count == 1)
        #expect(result.items.first?.risk == RiskLevel.protected)
        #expect(result.diagnostics.contains { $0.category == .protected })
    }

    @Test("a failing scanner does not stop the scan")
    func failureIsolation() async {
        let failing = FailingScanner(category: .logs, failure: FixtureFailure(message: "boom"))
        let good = StaticScanner(category: .largeFiles, items: [
            try! ScannerFixtures.item(category: .largeFiles, path: "/Users/u/big.bin", title: "big"),
        ])
        let engine = ScanEngine(scanners: [failing, good])
        let result = await engine.scan(fileSystem: InMemoryFileSystem(), applications: MockApplicationRegistry(), progress: CollectingProgressReporter(), homeDirectory: URL(fileURLWithPath: "/Users/u"))
        #expect(result.items.count == 1)
        #expect(result.items.first?.category == .largeFiles)
        #expect(result.diagnostics.contains { $0.severity == .error })
        #expect(!result.isCancelled)
    }

    @Test("cancellation returns partial results and cancelled phase")
    func cancellation() async throws {
        let slow = CancellableScanner(category: .logs, delay: .seconds(10), items: [])
        let engine = ScanEngine(scanners: [slow])
        let progress = CollectingProgressReporter()
        let task = Task {
            await engine.scan(fileSystem: InMemoryFileSystem(), applications: MockApplicationRegistry(), progress: progress, homeDirectory: URL(fileURLWithPath: "/Users/u"))
        }
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        let result = await task.value
        #expect(result.isCancelled)
        #expect(result.items.isEmpty)
        #expect(progress.latest?.phase == .cancelled)
        #expect(!result.diagnostics.contains { $0.severity == .error })
    }

    @Test("progress reports running then complete")
    func progress() async {
        let scanner = StaticScanner(category: .logs, items: [])
        let engine = ScanEngine(scanners: [scanner])
        let progress = CollectingProgressReporter()
        _ = await engine.scan(fileSystem: InMemoryFileSystem(), applications: MockApplicationRegistry(), progress: progress, homeDirectory: URL(fileURLWithPath: "/Users/u"))
        let history = progress.all
        #expect(!history.isEmpty)
        #expect(history.first?.phase == .running)
        #expect(history.last?.phase == .complete)
        #expect(history.last?.fractionComplete == 1)
        #expect(history.last?.isFinished == true)
    }

    @Test("only enabled categories are scanned")
    func enabledCategories() async throws {
        let logs = StaticScanner(category: .logs, items: [
            try ScannerFixtures.item(category: .logs, path: "/Users/u/Library/Logs/x.log", title: "x"),
        ])
        let large = StaticScanner(category: .largeFiles, items: [
            try ScannerFixtures.item(category: .largeFiles, path: "/Users/u/big.bin", title: "big"),
        ])
        let engine = ScanEngine(scanners: [logs, large])
        let result = await engine.scan(
            fileSystem: InMemoryFileSystem(),
            applications: MockApplicationRegistry(),
            progress: CollectingProgressReporter(),
            homeDirectory: URL(fileURLWithPath: "/Users/u"),
            enabledCategories: [.logs]
        )
        #expect(result.items.count == 1)
        #expect(result.items.first?.category == .logs)
    }
}
