import Foundation
import Testing

@testable import MacSweep

@Suite("AppInfo")
struct AppInfoTests {
    @Test("public links and identity are well formed")
    func publicInfo() {
        #expect(!AppInfo.name.isEmpty)
        #expect(!AppInfo.developer.isEmpty)
        #expect(AppInfo.websiteURL.scheme == "https")
        #expect(AppInfo.websiteURL.host?.contains("grayhawks.com") == true)
        #expect(AppInfo.emailURL.scheme == "mailto")
        #expect(AppInfo.emailAddress.contains("@"))
        #expect(AppInfo.githubURL.absoluteString.contains("github.com"))
        #expect(AppInfo.issuesURL.absoluteString.hasSuffix("/issues"))
    }
}
