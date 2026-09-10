import Foundation

public final class CollectingProgressReporter: ProgressReporter, @unchecked Sendable {
    private let lock = NSLock()
    private var history: [ScanProgress] = []

    public init() {}

    public var all: [ScanProgress] {
        lock.lock()
        defer { lock.unlock() }
        return history
    }

    public var latest: ScanProgress? {
        all.last
    }

    public func report(_ progress: ScanProgress) {
        lock.lock()
        history.append(progress)
        lock.unlock()
    }
}
