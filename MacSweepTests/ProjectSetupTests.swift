import Foundation
import Testing

@Suite("Phase 0 — Project setup")
struct ProjectSetupTests {
    @Test("test host is the MacSweep app bundle")
    func testHostIsMacSweepApp() {
        #expect(Bundle.main.bundleIdentifier == "com.macsweep.MacSweep")
    }

    @Test("test bundle is loaded with its own identity")
    func testBundleIdentity() {
        let identifiers = Bundle.allBundles.compactMap { $0.bundleIdentifier }
        #expect(identifiers.contains("com.macsweep.MacSweepTests"))
    }
}
