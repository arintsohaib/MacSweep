import Foundation

public final class RecordingTrashService: TrashService, @unchecked Sendable {
    public struct Move: Sendable, Equatable {
        public let source: URL
        public let destination: URL
    }

    private let lock = NSLock()
    private var _moves: [Move] = []
    private var _failures: [String: any Error] = [:]
    private let simulatedFileSystem: InMemoryFileSystem?

    public init(simulatedFileSystem: InMemoryFileSystem? = nil) {
        self.simulatedFileSystem = simulatedFileSystem
    }

    public var moves: [Move] {
        lock.lock()
        defer { lock.unlock() }
        return _moves
    }

    public var movedSources: [URL] {
        moves.map(\.source)
    }

    public func simulateFailure(for path: String, error: any Error) {
        lock.lock()
        defer { lock.unlock() }
        _failures[path] = error
    }

    public func move(toTrash url: URL) throws -> URL {
        let key = url.standardizedFileURL.path
        lock.lock()
        let failure = _failures[key]
        lock.unlock()
        if let failure {
            throw failure
        }
        let destination = URL(fileURLWithPath: "/Users/test/.Trash/\(url.lastPathComponent)")
        simulatedFileSystem?.remove(url.path)
        lock.lock()
        _moves.append(Move(source: url, destination: destination))
        lock.unlock()
        return destination
    }
}
