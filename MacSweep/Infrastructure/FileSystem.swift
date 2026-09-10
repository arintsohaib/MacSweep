import Foundation

public struct FileMetadata: Hashable, Sendable {
    public let requestedURL: URL
    public let resolvedURL: URL
    public let kind: PathSnapshot.FileKind
    public let size: Int64
    public let modificationDate: Date

    public init(
        requestedURL: URL,
        resolvedURL: URL,
        kind: PathSnapshot.FileKind,
        size: Int64,
        modificationDate: Date
    ) {
        self.requestedURL = requestedURL
        self.resolvedURL = resolvedURL
        self.kind = kind
        self.size = size
        self.modificationDate = modificationDate
    }

    public var isSymbolicLink: Bool { kind == .symbolicLink }
}

public enum FileSystemError: Error, Equatable {
    case notFound(URL)
    case permissionDenied(URL)
    case ioFailure(URL, String)
    case cancelled

    public var category: ErrorCategory {
        switch self {
        case .notFound: .notFound
        case .permissionDenied: .permissionDenied
        case .ioFailure: .ioFailure
        case .cancelled: .cancelled
        }
    }
}

public protocol FileSystem: Sendable {
    func stat(_ url: URL) throws -> FileMetadata
    func canonicalizedURL(for url: URL) throws -> URL
    func immediateChildren(of url: URL) throws -> [URL]
    func totalSize(of url: URL) throws -> Int64
    func exists(_ url: URL) -> Bool
}
