import Foundation

public struct ApplicationIdentity: Hashable, Codable, Sendable {
    public var bundleIdentifier: BundleIdentifier?
    public var name: String
    public var bundleURL: URL?
    public var version: String?
    public var isInstalled: Bool

    public init(
        bundleIdentifier: BundleIdentifier?,
        name: String,
        bundleURL: URL? = nil,
        version: String? = nil,
        isInstalled: Bool
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.bundleURL = bundleURL
        self.version = version
        self.isInstalled = isInstalled
    }
}
