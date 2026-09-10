import Foundation

public struct CleanupItemResult: Identifiable, Hashable, Codable, Sendable {
    public enum Status: String, Codable, Sendable {
        case movedToTrash
        case alreadyAbsent
        case rejected
        case failed
        case cancelled

        public var isSuccess: Bool {
            self == .movedToTrash || self == .alreadyAbsent
        }
    }

    public let id: UUID
    public let itemID: CleanupItemID
    public var status: Status
    public var errorCategory: ErrorCategory?
    public var message: String
    public var recoverySuggestion: String?
    public var size: Int64

    public init(
        id: UUID = UUID(),
        itemID: CleanupItemID,
        status: Status,
        errorCategory: ErrorCategory? = nil,
        message: String,
        recoverySuggestion: String? = nil,
        size: Int64 = 0
    ) {
        self.id = id
        self.itemID = itemID
        self.status = status
        self.errorCategory = errorCategory
        self.message = message
        self.recoverySuggestion = recoverySuggestion
        self.size = size
    }
}

public struct CleanupReport: Sendable {
    public let operationID: UUID
    public let startedAt: Date
    public let finishedAt: Date
    public let results: [CleanupItemResult]

    public init(
        operationID: UUID = UUID(),
        startedAt: Date = Date(),
        finishedAt: Date = Date(),
        results: [CleanupItemResult]
    ) {
        self.operationID = operationID
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.results = results
    }

    public var movedCount: Int { results.filter { $0.status == .movedToTrash }.count }

    public var alreadyAbsentCount: Int { results.filter { $0.status == .alreadyAbsent }.count }

    public var rejectedCount: Int { results.filter { $0.status == .rejected }.count }

    public var failedCount: Int { results.filter { $0.status == .failed }.count }

    public var cancelledCount: Int { results.filter { $0.status == .cancelled }.count }

    public var totalMovedSize: Int64 {
        results.reduce(0) { $0 + $1.size }
    }

    public var isFullySucceeded: Bool {
        results.allSatisfy(\.status.isSuccess)
    }

    public var summary: String {
        if results.isEmpty {
            return "Nothing was cleaned."
        }
        var parts: [String] = []
        if movedCount > 0 { parts.append("\(movedCount) moved to Trash") }
        if alreadyAbsentCount > 0 { parts.append("\(alreadyAbsentCount) already absent") }
        if rejectedCount > 0 { parts.append("\(rejectedCount) rejected") }
        if failedCount > 0 { parts.append("\(failedCount) failed") }
        if cancelledCount > 0 { parts.append("\(cancelledCount) cancelled") }
        let detail = parts.joined(separator: ", ")
        if isFullySucceeded {
            return "Cleaned successfully. \(detail)."
        }
        return "Finished with problems. \(detail). Review each item before trying again."
    }
}
