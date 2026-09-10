import Foundation

public enum ScanError: Error, Equatable {
    case cancelled
    case failed(String)
}

public struct ScanConfiguration: Sendable, Equatable {
    public let minLargeFileSize: Int64

    public init(minLargeFileSize: Int64 = 512 * 1024 * 1024) {
        self.minLargeFileSize = minLargeFileSize
    }
}

public struct ScanContext: Sendable {
    public let operationID: UUID
    public let fileSystem: any FileSystem
    public let applications: any ApplicationRegistry
    public let exclusions: PathExclusions
    public let configuration: ScanConfiguration
    public let progress: any ProgressReporter
    public let diagnostics: DiagnosticCollector
    public let homeDirectory: URL

    public init(
        operationID: UUID,
        fileSystem: any FileSystem,
        applications: any ApplicationRegistry,
        exclusions: PathExclusions,
        configuration: ScanConfiguration = ScanConfiguration(),
        progress: any ProgressReporter,
        diagnostics: DiagnosticCollector,
        homeDirectory: URL
    ) {
        self.operationID = operationID
        self.fileSystem = fileSystem
        self.applications = applications
        self.exclusions = exclusions
        self.configuration = configuration
        self.progress = progress
        self.diagnostics = diagnostics
        self.homeDirectory = homeDirectory
    }

    public var isCancelled: Bool { Task.isCancelled }

    public func checkCancellation() throws {
        if Task.isCancelled {
            throw ScanError.cancelled
        }
    }
}

public protocol FindingsScanner: Sendable {
    var category: ScanCategory { get }
    func scan(context: ScanContext) async throws -> [CleanupItem]
}
