import Foundation

public protocol TrashService: Sendable {
    func move(toTrash url: URL) throws -> URL
}

public struct RealTrashService: TrashService {
    public init() {}

    public func move(toTrash url: URL) throws -> URL {
        var resulting: NSURL?
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: &resulting)
        } catch let error as FileSystemError {
            throw error
        } catch {
            throw RealFileSystem.mapFoundationError(url, error)
        }
        guard let resulting else {
            throw FileSystemError.ioFailure(url, "Trash move reported no resulting URL")
        }
        return resulting as URL
    }
}
