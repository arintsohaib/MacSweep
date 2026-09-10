public enum RiskLevel: Int, CaseIterable, Codable, Sendable, Comparable {
    case low
    case review
    case protected

    public var defaultSelected: Bool { self == .low }

    public var cleanupAllowed: Bool { self != .protected }

    public var displayName: String {
        switch self {
        case .low: "Low risk"
        case .review: "Needs review"
        case .protected: "Protected"
        }
    }

    public static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
