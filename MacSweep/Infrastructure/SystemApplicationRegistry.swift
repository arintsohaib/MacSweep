import AppKit
import Foundation

public final class SystemApplicationRegistry: ApplicationRegistry, @unchecked Sendable {
    public static let defaultSearchPaths: [URL] = [
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        URL(fileURLWithPath: "/Applications/Utilities", isDirectory: true),
        URL(fileURLWithPath: "/System/Applications", isDirectory: true),
        URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true),
        URL(fileURLWithPath: "/System/Library/CoreServices", isDirectory: true),
        URL(fileURLWithPath: "/System/Library/CoreServices/Applications", isDirectory: true),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
    ]

    private let lock = NSLock()
    private let searchPaths: [URL]
    private let workspace: NSWorkspace
    private var cached: [ApplicationIdentity]?

    public init(searchPaths: [URL] = SystemApplicationRegistry.defaultSearchPaths, workspace: NSWorkspace = .shared) {
        self.searchPaths = searchPaths
        self.workspace = workspace
    }

    public func installedApplications() throws -> [ApplicationIdentity] {
        lock.lock()
        defer { lock.unlock() }
        if let cached {
            return cached
        }
        let apps = scan()
        cached = apps
        return apps
    }

    public func installedApplication(withBundleIdentifier identifier: BundleIdentifier) throws -> ApplicationIdentity? {
        if let match = try installedApplications().first(where: { $0.bundleIdentifier == identifier }) {
            return match
        }
        if let url = workspace.urlForApplication(withBundleIdentifier: identifier.rawValue) {
            return Self.readIdentity(at: url)
        }
        return nil
    }

    private func scan() -> [ApplicationIdentity] {
        var seen = Set<String>()
        var apps: [ApplicationIdentity] = []
        for path in searchPaths {
            let contents: [URL]
            do {
                contents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            } catch {
                continue
            }
            for bundle in contents where bundle.pathExtension == "app" {
                guard let identity = Self.readIdentity(at: bundle) else { continue }
                let key = identity.bundleIdentifier?.normalized ?? "name:" + identity.name.lowercased()
                if seen.insert(key).inserted {
                    apps.append(identity)
                }
            }
        }
        return apps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func readIdentity(at bundleURL: URL) -> ApplicationIdentity? {
        guard let bundle = Bundle(url: bundleURL), let info = bundle.infoDictionary else { return nil }
        let identifier = (info["CFBundleIdentifier"] as? String).flatMap(BundleIdentifier.init(rawValue:))
        let name = (info["CFBundleDisplayName"] as? String)
            ?? (info["CFBundleName"] as? String)
            ?? bundleURL.deletingPathExtension().lastPathComponent
        let version = info["CFBundleShortVersionString"] as? String
        return ApplicationIdentity(bundleIdentifier: identifier, name: name, bundleURL: bundleURL, version: version, isInstalled: true)
    }
}
