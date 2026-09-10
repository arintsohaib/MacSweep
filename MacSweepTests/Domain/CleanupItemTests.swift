import Foundation
import Testing

@testable import MacSweep

@Suite("CleanupItem")
struct CleanupItemTests {
    private func snapshot(_ path: String, size: Int64 = 1024, kind: PathSnapshot.FileKind = .directory) -> PathSnapshot {
        PathSnapshot(url: URL(fileURLWithPath: path), kind: kind, size: size, modificationDate: nil)
    }

    @Test("valid item builds with a derived stable id")
    func validItem() throws {
        let item = try CleanupItem(
            category: .uninstalledAppRemnants,
            application: ApplicationIdentity(bundleIdentifier: try BundleIdentifier(validating: "com.example.Gone"), name: "Gone", isInstalled: false),
            title: "Gone",
            reason: "Application is no longer installed.",
            paths: [snapshot("/Users/u/Library/Containers/com.example.gone")],
            risk: .low,
            confidence: .high,
            evidence: [Evidence(kind: .applicationAbsent, detail: "No installed app with this bundle identifier")],
            recommendedAction: .moveToTrash,
            selectedByDefault: true,
            cleanupAllowed: true
        )
        #expect(item.id.rawValue.hasPrefix("ms_"))
        #expect(item.totalSize == 1024)
        #expect(item.cleanupAllowed)
        #expect(item.selectedByDefault)
    }

    @Test("stable id does not depend on size or metadata")
    func stableAcrossMetadata() throws {
        func make(size: Int64) -> CleanupItem {
            try! CleanupItem(
                category: .logs,
                title: "t",
                reason: "r",
                paths: [snapshot("/Users/u/Library/Logs/app.log", size: size, kind: .file)],
                risk: .low,
                confidence: .medium,
                evidence: [Evidence(kind: .pathConvention, detail: "known log location")],
                recommendedAction: .moveToTrash,
                selectedByDefault: false,
                cleanupAllowed: true
            )
        }
        #expect(make(size: 100).id == make(size: 999_999).id)
    }

    @Test("empty paths are rejected")
    func emptyPaths() {
        #expect(throws: CleanupItemError.emptyPaths) {
            _ = try CleanupItem(
                category: .logs,
                title: "t",
                reason: "r",
                paths: [],
                risk: .low,
                confidence: .low,
                evidence: [Evidence(kind: .other, detail: "d")],
                recommendedAction: .moveToTrash,
                selectedByDefault: false,
                cleanupAllowed: true
            )
        }
    }

    @Test("missing evidence is rejected")
    func missingEvidence() {
        #expect(throws: CleanupItemError.missingEvidence) {
            _ = try CleanupItem(
                category: .logs,
                title: "t",
                reason: "r",
                paths: [snapshot("/Users/u/x")],
                risk: .low,
                confidence: .low,
                evidence: [],
                recommendedAction: .moveToTrash,
                selectedByDefault: false,
                cleanupAllowed: true
            )
        }
    }

    @Test("nested paths are rejected")
    func nestedPaths() {
        #expect(throws: CleanupItemError.self) {
            _ = try CleanupItem(
                category: .uninstalledAppRemnants,
                title: "t",
                reason: "r",
                paths: [snapshot("/Users/u/Library/Caches"), snapshot("/Users/u/Library/Caches/foo")],
                risk: .low,
                confidence: .low,
                evidence: [Evidence(kind: .other, detail: "d")],
                recommendedAction: .moveToTrash,
                selectedByDefault: false,
                cleanupAllowed: true
            )
        }
    }

    @Test("duplicate paths are rejected")
    func duplicatePaths() {
        #expect(throws: CleanupItemError.self) {
            _ = try CleanupItem(
                category: .uninstalledAppRemnants,
                title: "t",
                reason: "r",
                paths: [snapshot("/Users/u/Library/Caches/foo"), snapshot("/Users/u/Library/Caches/foo")],
                risk: .low,
                confidence: .low,
                evidence: [Evidence(kind: .other, detail: "d")],
                recommendedAction: .moveToTrash,
                selectedByDefault: false,
                cleanupAllowed: true
            )
        }
    }

    @Test("non-file or root urls are rejected")
    func invalidURLs() {
        let web = PathSnapshot(url: URL(string: "https://example.com/data")!, kind: .file, size: 1, modificationDate: nil)
        #expect(throws: CleanupItemError.self) {
            _ = try CleanupItem(category: .logs, title: "t", reason: "r", paths: [web], risk: .low, confidence: .low, evidence: [Evidence(kind: .other, detail: "d")], recommendedAction: .moveToTrash, selectedByDefault: false, cleanupAllowed: true)
        }
        let root = PathSnapshot(url: URL(fileURLWithPath: "/"), kind: .directory, size: 0, modificationDate: nil)
        #expect(throws: CleanupItemError.self) {
            _ = try CleanupItem(category: .logs, title: "t", reason: "r", paths: [root], risk: .low, confidence: .low, evidence: [Evidence(kind: .other, detail: "d")], recommendedAction: .moveToTrash, selectedByDefault: false, cleanupAllowed: true)
        }
    }

    @Test("protected items cannot be cleanable or preselected")
    func protectedInvariants() {
        #expect(throws: CleanupItemError.self) {
            _ = try CleanupItem(category: .reviewOnly, title: "t", reason: "r", paths: [snapshot("/Users/u/Documents/x")], risk: .protected, confidence: .high, evidence: [Evidence(kind: .systemOwnership, detail: "user documents")], recommendedAction: .moveToTrash, selectedByDefault: false, cleanupAllowed: true)
        }
        #expect(throws: CleanupItemError.self) {
            _ = try CleanupItem(category: .reviewOnly, title: "t", reason: "r", paths: [snapshot("/Users/u/Documents/x")], risk: .protected, confidence: .high, evidence: [Evidence(kind: .systemOwnership, detail: "user documents")], recommendedAction: .reviewOnly, selectedByDefault: true, cleanupAllowed: false)
        }
    }

    @Test("cleanable items must recommend trash")
    func actionConsistency() {
        #expect(throws: CleanupItemError.self) {
            _ = try CleanupItem(category: .logs, title: "t", reason: "r", paths: [snapshot("/Users/u/Library/Logs/a.log")], risk: .low, confidence: .low, evidence: [Evidence(kind: .other, detail: "d")], recommendedAction: .reviewOnly, selectedByDefault: false, cleanupAllowed: true)
        }
    }

    @Test("total size sums path sizes")
    func totalSize() throws {
        let item = try CleanupItem(
            category: .largeFiles,
            title: "t",
            reason: "r",
            paths: [snapshot("/a", size: 100, kind: .file), snapshot("/b", size: 250, kind: .file)],
            risk: .low,
            confidence: .medium,
            evidence: [Evidence(kind: .sizeThreshold, detail: "large")],
            recommendedAction: .moveToTrash,
            selectedByDefault: false,
            cleanupAllowed: true
        )
        #expect(item.totalSize == 350)
    }
}
