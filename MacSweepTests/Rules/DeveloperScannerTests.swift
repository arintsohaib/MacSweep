import Foundation
import Testing

@testable import MacSweep

@Suite("DeveloperScanner")
struct DeveloperScannerTests {
    private let home = URL(fileURLWithPath: "/Users/u")

    @Test("discovers standard developer caches as review with consequence explanation")
    func discoversDeveloperCaches() async throws {
        let fs = InMemoryFileSystem()
        let derivedData = "/Users/u/Library/Developer/Xcode/DerivedData"
        fs.addDirectory(derivedData)
        fs.addFile("\(derivedData)/ModuleCache.noindex/cache.pcm", size: 100_000_000)

        let npmCache = "/Users/u/.npm"
        fs.addDirectory(npmCache)
        fs.addFile("\(npmCache)/_cacache/content-v2/a", size: 25_000_000)

        let context = ScanContext(
            operationID: UUID(),
            fileSystem: fs,
            applications: MockApplicationRegistry(),
            exclusions: PathExclusions(paths: []),
            progress: CollectingProgressReporter(),
            diagnostics: DiagnosticCollector(),
            homeDirectory: home
        )

        let scanner = DeveloperScanner()
        let items = try await scanner.scan(context: context)

        #expect(items.count == 2)
        for item in items {
            #expect(item.category == .developerCaches)
            #expect(item.risk == .review)
            #expect(!item.selectedByDefault)
            #expect(item.cleanupAllowed)
            #expect(item.reason.contains("Consequence:") == true)
        }
    }

    @Test("docker data is reported as protected and not cleanable")
    func dockerIsProtected() async throws {
        let fs = InMemoryFileSystem()
        let dockerPath = "/Users/u/Library/Containers/com.docker.docker"
        fs.addDirectory(dockerPath)
        fs.addFile("\(dockerPath)/Data/vms/0/data/Docker.raw", size: 10_000_000_000)

        let context = ScanContext(
            operationID: UUID(),
            fileSystem: fs,
            applications: MockApplicationRegistry(),
            exclusions: PathExclusions(paths: []),
            progress: CollectingProgressReporter(),
            diagnostics: DiagnosticCollector(),
            homeDirectory: home
        )

        let scanner = DeveloperScanner()
        let items = try await scanner.scan(context: context)

        #expect(items.count == 1)
        let dockerItem = try #require(items.first)
        #expect(dockerItem.title == "Docker VM & Storage")
        #expect(dockerItem.risk == .protected)
        #expect(!dockerItem.cleanupAllowed)
        #expect(dockerItem.recommendedAction == .reviewOnly)
        #expect(!dockerItem.selectedByDefault)
    }
}
