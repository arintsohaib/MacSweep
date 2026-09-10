import Foundation
import Testing

@testable import MacSweep

@Suite("Performance")
struct PerformanceTests {
    private let home = URL(fileURLWithPath: "/Users/u")

    private func createSyntheticWorkstation(fileSystem fs: InMemoryFileSystem, appCount: Int) {
        for i in 1...appCount {
            let bundleID = "com.developer.app\(i)"
            let container = "/Users/u/Library/Containers/\(bundleID)"
            fs.addDirectory(container)
            for fileIdx in 1...10 {
                fs.addFile("\(container)/file_\(fileIdx).dat", size: 10_000)
            }

            let cache = "/Users/u/Library/Caches/\(bundleID)"
            fs.addDirectory(cache)
            for fileIdx in 1...5 {
                fs.addFile("\(cache)/cache_\(fileIdx).bin", size: 50_000)
            }

            let log = "/Users/u/Library/Logs/\(bundleID)"
            fs.addDirectory(log)
            fs.addFile("\(log)/app.log", size: 5_000)

            fs.addFile("/Users/u/Library/Preferences/\(bundleID).plist", size: 500)
        }

        // Add developer directories
        let derivedData = "/Users/u/Library/Developer/Xcode/DerivedData"
        fs.addDirectory(derivedData)
        for i in 1...20 {
            fs.addFile("\(derivedData)/Project\(i)/build.db", size: 10_000_000)
        }

        // Add large files in downloads
        let downloads = "/Users/u/Downloads"
        fs.addDirectory(downloads)
        fs.addFile("\(downloads)/big_sdk.pkg", size: 1_000_000_000)
    }

    @Test("scan of synthetic workstation completes under benchmark threshold")
    func workstationScanDuration() async throws {
        let fs = InMemoryFileSystem()
        createSyntheticWorkstation(fileSystem: fs, appCount: 30) // ~500 nodes

        // Apps 1..15 are installed, apps 16..30 are uninstalled
        let installedApps = (1...15).map {
            ApplicationIdentity(
                bundleIdentifier: BundleIdentifier(rawValue: "com.developer.app\($0)"),
                name: "App\($0)",
                isInstalled: true
            )
        }
        let registry = MockApplicationRegistry(apps: installedApps)
        let engine = ScanEngine(scanners: ScanEngine.defaultScanners)

        let start = ContinuousClock.now
        let result = await engine.scan(
            fileSystem: fs,
            applications: registry,
            progress: CollectingProgressReporter(),
            homeDirectory: home
        )
        let elapsed = ContinuousClock.now - start

        #expect(!result.items.isEmpty)
        // Must complete in under 2 seconds (typically takes < 100ms)
        #expect(elapsed < .seconds(2))
    }

    @Test("cancellation is prompt during scanning")
    func cancellationLatency() async throws {
        let fs = InMemoryFileSystem()
        createSyntheticWorkstation(fileSystem: fs, appCount: 50)

        let engine = ScanEngine(scanners: ScanEngine.defaultScanners)
        let start = ContinuousClock.now

        let task = Task {
            await engine.scan(
                fileSystem: fs,
                applications: MockApplicationRegistry(),
                progress: CollectingProgressReporter(),
                homeDirectory: home
            )
        }
        task.cancel()
        let result = await task.value
        let elapsed = ContinuousClock.now - start

        #expect(result.isCancelled)
        #expect(elapsed < .seconds(1))
    }

    @Test("cleanup validation is fast for batch items")
    func cleanupValidationLatency() async throws {
        let fs = InMemoryFileSystem()
        var items: [CleanupItem] = []

        for i in 1...50 {
            let path = "/Users/u/Library/Containers/com.vendor.Batch\(i)"
            fs.addDirectory(path)
            fs.addFile("\(path)/data.bin", size: 1000)

            let snapshot = PathSnapshot(
                url: URL(fileURLWithPath: path),
                kind: .directory,
                size: 1000,
                modificationDate: nil
            )
            let item = try CleanupItem(
                category: .uninstalledAppRemnants,
                title: "Batch \(i)",
                reason: "reason",
                paths: [snapshot],
                risk: .low,
                confidence: .high,
                evidence: [Evidence(kind: .other, detail: "d")],
                recommendedAction: .moveToTrash,
                selectedByDefault: true,
                cleanupAllowed: true
            )
            items.append(item)
        }

        let trash = RecordingTrashService(simulatedFileSystem: fs)
        let engine = CleanupEngine(fileSystem: fs, trash: trash, homeDirectory: home)

        let start = ContinuousClock.now
        let report = await engine.cleanup(selectedItems: items)
        let elapsed = ContinuousClock.now - start

        #expect(report.isFullySucceeded)
        #expect(report.movedCount == 50)
        #expect(elapsed < .seconds(1))
    }
}
