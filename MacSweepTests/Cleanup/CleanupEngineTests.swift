import Foundation
import Testing

@testable import MacSweep

@Suite("CleanupEngine")
struct CleanupEngineTests {
    private let home = URL(fileURLWithPath: "/Users/u")

    private func makeFileItem(
        path: String,
        size: Int64 = 1024,
        date: Date = Date(timeIntervalSince1970: 100),
        risk: RiskLevel = .low,
        category: ScanCategory = .uninstalledAppRemnants,
        title: String = "Test Item"
    ) throws -> CleanupItem {
        let snapshot = PathSnapshot(
            url: URL(fileURLWithPath: path),
            kind: .file,
            size: size,
            modificationDate: date
        )
        return try CleanupItem(
            category: category,
            title: title,
            reason: "Reason",
            paths: [snapshot],
            risk: risk,
            confidence: .high,
            evidence: [Evidence(kind: .other, detail: "evidence")],
            recommendedAction: risk == .protected ? .reviewOnly : .moveToTrash,
            selectedByDefault: risk == .low,
            cleanupAllowed: risk != .protected,
            modifiedAt: date
        )
    }

    private func makeDirectoryItem(
        path: String,
        size: Int64 = 2048,
        risk: RiskLevel = .low,
        category: ScanCategory = .uninstalledAppRemnants,
        title: String = "Directory Item"
    ) throws -> CleanupItem {
        let snapshot = PathSnapshot(
            url: URL(fileURLWithPath: path),
            kind: .directory,
            size: size,
            modificationDate: nil
        )
        return try CleanupItem(
            category: category,
            title: title,
            reason: "Reason",
            paths: [snapshot],
            risk: risk,
            confidence: .high,
            evidence: [Evidence(kind: .other, detail: "evidence")],
            recommendedAction: risk == .protected ? .reviewOnly : .moveToTrash,
            selectedByDefault: risk == .low,
            cleanupAllowed: risk != .protected
        )
    }

    @Test("selected cleanable item moves to Trash and source is removed")
    func selectedItemMoves() async throws {
        let fs = InMemoryFileSystem()
        let path = "/Users/u/Library/Containers/com.vendor.Gone"
        fs.addDirectory(path)
        fs.addFile("\(path)/data.bin", size: 2048)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let item = try makeDirectoryItem(path: path, size: 2048)
        let report = await engine.cleanup(selectedItems: [item])

        #expect(report.isFullySucceeded)
        #expect(report.movedCount == 1)
        #expect(report.totalMovedSize == 2048)
        #expect(!fs.exists(URL(fileURLWithPath: path)))
        #expect(trash.movedSources.map(\.path).contains(path))
        #expect(report.results.first?.status == .movedToTrash)
    }

    @Test("unselected items remain untouched on the filesystem")
    func unselectedItemsRemain() async throws {
        let fs = InMemoryFileSystem()
        let selectedPath = "/Users/u/Library/Containers/com.vendor.Selected"
        let unselectedPath = "/Users/u/Library/Containers/com.vendor.Untouched"
        fs.addDirectory(selectedPath)
        fs.addFile("\(selectedPath)/a.bin", size: 100)
        fs.addDirectory(unselectedPath)
        fs.addFile("\(unselectedPath)/b.bin", size: 500)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let item = try makeDirectoryItem(path: selectedPath, size: 100)
        let report = await engine.cleanup(selectedItems: [item])

        #expect(report.isFullySucceeded)
        #expect(!fs.exists(URL(fileURLWithPath: selectedPath)))
        #expect(fs.exists(URL(fileURLWithPath: unselectedPath)))
        #expect(!trash.movedSources.map(\.path).contains(unselectedPath))
    }

    @Test("protected item is rejected without moving")
    func protectedItemRejected() async throws {
        let fs = InMemoryFileSystem()
        let path = "/Users/u/Documents/Work"
        fs.addDirectory(path)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let item = try makeDirectoryItem(path: path, risk: .protected, category: .reviewOnly)
        let report = await engine.cleanup(selectedItems: [item])

        #expect(!report.isFullySucceeded)
        #expect(report.rejectedCount == 1)
        #expect(report.results.first?.status == .rejected)
        #expect(report.results.first?.errorCategory == .protected)
        #expect(fs.exists(URL(fileURLWithPath: path)))
        #expect(trash.movedSources.isEmpty)
    }

    @Test("item modified since scan is rejected")
    func modifiedItemRejected() async throws {
        let fs = InMemoryFileSystem()
        let path = "/Users/u/Library/Caches/com.vendor.App/cached.bin"
        let date = Date(timeIntervalSince1970: 100)
        fs.addFile(path, size: 1024, modificationDate: date)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let item = try makeFileItem(path: path, size: 1024, date: date)

        // Modify file size after scan snapshot
        fs.resize(path, to: 2048)

        let report = await engine.cleanup(selectedItems: [item])
        #expect(!report.isFullySucceeded)
        #expect(report.rejectedCount == 1)
        #expect(report.results.first?.status == .rejected)
        #expect(report.results.first?.errorCategory == .changedSinceScan)
        #expect(fs.exists(URL(fileURLWithPath: path)))
        #expect(trash.movedSources.isEmpty)
    }

    @Test("already missing item produces alreadyAbsent status and succeeds")
    func alreadyMissingItem() async throws {
        let fs = InMemoryFileSystem()
        let path = "/Users/u/Library/Caches/com.vendor.App/vanished.bin"
        // Do not add to filesystem (simulating it disappeared before cleanup)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let item = try makeFileItem(path: path, size: 100)
        let report = await engine.cleanup(selectedItems: [item])

        #expect(report.isFullySucceeded)
        #expect(report.alreadyAbsentCount == 1)
        #expect(report.movedCount == 0)
        #expect(report.results.first?.status == .alreadyAbsent)
        #expect(trash.movedSources.isEmpty)
    }

    @Test("partial failure reports failure while accounting for moved paths")
    func partialFailure() async throws {
        let fs = InMemoryFileSystem()
        let path1 = "/Users/u/Library/Caches/com.vendor.Multi/part1.bin"
        let path2 = "/Users/u/Library/Caches/com.vendor.Multi/part2.bin"
        let date = Date(timeIntervalSince1970: 100)
        fs.addFile(path1, size: 300, modificationDate: date)
        fs.addFile(path2, size: 700, modificationDate: date)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        trash.simulateFailure(for: path2, error: FileSystemError.permissionDenied(URL(fileURLWithPath: path2)))

        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let item = try CleanupItem(
            category: .uninstalledAppRemnants,
            title: "Multi-path Item",
            reason: "reason",
            paths: [
                PathSnapshot(url: URL(fileURLWithPath: path1), kind: .file, size: 300, modificationDate: date),
                PathSnapshot(url: URL(fileURLWithPath: path2), kind: .file, size: 700, modificationDate: date),
            ],
            risk: .low,
            confidence: .high,
            evidence: [Evidence(kind: .other, detail: "evidence")],
            recommendedAction: .moveToTrash,
            selectedByDefault: true,
            cleanupAllowed: true
        )

        let report = await engine.cleanup(selectedItems: [item])
        #expect(!report.isFullySucceeded)
        #expect(report.failedCount == 1)
        #expect(report.results.first?.status == .failed)
        #expect(!fs.exists(URL(fileURLWithPath: path1)))
        #expect(fs.exists(URL(fileURLWithPath: path2)))
        #expect(report.results.first?.message.contains("Partially cleaned") == true)
        #expect(report.results.first?.size == 300)
        #expect(report.totalMovedSize == 300)
    }

    @Test("symlink escaping home directory is rejected as protected")
    func symlinkEscapingHome() async throws {
        let fs = InMemoryFileSystem()
        fs.addDirectory("/outside")
        fs.addFile("/outside/system.bin", size: 50)
        let linkPath = "/Users/u/Library/Caches/com.vendor.App/link"
        fs.addSymbolicLink(linkPath, target: "/outside/system.bin")

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let snapshot = PathSnapshot(
            url: URL(fileURLWithPath: linkPath),
            kind: .symbolicLink,
            size: 0,
            modificationDate: nil
        )
        let item = try CleanupItem(
            category: .uninstalledAppRemnants,
            title: "Escaping Link",
            reason: "reason",
            paths: [snapshot],
            risk: .low,
            confidence: .medium,
            evidence: [Evidence(kind: .other, detail: "evidence")],
            recommendedAction: .moveToTrash,
            selectedByDefault: true,
            cleanupAllowed: true
        )

        let report = await engine.cleanup(selectedItems: [item])
        #expect(!report.isFullySucceeded)
        #expect(report.rejectedCount == 1)
        #expect(report.results.first?.status == .rejected)
        #expect(report.results.first?.errorCategory == .protected)
        #expect(trash.movedSources.isEmpty)
    }

    @Test("cleanup is idempotent: repeating it reports already absent")
    func idempotency() async throws {
        let fs = InMemoryFileSystem()
        let path = "/Users/u/Library/Containers/com.vendor.Once"
        fs.addDirectory(path)
        fs.addFile("\(path)/data.bin", size: 1024)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let item = try makeDirectoryItem(path: path, size: 1024)

        let firstReport = await engine.cleanup(selectedItems: [item])
        #expect(firstReport.isFullySucceeded)
        #expect(firstReport.movedCount == 1)

        let secondReport = await engine.cleanup(selectedItems: [item])
        #expect(secondReport.isFullySucceeded)
        #expect(secondReport.alreadyAbsentCount == 1)
        #expect(secondReport.movedCount == 0)
    }

    @Test("cancellation cancels remaining items without moving them")
    func cancellation() async throws {
        let fs = InMemoryFileSystem()
        let path1 = "/Users/u/Library/Containers/com.vendor.App1"
        let path2 = "/Users/u/Library/Containers/com.vendor.App2"
        fs.addDirectory(path1)
        fs.addDirectory(path2)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let item1 = try makeDirectoryItem(path: path1, size: 100)
        let item2 = try makeDirectoryItem(path: path2, size: 100)

        let task = Task { () -> CleanupReport in
            try? await Task.sleep(for: .milliseconds(50))
            return await engine.cleanup(selectedItems: [item1, item2])
        }
        task.cancel()
        let report = await task.value

        #expect(report.results.allSatisfy { $0.status == .cancelled })
        #expect(trash.movedSources.isEmpty)
    }
}
