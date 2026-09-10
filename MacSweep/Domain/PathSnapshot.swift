import Foundation

public struct PathSnapshot: Hashable, Codable, Sendable {
    public enum FileKind: String, Codable, Sendable {
        case file
        case directory
        case symbolicLink
        case other
    }

    public let url: URL
    public let kind: FileKind
    public let size: Int64
    public let modificationDate: Date?

    public init(url: URL, kind: FileKind, size: Int64, modificationDate: Date?) {
        self.url = url
        self.kind = kind
        self.size = size
        self.modificationDate = modificationDate
    }

    public var isSymbolicLink: Bool { kind == .symbolicLink }

    public var path: String { url.path }
}
