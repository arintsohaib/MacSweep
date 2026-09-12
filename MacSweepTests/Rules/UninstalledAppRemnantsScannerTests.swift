import Foundation
import Testing

@testable import MacSweep

@Suite("UninstalledAppRemnantsScanner")
struct UninstalledAppRemnantsScannerTests {
    private let home = "/Users/u"

    private func makeContext(
        fileSystem: InMemoryFileSystem,
        registry: MockApplicationRegistry,
        exclusions: PathExclusions = PathExclusions(paths: [])
    ) -> ScanContext {
        ScanContext(
            operationID: UUID(),
            fileSystem: fileSystem,
            applications: registry,
            exclusions: exclusions,
            progress: CollectingProgressReporter(),
            diagnostics: DiagnosticCollector(),
            homeDirectory: URL(fileURLWithPath: home)
        )
    }

    private func installedRegistry() -> MockApplicationRegistry {
        MockApplicationRegistry(apps: [
            ApplicationIdentity(bundleIdentifier: BundleIdentifier(rawValue: "com.vendor.Active")!, name: "Active", isInstalled: true),
            ApplicationIdentity(bundleIdentifier: BundleIdentifier(rawValue: "com.vendor.Other")!, name: "Other", isInstalled: true),
        ])
    }

    private func addGoneAppData(_ fileSystem: InMemoryFileSystem) {
        let container = "\(home)/Library/Containers/com.vendor.Gone"
        fileSystem.addDirectory(container)
        fileSystem.addFile("\(container)/Data/a.bin", size: 1024)
        fileSystem.addDirectory("\(home)/Library/Application Support/com.vendor.Gone")
        fileSystem.addFile("\(home)/Library/Application Support/com.vendor.Gone/b.bin", size: 2048)
        fileSystem.addDirectory("\(home)/Library/Caches/com.vendor.Gone")
        fileSystem.addFile("\(home)/Library/Caches/com.vendor.Gone/c.bin", size: 4096)
    }

    @Test("abandoned app data is detected as one review-only, non-cleanable finding")
    func abandonedAppData() async throws {
        let fileSystem = InMemoryFileSystem()
        addGoneAppData(fileSystem)
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.risk == .review)
        #expect(!item.selectedByDefault)
        #expect(!item.cleanupAllowed)
        #expect(item.recommendedAction == .reviewOnly)
        #expect(item.application?.bundleIdentifier?.rawValue == "com.vendor.Gone")
        #expect(item.paths.map(\.url.path).sorted() == [
            "\(home)/Library/Application Support/com.vendor.Gone",
            "\(home)/Library/Containers/com.vendor.Gone",
        ])
        #expect(item.totalSize == 1024 + 2048)
        #expect(item.evidence.contains { $0.kind == .applicationAbsent })
        #expect(item.evidence.contains { $0.kind == .bundleIdentifierMatch })
        #expect(!item.reason.isEmpty)
    }

    @Test("active application data is never reported")
    func activeAppDataIsSkipped() async throws {
        let fileSystem = InMemoryFileSystem()
        fileSystem.addDirectory("\(home)/Library/Containers/com.vendor.Active")
        fileSystem.addFile("\(home)/Library/Containers/com.vendor.Active/x.bin", size: 10)
        fileSystem.addDirectory("\(home)/Library/Application Support/com.vendor.Active")
        fileSystem.addFile("\(home)/Library/Application Support/com.vendor.Active/y.bin", size: 10)
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)
        #expect(items.isEmpty)
    }

    @Test("extension containers of installed applications are not reported")
    func extensionContainersOfInstalledApps() async throws {
        let fileSystem = InMemoryFileSystem()
        for extensionID in ["com.vendor.Active.Intents", "com.vendor.Active.Widget", "com.vendor.Active.ShareExtension"] {
            fileSystem.addDirectory("\(home)/Library/Containers/\(extensionID)")
            fileSystem.addFile("\(home)/Library/Containers/\(extensionID)/x.bin", size: 10)
        }
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)
        #expect(items.isEmpty)
    }

    @Test("group containers are not scanned")
    func groupContainersAreNotReported() async throws {
        let fileSystem = InMemoryFileSystem()
        fileSystem.addDirectory("\(home)/Library/Group Containers/group.com.vendor.Gone")
        fileSystem.addFile("\(home)/Library/Group Containers/group.com.vendor.Gone/shared.bin", size: 100)
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)
        #expect(items.isEmpty)
    }

    @Test("launch agents are not scanned")
    func launchAgentsAreNotReported() async throws {
        let fileSystem = InMemoryFileSystem()
        fileSystem.addFile("\(home)/Library/LaunchAgents/com.vendor.Gone.plist", size: 5)
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)
        #expect(items.isEmpty)
    }

    @Test("preferences, caches, logs, web storage and saved state are not scanned")
    func otherLocationsAreNotScanned() async throws {
        let fileSystem = InMemoryFileSystem()
        fileSystem.addFile("\(home)/Library/Preferences/com.vendor.Gone.plist", size: 10)
        fileSystem.addDirectory("\(home)/Library/Caches/com.vendor.Gone")
        fileSystem.addDirectory("\(home)/Library/Logs/com.vendor.Gone")
        fileSystem.addDirectory("\(home)/Library/WebKit/com.vendor.Gone")
        fileSystem.addDirectory("\(home)/Library/HTTPStorages/com.vendor.Gone")
        fileSystem.addFile("\(home)/Library/HTTPStorages/com.vendor.Gone.binarycookies", size: 10)
        fileSystem.addDirectory("\(home)/Library/Saved Application State/com.vendor.Gone.savedState")
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)
        #expect(items.isEmpty)
    }

    @Test("Apple system components and MacSweep itself are never reported as leftovers")
    func appleSystemRemnantsAreNeverReported() async throws {
        let fileSystem = InMemoryFileSystem()
        for name in ["com.apple.TCC", "com.apple.sharedfilelist", "com.apple.containermanagerd", "com.apple.AddressBook"] {
            fileSystem.addDirectory("\(home)/Library/Containers/\(name)")
            fileSystem.addFile("\(home)/Library/Containers/\(name)/x.bin", size: 100)
            fileSystem.addDirectory("\(home)/Library/Application Support/\(name)")
            fileSystem.addFile("\(home)/Library/Application Support/\(name)/y.bin", size: 100)
        }
        fileSystem.addDirectory("\(home)/Library/Containers/\(SystemOwnerRules.selfBundlePrefix)helper")
        fileSystem.addDirectory("\(home)/Library/Containers/com.apple.finder")
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)
        #expect(items.isEmpty)
    }

    @Test("name-based folders with no matching app are not reported")
    func unattributedFolderIsNotReported() async throws {
        let fileSystem = InMemoryFileSystem()
        fileSystem.addDirectory("\(home)/Library/Application Support/MysteryApp")
        fileSystem.addFile("\(home)/Library/Application Support/MysteryApp/data.bin", size: 10)
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)
        #expect(items.isEmpty)
    }

    @Test("an unattributed folder containing protected data is never reported")
    func unattributedFolderContainingProtectedDataIsNotReported() async throws {
        let fileSystem = InMemoryFileSystem()
        fileSystem.addDirectory("\(home)/Library/Application Support/Google")
        fileSystem.addDirectory("\(home)/Library/Application Support/Google/Chrome")
        fileSystem.addFile("\(home)/Library/Application Support/Google/Chrome/profile.bin", size: 2048)
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)
        #expect(items.isEmpty)
    }

    @Test("container and application support locations merge into one finding")
    func locationsMerged() async throws {
        let fileSystem = InMemoryFileSystem()
        fileSystem.addDirectory("\(home)/Library/Containers/com.vendor.Gone")
        fileSystem.addFile("\(home)/Library/Containers/com.vendor.Gone/c.bin", size: 100)
        fileSystem.addDirectory("\(home)/Library/Application Support/com.vendor.Gone")
        fileSystem.addFile("\(home)/Library/Application Support/com.vendor.Gone/s.bin", size: 200)
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.paths.count == 2)
        #expect(item.totalSize == 300)
        #expect(!item.cleanupAllowed)
    }

    @Test("excluded paths are not reported")
    func exclusions() async throws {
        let fileSystem = InMemoryFileSystem()
        addGoneAppData(fileSystem)
        let exclusions = PathExclusions(paths: [URL(fileURLWithPath: "\(home)/Library/Containers/com.vendor.Gone")])
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry(), exclusions: exclusions)
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.paths.map(\.url.path) == ["\(home)/Library/Application Support/com.vendor.Gone"])
    }

    @Test("permission failures produce diagnostics and do not stop the scan")
    func permissionFailure() async throws {
        let fileSystem = InMemoryFileSystem()
        addGoneAppData(fileSystem)
        fileSystem.markInaccessible("\(home)/Library/Containers")
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.paths.map(\.url.path) == ["\(home)/Library/Application Support/com.vendor.Gone"])
        #expect(context.diagnostics.all.contains { $0.category == .permissionDenied })
    }

    @Test("paths that disappear during the scan are skipped safely")
    func disappearingPath() async throws {
        let fileSystem = InMemoryFileSystem()
        addGoneAppData(fileSystem)
        fileSystem.remove("\(home)/Library/Containers/com.vendor.Gone")
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)
        #expect(items.count == 1)
        #expect(try #require(items.first).paths.count == 1)
    }

    @Test("containers without a valid bundle id are not reported")
    func invalidContainerName() async throws {
        let fileSystem = InMemoryFileSystem()
        fileSystem.addDirectory("\(home)/Library/Containers/not a valid id")
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)
        #expect(items.isEmpty)
    }

    @Test("symlinked data is measured as zero and still reported as review-only")
    func symlinkedData() async throws {
        let fileSystem = InMemoryFileSystem()
        fileSystem.addDirectory("/outside")
        fileSystem.addFile("/outside/big.bin", size: 999999)
        fileSystem.addSymbolicLink("\(home)/Library/Containers/com.vendor.Gone", target: "/outside")
        let context = makeContext(fileSystem: fileSystem, registry: installedRegistry())
        let items = try await UninstalledAppRemnantsScanner().scan(context: context)

        #expect(items.count == 1)
        let item = try #require(items.first)
        #expect(item.paths.first?.isSymbolicLink == true)
        #expect(item.totalSize == 0)
        #expect(!item.cleanupAllowed)
    }
}
