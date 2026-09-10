import Foundation
import Testing

@testable import MacSweep

@Suite("SecurityAudit")
struct SecurityAuditTests {
    private let home = URL(fileURLWithPath: "/Users/u")

    @Test("traversal tricks cannot bypass protected path enforcement")
    func pathTraversalAttacks() {
        let rules = ProtectedPathRules(homeDirectory: home)

        // Traversal attempting to escape into Documents or system roots
        let traversalToDocs = URL(fileURLWithPath: "/Users/u/Library/Caches/../../Documents/Secret.txt")
        #expect(rules.isProtected(traversalToDocs))

        let traversalToEtc = URL(fileURLWithPath: "/Users/u/Library/Containers/../../../../etc/passwd")
        #expect(rules.isProtected(traversalToEtc))

        let traversalToSSH = URL(fileURLWithPath: "/Users/u/Library/Caches/com.app/../../../.ssh/id_rsa")
        #expect(rules.isProtected(traversalToSSH))

        let rootTraversal = URL(fileURLWithPath: "/Users/u/../../../../../../")
        #expect(rules.isProtected(rootTraversal))
    }

    @Test("symlink pointing to sensitive file is rejected during cleanup")
    func symlinkToSensitiveFileRejected() async throws {
        let fs = InMemoryFileSystem()
        fs.addDirectory("/Users/u/.ssh")
        fs.addFile("/Users/u/.ssh/id_ed25519", size: 400)

        let maliciousLink = "/Users/u/Library/Containers/com.vendor.Malicious"
        fs.addSymbolicLink(maliciousLink, target: "/Users/u/.ssh/id_ed25519")

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let snapshot = PathSnapshot(
            url: URL(fileURLWithPath: maliciousLink),
            kind: .symbolicLink,
            size: 0,
            modificationDate: nil
        )
        let item = try CleanupItem(
            category: .uninstalledAppRemnants,
            title: "Malicious Container",
            reason: "reason",
            paths: [snapshot],
            risk: .low,
            confidence: .high,
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
        #expect(fs.exists(URL(fileURLWithPath: "/Users/u/.ssh/id_ed25519")))
    }

    @Test("symlink pointing to system root is rejected during cleanup")
    func symlinkToSystemRootRejected() async throws {
        let fs = InMemoryFileSystem()
        let maliciousLink = "/Users/u/Library/Caches/com.vendor.SystemEscape"
        fs.addSymbolicLink(maliciousLink, target: "/System/Library")

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let snapshot = PathSnapshot(
            url: URL(fileURLWithPath: maliciousLink),
            kind: .symbolicLink,
            size: 0,
            modificationDate: nil
        )
        let item = try CleanupItem(
            category: .uninstalledAppRemnants,
            title: "System Escape",
            reason: "reason",
            paths: [snapshot],
            risk: .low,
            confidence: .high,
            evidence: [Evidence(kind: .other, detail: "evidence")],
            recommendedAction: .moveToTrash,
            selectedByDefault: true,
            cleanupAllowed: true
        )

        let report = await engine.cleanup(selectedItems: [item])
        #expect(!report.isFullySucceeded)
        #expect(report.rejectedCount == 1)
        #expect(report.results.first?.status == .rejected)
        #expect(trash.movedSources.isEmpty)
    }

    @Test("paths outside the user home folder cannot be cleaned")
    func pathsOutsideHomeRejected() async throws {
        let fs = InMemoryFileSystem()
        fs.addDirectory("/var/tmp/data")
        fs.addFile("/var/tmp/data/file.bin", size: 100)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let snapshot = PathSnapshot(
            url: URL(fileURLWithPath: "/var/tmp/data/file.bin"),
            kind: .file,
            size: 100,
            modificationDate: nil
        )
        let item = try CleanupItem(
            category: .largeFiles,
            title: "Outside File",
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

    @Test("large files in personal folders are review-only and can never be cleaned")
    func largeFilesInPersonalFoldersAreReviewOnly() async throws {
        let fs = InMemoryFileSystem()
        let path = "/Users/u/Downloads/video.mp4"
        fs.addFile(path, size: 600 * 1024 * 1024)

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        // Scanner shape: review-only, cleanup not allowed
        let item = try CleanupItem(
            category: .largeFiles,
            title: "video.mp4",
            reason: "large file in personal folder",
            paths: [PathSnapshot(url: URL(fileURLWithPath: path), kind: .file, size: 600 * 1024 * 1024, modificationDate: nil)],
            risk: .review,
            confidence: .high,
            evidence: [Evidence(kind: .sizeThreshold, detail: "evidence")],
            recommendedAction: .reviewOnly,
            selectedByDefault: false,
            cleanupAllowed: false
        )
        #expect(!item.cleanupAllowed)

        // Even if forced through the engine, protected-path revalidation rejects it
        let report = await engine.cleanup(selectedItems: [item])
        #expect(report.rejectedCount == 1)
        #expect(report.results.first?.errorCategory == .protected)
        #expect(fs.exists(URL(fileURLWithPath: path)))
        #expect(trash.movedSources.isEmpty)
    }
}
