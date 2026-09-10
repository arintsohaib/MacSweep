import Foundation
import Testing

@testable import MacSweep

@Suite("BundleIdentifier")
struct BundleIdentifierTests {
    @Test("valid identifiers are accepted")
    func valid() throws {
        #expect(try BundleIdentifier(validating: "com.apple.Safari") != nil)
        #expect(BundleIdentifier(rawValue: "org.example.app-1") != nil)
        #expect(BundleIdentifier(rawValue: "a.b") != nil)
    }

    @Test("invalid identifiers are rejected")
    func invalid() {
        #expect(BundleIdentifier(rawValue: "") == nil)
        #expect(BundleIdentifier(rawValue: ".leading") == nil)
        #expect(BundleIdentifier(rawValue: "trailing.") == nil)
        #expect(BundleIdentifier(rawValue: "a..b") == nil)
        #expect(BundleIdentifier(rawValue: "a b.c") == nil)
        #expect(BundleIdentifier(rawValue: "single") == nil)
        #expect(BundleIdentifier(rawValue: "-bad.example") == nil)
        #expect(BundleIdentifier(rawValue: "bad-.example") == nil)
        #expect(BundleIdentifier(rawValue: String(repeating: "a", count: 256)) == nil)
    }

    @Test("equality is case-insensitive")
    func caseInsensitive() throws {
        let a = try BundleIdentifier(validating: "com.Example.App")
        let b = try BundleIdentifier(validating: "com.example.app")
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }
}
