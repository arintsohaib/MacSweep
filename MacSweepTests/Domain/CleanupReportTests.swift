import Foundation
import Testing

@testable import MacSweep

@Suite("CleanupReport")
struct CleanupReportTests {
    private func id(_ component: String) -> CleanupItemID {
        CleanupItemID(stableComponents: [component])
    }

    @Test("full success is reported as success")
    func fullSuccess() {
        let report = CleanupReport(results: [
            CleanupItemResult(itemID: id("a"), status: .movedToTrash, message: "moved", size: 10),
            CleanupItemResult(itemID: id("b"), status: .alreadyAbsent, message: "absent"),
        ])
        #expect(report.isFullySucceeded)
        #expect(report.movedCount == 1)
        #expect(report.alreadyAbsentCount == 1)
        #expect(report.totalMovedSize == 10)
        #expect(report.summary.contains("successfully"))
    }

    @Test("partial failure is never reported as full success")
    func partialFailure() {
        let report = CleanupReport(results: [
            CleanupItemResult(itemID: id("a"), status: .movedToTrash, message: "moved", size: 10),
            CleanupItemResult(itemID: id("b"), status: .failed, errorCategory: .ioFailure, message: "disk error"),
        ])
        #expect(!report.isFullySucceeded)
        #expect(!report.summary.contains("successfully"))
        #expect(report.summary.contains("with problems"))
    }

    @Test("total moved size counts bytes moved in partially failed items")
    func partialMovedSize() {
        let report = CleanupReport(results: [
            CleanupItemResult(itemID: id("a"), status: .movedToTrash, message: "moved", size: 300),
            CleanupItemResult(itemID: id("b"), status: .failed, errorCategory: .permissionDenied, message: "partially cleaned", size: 700),
            CleanupItemResult(itemID: id("c"), status: .rejected, errorCategory: .protected, message: "rejected"),
        ])
        #expect(report.totalMovedSize == 1000)
        #expect(report.movedCount == 1)
        #expect(report.failedCount == 1)
    }

    @Test("rejection is never reported as success")
    func rejection() {
        let report = CleanupReport(results: [
            CleanupItemResult(itemID: id("a"), status: .rejected, errorCategory: .changedSinceScan, message: "changed since scan", recoverySuggestion: "Re-scan"),
        ])
        #expect(!report.isFullySucceeded)
        #expect(report.rejectedCount == 1)
    }

    @Test("empty report cleans nothing")
    func empty() {
        let report = CleanupReport(results: [])
        #expect(report.summary == "Nothing was cleaned.")
    }
}
