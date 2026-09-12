import Foundation
import Testing

@testable import MacSweep

@Suite("RealScanInvariants")
struct RealScanInvariantsTests {
    // A full scan of the real filesystem is slow, so this test is opt-in.
    // Opt in by creating the marker file, e.g.:
    //   touch /tmp/macsweep-real-scan-test
    private static let markerPath = "/tmp/macsweep-real-scan-test"
    private static var optInEnabled: Bool {
        FileManager.default.fileExists(atPath: markerPath)
    }

    @Test("a scan of the real filesystem stays consistent and safe",
          .enabled(if: Self.optInEnabled),
          .timeLimit(.minutes(20)))
    func realScanStaysConsistentAndSafe() async throws {
        let fileSystem = RealFileSystem()
        let registry = SystemApplicationRegistry()
        let home = FileManager.default.homeDirectoryForCurrentUser
        let engine = ScanEngine(scanners: ScanEngine.defaultScanners)

        let result = await engine.scan(
            fileSystem: fileSystem,
            applications: registry,
            exclusions: PathExclusions(paths: []),
            configuration: ScanConfiguration(),
            progress: CollectingProgressReporter(),
            homeDirectory: home
        )

        let items = result.items

        // No two findings may share or nest paths, so totals never double-count.
        for index in items.indices {
            for other in items.index(after: index)..<items.endIndex {
                #expect(!ScanEngine.pathSetsIntersect(items[index], items[other]),
                        "Overlapping findings: \(items[index].title) and \(items[other].title)")
            }
        }

        // Anything offered for cleanup must not touch — or contain — protected locations.
        let rules = ProtectedPathRules(homeDirectory: home)
        for item in items where item.cleanupAllowed {
            for path in item.paths {
                #expect(!rules.isProtectedOrContainsProtected(path.url),
                        "\(item.title) offers cleanup on or above protected path \(path.url.path)")
            }
        }

        // No system-owned (Apple/MacSweep) finding may ever be reported, and
        // preferences must never appear as a finding.
        for item in items {
            if let bundleID = item.application?.bundleIdentifier {
                #expect(!SystemOwnerRules.isSystemOwned(bundleID),
                        "System-owned finding reported: \(bundleID.rawValue)")
            }
            for path in item.paths {
                #expect(!path.url.path.contains("/Library/Preferences/"),
                        "Preference path reported: \(path.url.path)")
            }
        }

        // The reclaimable total must equal the sum of the cleanable items.
        let expected = items.filter(\.cleanupAllowed).reduce(Int64(0)) { $0 + $1.totalSize }
        #expect(result.reclaimableSize == expected)
        #expect(result.reclaimableSize >= 0)

        // Every cleanable finding offers exactly the trash action.
        for item in items where item.cleanupAllowed {
            #expect(item.recommendedAction == .moveToTrash)
        }

        // Review-only findings are never selected by default and never cleanable.
        for item in items where item.recommendedAction == .reviewOnly {
            #expect(!item.cleanupAllowed)
            #expect(!item.selectedByDefault)
        }

        print("[RealScan] findings=\(items.count) cleanable=\(items.filter(\.cleanupAllowed).count) reclaimable=\(result.reclaimableSize) diagnostics=\(result.diagnostics.count)")
    }
}
