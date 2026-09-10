public struct Evidence: Hashable, Codable, Sendable {
    public enum Kind: String, CaseIterable, Codable, Sendable {
        case bundleIdentifierMatch
        case applicationAbsent
        case pathConvention
        case directoryName
        case fileExtension
        case sizeThreshold
        case modificationAge
        case sharedOwnership
        case systemOwnership
        case userProvided
        case other
    }

    public let kind: Kind
    public let detail: String

    public init(kind: Kind, detail: String) {
        self.kind = kind
        self.detail = detail
    }
}
