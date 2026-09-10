import Foundation

public struct ScanResult: Sendable {
    public let operationID: UUID
    public let startedAt: Date
    public let finishedAt: Date
    public let items: [CleanupItem]
    public let diagnostics: [ScanDiagnostic]
    public let isCancelled: Bool

    public init(
        operationID: UUID = UUID(),
        startedAt: Date = Date(),
        finishedAt: Date = Date(),
        items: [CleanupItem],
        diagnostics: [ScanDiagnostic] = [],
        isCancelled: Bool = false
    ) {
        self.operationID = operationID
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.items = items
        self.diagnostics = diagnostics
        self.isCancelled = isCancelled
    }

    public var totalFoundSize: Int64 {
        items.reduce(0) { $0 + $1.totalSize }
    }

    public var reclaimableSize: Int64 {
        items.filter(\.cleanupAllowed).reduce(0) { $0 + $1.totalSize }
    }

    public var permissionLimitations: [ScanDiagnostic] {
        diagnostics.filter { $0.category == .permissionDenied }
    }

    public func items(in category: ScanCategory) -> [CleanupItem] {
        items.filter { $0.category == category }
    }
}
