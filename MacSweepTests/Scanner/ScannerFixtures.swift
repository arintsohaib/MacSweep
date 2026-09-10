import Foundation
import Testing

@testable import MacSweep

struct FixtureFailure: Error, Equatable {
    let message: String
}

struct StaticScanner: FindingsScanner {
    let category: ScanCategory
    let items: [CleanupItem]

    func scan(context: ScanContext) async throws -> [CleanupItem] {
        items
    }
}

struct FailingScanner: FindingsScanner {
    let category: ScanCategory
    let failure: FixtureFailure

    func scan(context: ScanContext) async throws -> [CleanupItem] {
        throw failure
    }
}

struct CancellableScanner: FindingsScanner {
    let category: ScanCategory
    let delay: Duration
    let items: [CleanupItem]

    func scan(context: ScanContext) async throws -> [CleanupItem] {
        try await Task.sleep(for: delay)
        try context.checkCancellation()
        return items
    }
}

enum ScannerFixtures {
    static func item(
        category: ScanCategory,
        path: String,
        size: Int64 = 1024,
        risk: RiskLevel = .low,
        title: String
    ) throws -> CleanupItem {
        try CleanupItem(
            category: category,
            title: title,
            reason: "fixture finding",
            paths: [PathSnapshot(url: URL(fileURLWithPath: path), kind: .directory, size: size, modificationDate: nil)],
            risk: risk,
            confidence: .medium,
            evidence: [Evidence(kind: .other, detail: "fixture evidence")],
            recommendedAction: risk == .protected ? .reviewOnly : .moveToTrash,
            selectedByDefault: false,
            cleanupAllowed: risk != .protected
        )
    }
}
