import Foundation
import Testing

@testable import MacSweep

@Suite("SystemApplicationRegistry")
struct SystemApplicationRegistryTests {
    private func makeFixtureApp(directory: URL, name: String, bundleID: String, version: String) throws -> URL {
        let app = directory.appendingPathComponent("\(name).app")
        let contents = app.appendingPathComponent("Contents")
        let macos = contents.appendingPathComponent("MacOS")
        try FileManager.default.createDirectory(at: macos, withIntermediateDirectories: true)
        let info: [String: Any] = [
            "CFBundleIdentifier": bundleID,
            "CFBundleName": name,
            "CFBundleShortVersionString": version,
        ]
        try (info as NSDictionary).write(to: contents.appendingPathComponent("Info.plist"))
        try Data().write(to: macos.appendingPathComponent(name))
        return app
    }

    @Test("discovers fixture apps with bundle identity")
    func discoversFixtureApps() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacSweepRegistryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try makeFixtureApp(directory: directory, name: "FakeApp", bundleID: "com.macsweep.test.fakeapp", version: "1.2.3")
        _ = try makeFixtureApp(directory: directory, name: "OtherApp", bundleID: "com.macsweep.test.otherapp", version: "0.1")

        let registry = SystemApplicationRegistry(searchPaths: [directory])
        let apps = try registry.installedApplications()
        #expect(apps.count == 2)

        let fake = try registry.installedApplication(withBundleIdentifier: BundleIdentifier(rawValue: "com.macsweep.test.fakeapp")!)
        #expect(fake != nil)
        #expect(fake?.name == "FakeApp")
        #expect(fake?.version == "1.2.3")
        #expect(fake?.bundleURL?.lastPathComponent == "FakeApp.app")
        #expect(fake?.isInstalled == true)
    }

    @Test("unknown bundle identifiers resolve to nil")
    func unknownIdentifier() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacSweepRegistryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let registry = SystemApplicationRegistry(searchPaths: [directory])
        let missing = BundleIdentifier(rawValue: "com.macsweep.test.does-not-exist-\(UUID().uuidString.lowercased())")!
        #expect(try registry.installedApplication(withBundleIdentifier: missing) == nil)
    }

    @Test("duplicate bundle ids are reported once")
    func duplicatesReportedOnce() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacSweepRegistryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try makeFixtureApp(directory: directory, name: "DupApp", bundleID: "com.macsweep.test.dup", version: "1")
        _ = try makeFixtureApp(directory: directory, name: "DupCopy", bundleID: "com.macsweep.test.dup", version: "2")

        let registry = SystemApplicationRegistry(searchPaths: [directory])
        let apps = try registry.installedApplications()
        #expect(apps.filter { $0.bundleIdentifier?.rawValue == "com.macsweep.test.dup" }.count == 1)
    }
}
