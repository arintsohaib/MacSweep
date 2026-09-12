import Foundation

/// Static, user-facing information about the app, its maker and public links.
enum AppInfo {
    static let name = "MacSweep"
    static let tagline = "Safe, deterministic storage cleanup for macOS."

    static let developer = "GrayHawk Sentinel"
    static let websiteURL = URL(string: "https://grayhawks.com")!
    static let emailAddress = "info@grayhawks.com"
    static let emailURL = URL(string: "mailto:info@grayhawks.com")!
    static let githubURL = URL(string: "https://github.com/arintsohaib/MacSweep")!
    static let issuesURL = URL(string: "https://github.com/arintsohaib/MacSweep/issues")!
    static let helpURL = URL(string: "https://github.com/arintsohaib/MacSweep#readme")!
    static let licenseURL = URL(string: "https://github.com/arintsohaib/MacSweep/blob/main/LICENSE")!

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    static var versionDescription: String {
        "Version \(version) (\(build))"
    }
}
