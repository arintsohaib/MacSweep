import Foundation
import Testing

@testable import MacSweep

@Suite("InMemoryFileSystem")
struct InMemoryFileSystemTests {
    @Test("stat reports files, directories, and links")
    func stat() throws {
        let fs = InMemoryFileSystem()
        fs.addDirectory("/data")
        fs.addFile("/data/a.txt", size: 100)
        fs.addSymbolicLink("/data/link", target: "/data/a.txt")

        let file = try fs.stat(URL(fileURLWithPath: "/data/a.txt"))
        #expect(file.kind == .file)
        #expect(file.size == 100)

        let directory = try fs.stat(URL(fileURLWithPath: "/data"))
        #expect(directory.kind == .directory)

        let link = try fs.stat(URL(fileURLWithPath: "/data/link"))
        #expect(link.kind == .symbolicLink)
        #expect(link.resolvedURL.path == "/data/a.txt")
    }

    @Test("missing paths throw notFound")
    func notFound() {
        let fs = InMemoryFileSystem()
        #expect(throws: FileSystemError.notFound(URL(fileURLWithPath: "/nope"))) {
            _ = try fs.stat(URL(fileURLWithPath: "/nope"))
        }
    }

    @Test("inaccessible paths throw permissionDenied")
    func permissionDenied() {
        let fs = InMemoryFileSystem()
        fs.addFile("/data/secret.txt", size: 10)
        fs.markInaccessible("/data/secret.txt")
        #expect(throws: FileSystemError.self) {
            _ = try fs.stat(URL(fileURLWithPath: "/data/secret.txt"))
        }
        #expect(fs.exists(URL(fileURLWithPath: "/data/secret.txt")))
    }

    @Test("children are sorted and only immediate")
    func children() throws {
        let fs = InMemoryFileSystem()
        fs.addDirectory("/data")
        fs.addFile("/data/b.txt", size: 1)
        fs.addFile("/data/A.txt", size: 1)
        fs.addDirectory("/data/sub")
        fs.addFile("/data/sub/deep.txt", size: 1)

        let children = try fs.immediateChildren(of: URL(fileURLWithPath: "/data"))
        #expect(children.map(\.lastPathComponent) == ["A.txt", "b.txt", "sub"])
    }

    @Test("total size sums files without following symlinked directories")
    func totalSize() throws {
        let fs = InMemoryFileSystem()
        fs.addDirectory("/data")
        fs.addFile("/data/a.txt", size: 100)
        fs.addDirectory("/data/sub")
        fs.addFile("/data/sub/b.txt", size: 250)
        fs.addDirectory("/outside")
        fs.addFile("/outside/c.txt", size: 9999)
        fs.addSymbolicLink("/data/link", target: "/outside")

        #expect(try fs.totalSize(of: URL(fileURLWithPath: "/data")) == 350)
        #expect(try fs.totalSize(of: URL(fileURLWithPath: "/data/a.txt")) == 100)
    }

    @Test("canonicalization resolves symlink chains")
    func canonicalization() throws {
        let fs = InMemoryFileSystem()
        fs.addFile("/real/file.txt", size: 1)
        fs.addSymbolicLink("/link1", target: "/real/file.txt")
        fs.addSymbolicLink("/link2", target: "/link1")

        let resolved = try fs.canonicalizedURL(for: URL(fileURLWithPath: "/link2"))
        #expect(resolved.path == "/real/file.txt")
    }

    @Test("disappearing files become notFound")
    func disappearingFile() throws {
        let fs = InMemoryFileSystem()
        fs.addFile("/data/gone.txt", size: 10)
        _ = try fs.stat(URL(fileURLWithPath: "/data/gone.txt"))
        fs.remove("/data/gone.txt")
        #expect(throws: FileSystemError.notFound(URL(fileURLWithPath: "/data/gone.txt"))) {
            _ = try fs.stat(URL(fileURLWithPath: "/data/gone.txt"))
        }
    }

    @Test("resizing changes reported sizes")
    func resize() throws {
        let fs = InMemoryFileSystem()
        fs.addDirectory("/data")
        fs.addFile("/data/a.txt", size: 10)
        fs.resize("/data/a.txt", to: 42)
        #expect(try fs.totalSize(of: URL(fileURLWithPath: "/data")) == 42)
    }

    @Test("symlink cycles do not loop")
    func symlinkCycle() throws {
        let fs = InMemoryFileSystem()
        fs.addSymbolicLink("/cycle/a", target: "/cycle/b")
        fs.addSymbolicLink("/cycle/b", target: "/cycle/a")
        let resolved = try fs.canonicalizedURL(for: URL(fileURLWithPath: "/cycle/a"))
        #expect(!resolved.path.isEmpty)
    }
}
