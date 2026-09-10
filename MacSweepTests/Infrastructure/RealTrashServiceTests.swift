import Foundation
import Testing

@testable import MacSweep

@Suite("RealTrashService")
struct RealTrashServiceTests {
    @Test("moves a fixture file into the user Trash")
    func moveToTrash() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacSweepTrashTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("macsweep-trash-test.txt")
        try Data("MacSweep test fixture. Safe to delete from Trash.\n".utf8).write(to: file)

        let service = RealTrashService()
        let destination = try service.move(toTrash: file)

        #expect(!FileManager.default.fileExists(atPath: file.path))
        #expect(FileManager.default.fileExists(atPath: destination.path))

        let trashURL = try FileManager.default.url(for: .trashDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        #expect(destination.path.hasPrefix(trashURL.path))
    }

    @Test("missing source is reported as notFound")
    func missingSource() {
        let service = RealTrashService()
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacSweepTrashTests-\(UUID().uuidString)")
            .appendingPathComponent("no-such-file.txt")
        #expect(throws: FileSystemError.self) {
            _ = try service.move(toTrash: missing)
        }
    }
}
