import Darwin
import Foundation

public struct RealFileSystem: FileSystem, Sendable {
    public init() {}

    public func stat(_ url: URL) throws -> FileMetadata {
        var info = Darwin.stat()
        let status = lstat(url.path, &info)
        guard status == 0 else {
            throw Self.mapPOSIXError(url, code: errno)
        }
        let kind: PathSnapshot.FileKind
        let mode = info.st_mode & S_IFMT
        if mode == S_IFLNK {
            kind = .symbolicLink
        } else if mode == S_IFDIR {
            kind = .directory
        } else if mode == S_IFREG {
            kind = .file
        } else {
            kind = .other
        }
        let requested = url.standardizedFileURL
        let resolved: URL
        if kind == .symbolicLink {
            resolved = try canonicalizedURL(for: requested)
        } else {
            resolved = requested
        }
        let seconds = TimeInterval(info.st_mtimespec.tv_sec)
        let nanos = TimeInterval(info.st_mtimespec.tv_nsec)
        return FileMetadata(
            requestedURL: requested,
            resolvedURL: resolved,
            kind: kind,
            size: Int64(info.st_size),
            modificationDate: Date(timeIntervalSince1970: seconds + nanos / 1_000_000_000)
        )
    }

    public func canonicalizedURL(for url: URL) throws -> URL {
        var info = Darwin.stat()
        let status = lstat(url.path, &info)
        guard status == 0 else {
            throw Self.mapPOSIXError(url, code: errno)
        }
        return url.standardizedFileURL.resolvingSymlinksInPath()
    }

    public func immediateChildren(of url: URL) throws -> [URL] {
        do {
            let children = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            return children.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        } catch let error as FileSystemError {
            throw error
        } catch {
            throw Self.mapFoundationError(url, error)
        }
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
        var info = Darwin.stat()
        return lstat(url.path, &info) == 0
    }

    static func mapPOSIXError(_ url: URL, code: Int32) -> FileSystemError {
        switch code {
        case ENOENT, ENOTDIR:
            return .notFound(url)
        case EACCES, EPERM:
            return .permissionDenied(url)
        default:
            return .ioFailure(url, String(cString: strerror(code)))
        }
    }

    static func mapFoundationError(_ url: URL, _ error: Error) -> FileSystemError {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain {
            switch nsError.code {
            case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
                return .permissionDenied(url)
            case NSFileNoSuchFileError:
                return .notFound(url)
            default:
                break
            }
        }
        return .ioFailure(url, nsError.localizedDescription)
    }
}
