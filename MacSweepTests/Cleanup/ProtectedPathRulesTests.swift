import Foundation
import Testing

@testable import MacSweep

@Suite("ProtectedPathRules")
struct ProtectedPathRulesTests {
    private let home = URL(fileURLWithPath: "/Users/u")

    @Test("system roots and files are protected")
    func systemRoots() {
        let rules = ProtectedPathRules(homeDirectory: home)
        #expect(rules.isProtected(URL(fileURLWithPath: "/")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/System")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/System/Library/CoreServices")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/usr/bin/swift")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/bin/zsh")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/sbin/launchd")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/etc/hosts")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Applications/Safari.app")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Library/Preferences")))
    }

    @Test("user home root itself is protected")
    func homeRoot() {
        let rules = ProtectedPathRules(homeDirectory: home)
        #expect(rules.isProtected(home))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/")))
    }

    @Test("sensitive user documents and credentials are protected")
    func sensitiveUserLocations() {
        let rules = ProtectedPathRules(homeDirectory: home)
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/Documents")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/Documents/Tax2025.pdf")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/Desktop")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/Desktop/secret.txt")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/.ssh/id_ed25519")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/.gnupg/secring.gpg")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/.aws/credentials")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/Library/Keychains/login.keychain-db")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/Library/Mail")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/Library/Messages")))
        #expect(rules.isProtected(URL(fileURLWithPath: "/Users/u/Library/Safari")))
    }

    @Test("reclaimable application data locations are not protected")
    func reclaimableLocationsNotProtected() {
        let rules = ProtectedPathRules(homeDirectory: home)
        #expect(!rules.isProtected(URL(fileURLWithPath: "/Users/u/Library/Containers/com.vendor.App")))
        #expect(!rules.isProtected(URL(fileURLWithPath: "/Users/u/Library/Caches/com.vendor.App")))
        #expect(!rules.isProtected(URL(fileURLWithPath: "/Users/u/Library/Application Support/com.vendor.App")))
        #expect(!rules.isProtected(URL(fileURLWithPath: "/Users/u/Library/Logs/com.vendor.App")))
        #expect(!rules.isProtected(URL(fileURLWithPath: "/Users/u/Library/WebKit/com.vendor.App")))
        #expect(!rules.isProtected(URL(fileURLWithPath: "/Users/u/Library/Saved Application State/com.vendor.App.savedState")))
    }

    @Test("ancestors of protected locations cannot be cleaned because they would remove protected content")
    func ancestorsOfProtectedLocations() {
        let rules = ProtectedPathRules(homeDirectory: home)
        #expect(rules.isProtectedOrContainsProtected(URL(fileURLWithPath: "/Users/u/Library/Application Support/Google")))
        #expect(rules.isProtectedOrContainsProtected(URL(fileURLWithPath: "/Users/u/Library/Application Support/Google/Chrome")))
        #expect(rules.isProtectedOrContainsProtected(URL(fileURLWithPath: "/Users/u/Library/Application Support/Google/Chrome/Profile 1")))
        // Unrelated and sibling locations remain cleanable.
        #expect(!rules.isProtectedOrContainsProtected(URL(fileURLWithPath: "/Users/u/Library/Application Support/com.vendor.App")))
        #expect(!rules.isProtectedOrContainsProtected(URL(fileURLWithPath: "/Users/u/Library/Caches/com.vendor.App")))
        #expect(!rules.isProtectedOrContainsProtected(URL(fileURLWithPath: "/Users/u/Library/Containers/com.vendor.App")))
    }
}
