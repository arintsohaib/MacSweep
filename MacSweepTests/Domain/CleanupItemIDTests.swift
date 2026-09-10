import Foundation
import Testing

@testable import MacSweep

@Suite("CleanupItemID")
struct CleanupItemIDTests {
    @Test("id is stable for identical components")
    func stableForIdenticalComponents() {
        let a = CleanupItemID(stableComponents: ["uninstalledAppRemnants", "bundle:com.example.gone", "/Users/u/Library/Containers/com.example.gone"])
        let b = CleanupItemID(stableComponents: ["uninstalledAppRemnants", "bundle:com.example.gone", "/Users/u/Library/Containers/com.example.gone"])
        #expect(a == b)
    }

    @Test("id differs when inputs differ")
    func differsForDifferentInputs() {
        let a = CleanupItemID(stableComponents: ["logs", "/Users/u/Library/Logs/app.log"])
        let b = CleanupItemID(stableComponents: ["logs", "/Users/u/Library/Logs/other.log"])
        #expect(a != b)
    }

    @Test("raw value round-trips through validation")
    func rawRoundTrip() {
        let id = CleanupItemID(stableComponents: ["x"])
        #expect(CleanupItemID(rawValue: id.rawValue) == id)
    }

    @Test("invalid raw values are rejected")
    func invalidRaw() {
        #expect(CleanupItemID(rawValue: "ms_") == nil)
        #expect(CleanupItemID(rawValue: "ms_ZZZZ") == nil)
        #expect(CleanupItemID(rawValue: "xx_0123456789abcdef0123456789abcdef") == nil)
        #expect(CleanupItemID(rawValue: "ms_0123456789abcdef0123456789abcde") == nil)
    }
}
