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

    @Test("group and team prefixes are normalized before classifying ownership")
    func normalization() {
        #expect(SystemOwnerRules.normalizedOwner("group.com.vendor.App") == "com.vendor.app")
        #expect(SystemOwnerRules.normalizedOwner("UBF8T346G9.com.microsoft.teams") == "com.microsoft.teams")
        #expect(SystemOwnerRules.normalizedOwner("243LU875E5.groups.com.apple.podcasts") == "com.apple.podcasts")
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "243LU875E5.groups.com.apple.podcasts"))
        #expect(SystemOwnerRules.isSystemOwned(bundleID: "group.com.apple.shared"))
        #expect(!SystemOwnerRules.isSystemOwned(bundleID: "6N38VWS5BX.ru.keepcoder.Telegram"))
    }

    @Test("installed ownership covers extensions and prefixed group identifiers")
    func installedOwnership() {
        let installed: Set<String> = ["com.vendor.active", "net.whatsapp.whatsapp", "ru.keepcoder.telegram"]
        #expect(SystemOwnerRules.isOwnedByInstalled("com.vendor.Active", installed: installed))
        #expect(SystemOwnerRules.isOwnedByInstalled("com.vendor.Active.Intents", installed: installed))
        #expect(SystemOwnerRules.isOwnedByInstalled("UBF8T346G9.com.vendor.Active", installed: installed))
        #expect(SystemOwnerRules.isOwnedByInstalled("group.net.whatsapp.WhatsApp.shared", installed: installed))
        #expect(SystemOwnerRules.isOwnedByInstalled("6N38VWS5BX.ru.keepcoder.Telegram", installed: installed))
        #expect(!SystemOwnerRules.isOwnedByInstalled("com.other.App", installed: installed))
        // Must not match on a partial segment.
        #expect(!SystemOwnerRules.isOwnedByInstalled("com.vendor.ActiveExtra", installed: installed))
    }

    @Test("file names map to bundle identifiers and system ownership")
    func pathNames() {
        #expect(SystemOwnerRules.bundleIDCandidate(fromFileName: "com.apple.dock.plist") == "com.apple.dock")
        #expect(SystemOwnerRules.bundleIDCandidate(fromFileName: "com.apple.dock.savedState") == "com.apple.dock")
        #expect(SystemOwnerRules.bundleIDCandidate(fromFileName: "com.apple.Safari.binarycookies") == "com.apple.Safari")
        #expect(SystemOwnerRules.isSystemOwnedPath(URL(fileURLWithPath: "/Users/u/Library/Caches/com.apple.dock")))
        #expect(SystemOwnerRules.isSystemOwnedPath(URL(fileURLWithPath: "/Users/u/Library/Preferences/com.apple.dock.plist")))
        #expect(!SystemOwnerRules.isSystemOwnedPath(URL(fileURLWithPath: "/Users/u/Library/Caches/com.vendor.App")))
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
