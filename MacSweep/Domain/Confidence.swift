public enum Confidence: Int, CaseIterable, Codable, Sendable, Comparable {
    case low
    case medium
    case high

    public var displayName: String {
        switch self {
        case .low: "Low confidence"
        case .medium: "Medium confidence"
        case .high: "High confidence"
        }
    }

    public static func < (lhs: Confidence, rhs: Confidence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
