import Foundation
import Testing

@testable import MacSweep

@Suite("BundleIDMapping")
struct BundleIDMappingTests {
    @Test("folder names that are valid bundle identifiers parse")
    func parseFromFolderName() {
        #expect(BundleIDMapping.bundleID(fromFolderName: "com.apple.Safari") != nil)
        #expect(BundleIDMapping.bundleID(fromFolderName: "Safari") == nil)
        #expect(BundleIDMapping.bundleID(fromFolderName: "not a bundle id") == nil)
    }

    @Test("folder names match the full bundle id case-insensitively")
    func fullIDMatch() {
        let id = BundleIdentifier(rawValue: "com.example.MyApp")!
        #expect(BundleIDMapping.folderNameMatchesBundleID(name: "com.example.MyApp", bundleID: id))
        #expect(BundleIDMapping.folderNameMatchesBundleID(name: "COM.EXAMPLE.MYAPP", bundleID: id))
        #expect(!BundleIDMapping.folderNameMatchesBundleID(name: "com.example.myapp.extra", bundleID: id))
    }

    @Test("folder names match the last bundle id segment")
    func lastSegmentMatch() {
        let id = BundleIdentifier(rawValue: "com.example.MyApp")!
        #expect(BundleIDMapping.folderNameMatchesBundleID(name: "MyApp", bundleID: id))
        #expect(BundleIDMapping.folderNameMatchesBundleID(name: "myapp", bundleID: id))
        #expect(!BundleIDMapping.folderNameMatchesBundleID(name: "MyApp2", bundleID: id))
    }

    @Test("expected folder names cover id, segment, and display name")
    func expectedNames() {
        let id = BundleIdentifier(rawValue: "com.vendor.CloudDrive")!
        let names = BundleIDMapping.expectedFolderNames(bundleID: id, displayName: "Cloud Drive")
        #expect(names == ["com.vendor.CloudDrive", "CloudDrive", "Cloud Drive"])

        let deduped = BundleIDMapping.expectedFolderNames(bundleID: BundleIdentifier(rawValue: "com.app.App")!, displayName: "App")
        #expect(deduped == ["com.app.App", "App"])
    }
}
