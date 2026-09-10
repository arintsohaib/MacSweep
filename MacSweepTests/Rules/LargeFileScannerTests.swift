import Foundation
import Testing

@testable import MacSweep

@Suite("LargeFileScanner")
struct LargeFileScannerTests {
    private let home = URL(fileURLWithPath: "/Users/u")

    @Test("files exceeding discovery threshold are reported")
    func discoversLargeFiles() async throws {
        let fs = InMemoryFileSystem()
        let downloads = "/Users/u/Downloads"
        fs.addDirectory(downloads)
        fs.addFile("\(downloads)/macOS_Installer.dmg", size: 600 * 1024 * 1024)
        fs.addFile("\(downloads)/small_document.pdf", size: 10 * 1024 * 1024)
        fs.addDirectory("\(downloads)/some_directory")

        let config = ScanConfiguration(minLargeFileSize: 500 * 1024 * 1024)
        let context = ScanContext(
            operationID: UUID(),
            fileSystem: fs,
            applications: MockApplicationRegistry(),
            exclusions: PathExclusions(paths: []),
            configuration: config,
            progress: CollectingProgressReporter(),
            diagnostics: DiagnosticCollector(),
            homeDirectory: home
        )

        let scanner = LargeFileScanner()
        let items = try await scanner.scan(context: context)

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.title == "macOS_Installer.dmg")
        #expect(item.category == .largeFiles)
        #expect(item.risk == .review)
        #expect(!item.selectedByDefault)
        #expect(!item.cleanupAllowed)
        #expect(item.recommendedAction == .reviewOnly)
        #expect(item.totalSize == 600 * 1024 * 1024)
    }

    @Test("files below threshold are skipped")
    func smallFilesSkipped() async throws {
        let fs = InMemoryFileSystem()
        let downloads = "/Users/u/Downloads"
        fs.addDirectory(downloads)
        fs.addFile("\(downloads)/clip.mp4", size: 100 * 1024 * 1024)

        let config = ScanConfiguration(minLargeFileSize: 500 * 1024 * 1024)
        let context = ScanContext(
            operationID: UUID(),
            fileSystem: fs,
            applications: MockApplicationRegistry(),
            exclusions: PathExclusions(paths: []),
            configuration: config,
            progress: CollectingProgressReporter(),
            diagnostics: DiagnosticCollector(),
            homeDirectory: home
        )

        let scanner = LargeFileScanner()
        let items = try await scanner.scan(context: context)

        #expect(items.isEmpty)
    }
}
