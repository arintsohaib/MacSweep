import Foundation

public struct ScanDiagnostic: Identifiable, Hashable, Codable, Sendable {
    public enum Severity: String, Codable, Sendable {
        case notice
        case warning
        case error
    }

    public let id: UUID
    public var severity: Severity
    public var category: ErrorCategory
    public var path: URL?
    public var message: String
    public var occurredAt: Date

    public init(
        id: UUID = UUID(),
        severity: Severity,
        category: ErrorCategory,
        path: URL? = nil,
        message: String,
        occurredAt: Date = Date()
    ) {
        self.id = id
        self.severity = severity
        self.category = category
        self.path = path
        self.message = message
        self.occurredAt = occurredAt
    }
}
