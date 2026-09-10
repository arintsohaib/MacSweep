import Foundation

public struct PathExclusions: Sendable, Equatable {
    private let roots: [String]

    public init(paths: [URL]) {
        roots = paths
            .map { $0.standardizedFileURL.resolvingSymlinksInPath().path }
            .filter { !$0.isEmpty && $0 != "/" }
            .sorted()
    }

    public var isEmpty: Bool { roots.isEmpty }

    public func isExcluded(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.resolvingSymlinksInPath().path
        guard path != "/" else { return false }
        return roots.contains { root in
            path == root || path.hasPrefix(root + "/")
        }
    }
}
