import Foundation

public final class InMemoryFileSystem: FileSystem, @unchecked Sendable {
    public struct Node: Sendable, Equatable {
        var kind: PathSnapshot.FileKind
        var size: Int64
        var modificationDate: Date
        var linkTarget: URL?
        var inaccessible: Bool
    }

    private let lock = NSLock()
    private var nodes: [String: Node] = [:]

    public init() {}

    public func addFile(_ path: String, size: Int64 = 0, modificationDate: Date = Date(timeIntervalSince1970: 0)) {
        insert(path, kind: .file, size: size, modificationDate: modificationDate, linkTarget: nil)
    }

    public func addDirectory(_ path: String, modificationDate: Date = Date(timeIntervalSince1970: 0)) {
        insert(path, kind: .directory, size: 0, modificationDate: modificationDate, linkTarget: nil)
    }

    public func addSymbolicLink(_ path: String, target: String) {
        let linkSize = Int64(target.utf8.count)
        insert(path, kind: .symbolicLink, size: linkSize, modificationDate: Date(timeIntervalSince1970: 0), linkTarget: URL(fileURLWithPath: target))
    }

    public func markInaccessible(_ path: String) {
        let key = normalize(path)
        lock.lock()
        defer { lock.unlock() }
        guard var node = nodes[key] else { return }
        node.inaccessible = true
        nodes[key] = node
    }

    public func resize(_ path: String, to size: Int64) {
        let key = normalize(path)
        lock.lock()
        defer { lock.unlock() }
        guard var node = nodes[key] else { return }
        node.size = size
        nodes[key] = node
    }

    public func remove(_ path: String) {
        let key = normalize(path)
        lock.lock()
        defer { lock.unlock() }
        nodes.removeValue(forKey: key)
        let prefix = key + "/"
        for entry in nodes.keys where entry.hasPrefix(prefix) {
            nodes.removeValue(forKey: entry)
        }
    }

    public var nodeCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return nodes.count
    }

    public func stat(_ url: URL) throws -> FileMetadata {
        let key = normalize(url.path)
        lock.lock()
        defer { lock.unlock() }
        guard let node = nodes[key] else { throw FileSystemError.notFound(url) }
        if node.inaccessible { throw FileSystemError.permissionDenied(url) }
        let resolved = resolve(key, visited: [])
        return FileMetadata(
            requestedURL: URL(fileURLWithPath: key),
            resolvedURL: resolved,
            kind: node.kind,
            size: node.size,
            modificationDate: node.modificationDate
        )
    }

    public func canonicalizedURL(for url: URL) throws -> URL {
        try stat(url).resolvedURL
    }

    public func immediateChildren(of url: URL) throws -> [URL] {
        let meta = try stat(url)
        guard meta.kind == .directory else { throw FileSystemError.ioFailure(url, "Not a directory") }
        let parentKey = meta.requestedURL.path
        lock.lock()
        let entries = nodes
        lock.unlock()
        let children = entries.keys.filter { key in
            URL(fileURLWithPath: key).deletingLastPathComponent().path == parentKey
        }
        return children.sorted().map { URL(fileURLWithPath: $0) }
    }

    public func totalSize(of url: URL) throws -> Int64 {
        let meta = try stat(url)
        guard meta.kind == .directory else { return meta.size }
        var total: Int64 = 0
        var stack = [meta.requestedURL]
        while let current = stack.popLast() {
            let children: [URL]
            do {
                children = try immediateChildren(of: current)
            } catch {
                continue
            }
            for child in children {
                let childMeta: FileMetadata
                do {
                    childMeta = try stat(child)
                } catch {
                    continue
                }
                switch childMeta.kind {
                case .directory:
                    stack.append(child)
                case .file, .other:
                    total += childMeta.size
                case .symbolicLink:
                    continue
                }
            }
        }
        return total
    }

    public func exists(_ url: URL) -> Bool {
        let key = normalize(url.path)
        lock.lock()
        defer { lock.unlock() }
        return nodes[key] != nil
    }

    private func insert(_ path: String, kind: PathSnapshot.FileKind, size: Int64, modificationDate: Date, linkTarget: URL?) {
        let key = normalize(path)
        lock.lock()
        defer { lock.unlock() }
        var parent = URL(fileURLWithPath: key).deletingLastPathComponent().path
        while parent != "/" && !parent.isEmpty && nodes[parent] == nil {
            nodes[parent] = Node(kind: .directory, size: 0, modificationDate: Date(timeIntervalSince1970: 0), linkTarget: nil, inaccessible: false)
            parent = URL(fileURLWithPath: parent).deletingLastPathComponent().path
        }
        nodes[key] = Node(kind: kind, size: size, modificationDate: modificationDate, linkTarget: linkTarget, inaccessible: false)
    }

    private func resolve(_ key: String, visited: Set<String>) -> URL {
        guard !visited.contains(key) else { return URL(fileURLWithPath: key) }
        guard let node = nodes[key] else { return URL(fileURLWithPath: key) }
        guard node.kind == .symbolicLink, let target = node.linkTarget else { return URL(fileURLWithPath: key) }
        return resolve(normalize(target.path), visited: visited.union([key]))
    }

    private func normalize(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }
}
