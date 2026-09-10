public enum ErrorCategory: String, CaseIterable, Codable, Sendable {
    case permissionDenied
    case notFound
    case changedSinceScan
    case protected
    case invalidItem
    case unsupported
    case ioFailure
    case cancelled
    case insufficientSpace
    case unknown

    public var userFacingName: String {
        switch self {
        case .permissionDenied: "Permission denied"
        case .notFound: "Not found"
        case .changedSinceScan: "Changed since scan"
        case .protected: "Protected"
        case .invalidItem: "Invalid item"
        case .unsupported: "Unsupported"
        case .ioFailure: "Disk error"
        case .cancelled: "Cancelled"
        case .insufficientSpace: "Not enough space"
        case .unknown: "Unexpected problem"
        }
    }
}
