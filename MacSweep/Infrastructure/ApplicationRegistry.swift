import Foundation

public protocol ApplicationRegistry: Sendable {
    func installedApplications() throws -> [ApplicationIdentity]
    func installedApplication(withBundleIdentifier identifier: BundleIdentifier) throws -> ApplicationIdentity?
}
