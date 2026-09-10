import Foundation

public struct HistoricalItemResult: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let itemID: String
    public let title: String
    public let category: ScanCategory
    public let status: CleanupItemResult.Status
    public let size: Int64
    public let message: String

    public init(
        id: UUID = UUID(),
        itemID: String,
        title: String,
        category: ScanCategory,
        status: CleanupItemResult.Status,
        size: Int64,
        message: String
    ) {
        self.id = id
        self.itemID = itemID
        self.title = title
        self.category = category
        self.status = status
        self.size = size
        self.message = message
    }
}

public struct HistoricalCleanupRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let itemCount: Int
    public let totalMovedSize: Int64
    public let summary: String
    public let results: [HistoricalItemResult]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        itemCount: Int,
        totalMovedSize: Int64,
        summary: String,
        results: [HistoricalItemResult]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.itemCount = itemCount
        self.totalMovedSize = totalMovedSize
        self.summary = summary
        self.results = results
    }
}
