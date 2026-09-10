import Foundation

public final class MockApplicationRegistry: ApplicationRegistry, @unchecked Sendable {
    private let lock = NSLock()
    private var apps: [ApplicationIdentity]

    public init(apps: [ApplicationIdentity] = []) {
        self.apps = apps
    }

    public func setInstalled(_ apps: [ApplicationIdentity]) {
        lock.lock()
        defer { lock.unlock() }
        self.apps = apps
    }

    public func installedApplications() throws -> [ApplicationIdentity] {
        lock.lock()
        defer { lock.unlock() }
        return apps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func installedApplication(withBundleIdentifier identifier: BundleIdentifier) throws -> ApplicationIdentity? {
        try installedApplications().first { $0.bundleIdentifier == identifier }
    }
}
