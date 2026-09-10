import Foundation
import Testing

@testable import MacSweep

@Suite("RaceCondition")
struct RaceConditionTests {
    private let home = URL(fileURLWithPath: "/Users/u")

    @Test("directory replaced by file between scan and cleanup is rejected")
    func directoryReplacedByFile() async throws {
        let fs = InMemoryFileSystem()
        let path = "/Users/u/Library/Containers/com.vendor.Replaced"
        fs.addDirectory(path)

        let snapshot = PathSnapshot(
            url: URL(fileURLWithPath: path),
            kind: .directory,
            size: 1000,
            modificationDate: nil
        )
        let item = try CleanupItem(
            category: .uninstalledAppRemnants,
            title: "Replaced Container",
            reason: "reason",
            paths: [snapshot],
            risk: .low,
            confidence: .high,
            evidence: [Evidence(kind: .other, detail: "evidence")],
            recommendedAction: .moveToTrash,
            selectedByDefault: true,
            cleanupAllowed: true
        )

        // Race condition: directory is removed and replaced by a plain file
        fs.remove(path)
        fs.addFile(path, size: 200)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let report = await engine.cleanup(selectedItems: [item])
        #expect(!report.isFullySucceeded)
        #expect(report.rejectedCount == 1)
        #expect(report.results.first?.status == .rejected)
        #expect(report.results.first?.errorCategory == .changedSinceScan)
        #expect(trash.movedSources.isEmpty)
        #expect(fs.exists(URL(fileURLWithPath: path)))
    }

    @Test("file replaced by directory between scan and cleanup is rejected")
    func fileReplacedByDirectory() async throws {
        let fs = InMemoryFileSystem()
        let path = "/Users/u/Library/Caches/com.vendor.App/cached.bin"
        let date = Date(timeIntervalSince1970: 50)
        fs.addFile(path, size: 500, modificationDate: date)

        let snapshot = PathSnapshot(
            url: URL(fileURLWithPath: path),
            kind: .file,
            size: 500,
            modificationDate: date
        )
        let item = try CleanupItem(
            category: .applicationCaches,
            title: "Cache File",
            reason: "reason",
            paths: [snapshot],
            risk: .review,
            confidence: .medium,
            evidence: [Evidence(kind: .other, detail: "evidence")],
            recommendedAction: .moveToTrash,
            selectedByDefault: false,
            cleanupAllowed: true,
            modifiedAt: date
        )

        // Race: file is replaced by a directory of the same name
        fs.remove(path)
        fs.addDirectory(path)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let report = await engine.cleanup(selectedItems: [item])
        #expect(!report.isFullySucceeded)
        #expect(report.rejectedCount == 1)
        #expect(report.results.first?.status == .rejected)
        #expect(report.results.first?.errorCategory == .changedSinceScan)
        #expect(trash.movedSources.isEmpty)
    }

    @Test("file modification timestamp change between scan and cleanup is rejected")
    func fileMtimeChanged() async throws {
        let fs = InMemoryFileSystem()
        let path = "/Users/u/Library/Caches/com.vendor.App/modified.bin"
        let scanDate = Date(timeIntervalSince1970: 100)
        let laterDate = Date(timeIntervalSince1970: 200)
        fs.addFile(path, size: 500, modificationDate: laterDate) // on disk: later date

        let snapshot = PathSnapshot(
            url: URL(fileURLWithPath: path),
            kind: .file,
            size: 500,
            modificationDate: scanDate // snapshot had earlier date
        )
        let item = try CleanupItem(
            category: .applicationCaches,
            title: "Mtime Changed",
            reason: "reason",
            paths: [snapshot],
            risk: .review,
            confidence: .medium,
            evidence: [Evidence(kind: .other, detail: "evidence")],
            recommendedAction: .moveToTrash,
            selectedByDefault: false,
            cleanupAllowed: true,
            modifiedAt: scanDate
        )

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let report = await engine.cleanup(selectedItems: [item])
        #expect(!report.isFullySucceeded)
        #expect(report.rejectedCount == 1)
        #expect(report.results.first?.status == .rejected)
        #expect(report.results.first?.errorCategory == .changedSinceScan)
        #expect(trash.movedSources.isEmpty)
    }
}
