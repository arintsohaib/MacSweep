import Foundation

public final class DiagnosticCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var diagnostics: [ScanDiagnostic] = []

    public init() {}

    public func record(severity: ScanDiagnostic.Severity, category: ErrorCategory, path: URL? = nil, message: String) {
        let diagnostic = ScanDiagnostic(severity: severity, category: category, path: path, message: message)
        lock.lock()
        diagnostics.append(diagnostic)
        lock.unlock()
    }

    public var all: [ScanDiagnostic] {
        lock.lock()
        defer { lock.unlock() }
        return diagnostics
    }
}
