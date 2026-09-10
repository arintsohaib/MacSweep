import Foundation
import Testing

@testable import MacSweep

@Suite("RealFileSystem")
struct RealFileSystemTests {
    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("macsweep-fs-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("totalSize sums a real directory tree exactly and ignores symlinks")
    func totalSizeOfRealTree() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fs = RealFileSystem()
        let root = tempDir.appendingPathComponent("root", isDirectory: true)
        let nested = root.appendingPathComponent("a/b/c", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)

        func write(_ name: String, _ bytes: Int) throws {
            try Data(count: bytes).write(to: root.appendingPathComponent(name))
        }
        try write("one.bin", 1_000)
        try write("a/two.bin", 2_000)
        try write("a/b/c/three.bin", 3_000)

        let link = root.appendingPathComponent("link-to-one")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: root.appendingPathComponent("one.bin"))
        let dangling = root.appendingPathComponent("dangling")
        try FileManager.default.createSymbolicLink(at: dangling, withDestinationURL: root.appendingPathComponent("missing"))

        #expect(try fs.totalSize(of: root) == 6_000)
    }

    @Test("totalSize of a regular file is its own size")
    func totalSizeOfFile() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let file = tempDir.appendingPathComponent("plain.bin")
        try Data(count: 4_321).write(to: file)
        #expect(try RealFileSystem().totalSize(of: file) == 4_321)
    }

    @Test("stat classifies real filesystem entries")
    func statKinds() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fs = RealFileSystem()
        let dir = tempDir.appendingPathComponent("kinds-dir", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("f.bin")
        try Data(count: 7).write(to: file)
        let link = dir.appendingPathComponent("l")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)

        #expect(try fs.stat(dir).kind == .directory)
        #expect(try fs.stat(file).kind == .file)
        #expect(try fs.stat(file).size == 7)
        #expect(try fs.stat(link).kind == .symbolicLink)
        #expect(throws: FileSystemError.self) { try fs.stat(tempDir.appendingPathComponent("nope")) }
    }

    @Test("totalSize of an empty directory is zero")
    func totalSizeOfEmptyDirectory() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let empty = tempDir.appendingPathComponent("empty", isDirectory: true)
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        #expect(try RealFileSystem().totalSize(of: empty) == 0)
    }
}
