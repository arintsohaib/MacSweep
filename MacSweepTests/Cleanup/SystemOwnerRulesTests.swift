import Foundation
import Testing

@testable import MacSweep

@Suite("SystemOwnerRules")
struct SystemOwnerRulesTests {
    @Test("Apple and core-OS bundle identifiers are system owned")
    func appleIdentifiers() {
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "com.apple.TCC"))
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "com.apple.finder"))
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "com.apple.Safari.WebApp"))
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "group.com.apple.shared"))
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "com.apple"))
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "org.cups.PrintingPrefs"))
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "com.openssh.sshd"))
    }

    @Test("MacSweep's own identifiers are protected")
    func selfIdentifiers() {
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "com.macsweep.MacSweep"))
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "com.macsweep.something"))
    }

    @Test("third-party identifiers are not system owned")
    func thirdParty() {
        #expect(!SystemOwnerRules.isSystemOwned(bundleID: "com.vendor.Gone"))
        #expect(!SystemOwnerRules.isSystemOwned(bundleID: "org.example.tool"))
        #expect(!SystemOwnerRules.isSystemOwned(bundleID: "net.something.app"))
    }

    @Test("application identity check follows the bundle identifier")
    func identity() {
        let apple = ApplicationIdentity(
            bundleIdentifier: BundleIdentifier(rawValue: "com.apple.finder"),
            name: "Finder",
            isInstalled: true
        )
        let thirdParty = ApplicationIdentity(
            bundleIdentifier: BundleIdentifier(rawValue: "com.vendor.Gone"),
            name: "Gone",
            isInstalled: false
        )
        #expect(SystemOwnerRules.isProtectedOwner(apple))
        #expect(!SystemOwnerRules.isProtectedOwner(thirdParty))
        #expect(!SystemOwnerRules.isProtectedOwner(nil))
    }
}
