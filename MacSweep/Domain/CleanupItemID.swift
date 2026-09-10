import CryptoKit
import Foundation

public struct CleanupItemID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.hasPrefix(Self.prefix),
              rawValue.count == Self.prefix.count + 32,
              rawValue.dropFirst(Self.prefix.count).allSatisfy({ $0.isHexDigit }) else { return nil }
        self.rawValue = rawValue
    }

    public init(stableComponents: [String]) {
        var canonical = "macsweep.item/v1"
        for component in stableComponents {
            canonical.append("\n")
            canonical.append(component)
        }
        let digest = SHA256.hash(data: Data(canonical.utf8))
        let hex = digest.prefix(16).map { String(format: "%02x", $0) }.joined()
        self.rawValue = Self.prefix + hex
    }

    private static let prefix = "ms_"

    public var description: String { rawValue }
}
