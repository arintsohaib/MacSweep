public protocol ProgressReporter: Sendable {
    func report(_ progress: ScanProgress)
}
