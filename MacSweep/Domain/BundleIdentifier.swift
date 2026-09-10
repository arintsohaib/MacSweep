import Foundation

public struct BundleIdentifier: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let rawValue: String

    public init?(rawValue: String) {
        guard Self.isValid(rawValue) else { return nil }
        self.rawValue = rawValue
    }

    public init(validating rawValue: String) throws {
        guard let identifier = BundleIdentifier(rawValue: rawValue) else {
            throw BundleIdentifierError.invalidFormat
        }
        self = identifier
    }

    public static func isValid(_ value: String) -> Bool {
        guard (1...255).contains(value.count),
              !value.hasPrefix("."),
              !value.hasSuffix("."),
              !value.contains("..") else { return false }
        let segments = value.components(separatedBy: ".")
        guard segments.count >= 2 else { return false }
        return segments.allSatisfy { segment in
            guard (1...63).contains(segment.count) else { return false }
            guard let first = segment.first, first.isASCII, first.isLetter || first.isNumber else { return false }
            guard let last = segment.last, last.isASCII, last.isLetter || last.isNumber else { return false }
            return segment.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
        }
    }

    public var normalized: String { rawValue.lowercased() }

    public static func == (lhs: BundleIdentifier, rhs: BundleIdentifier) -> Bool {
        lhs.normalized == rhs.normalized
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(normalized)
    }

    public static func < (lhs: BundleIdentifier, rhs: BundleIdentifier) -> Bool {
        lhs.normalized < rhs.normalized
    }

    public var description: String { rawValue }
}

public enum BundleIdentifierError: Error, Equatable {
    case invalidFormat
}
