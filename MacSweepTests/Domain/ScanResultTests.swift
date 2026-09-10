import Foundation
import Testing

@testable import MacSweep

@Suite("ScanResult")
struct ScanResultTests {
    private func item(_ category: ScanCategory, size: Int64, cleanupAllowed: Bool) throws -> CleanupItem {
        try CleanupItem(
            category: category,
            title: "item",
            reason: "reason",
            paths: [PathSnapshot(url: URL(fileURLWithPath: "/Users/u/\(UUID().uuidString)"), kind: .directory, size: size, modificationDate: nil)],
            risk: cleanupAllowed ? .low : .protected,
            confidence: .medium,
            evidence: [Evidence(kind: .other, detail: "d")],
            recommendedAction: cleanupAllowed ? .moveToTrash : .reviewOnly,
            selectedByDefault: false,
            cleanupAllowed: cleanupAllowed
        )
    }

    @Test("reclaimable size excludes protected items")
    func reclaimable() throws {
        let allowed = try item(.logs, size: 100, cleanupAllowed: true)
        let protected = try item(.reviewOnly, size: 50, cleanupAllowed: false)
        let result = ScanResult(items: [allowed, protected], diagnostics: [])
        #expect(result.totalFoundSize == 150)
        #expect(result.reclaimableSize == 100)
    }

    @Test("permission limitations are surfaced")
    func limitations() {
        let diagnostic = ScanDiagnostic(severity: .warning, category: .permissionDenied, path: URL(fileURLWithPath: "/Users/u/Protected"), message: "Access denied")
        let result = ScanResult(items: [], diagnostics: [diagnostic])
        #expect(result.permissionLimitations.count == 1)
        #expect(result.permissionLimitations.first?.category == .permissionDenied)
    }

    @Test("items can be filtered by category")
    func filterByCategory() throws {
        let log = try item(.logs, size: 10, cleanupAllowed: true)
        let cache = try item(.applicationCaches, size: 20, cleanupAllowed: true)
        let result = ScanResult(items: [log, cache], diagnostics: [])
        #expect(result.items(in: .logs).count == 1)
        #expect(result.items(in: .applicationCaches).count == 1)
    }
}
