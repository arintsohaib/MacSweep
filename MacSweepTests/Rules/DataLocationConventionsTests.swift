import Foundation
import Testing

@testable import MacSweep

@Suite("DataLocationConventions")
struct DataLocationConventionsTests {
    private let library = URL(fileURLWithPath: "/Users/u/Library")
    private let id = BundleIdentifier(rawValue: "com.example.Gone")!

    @Test("conventional locations resolve to standard paths")
    func locations() {
        #expect(DataLocationConventions.url(location: .applicationSupport, libraryDirectory: library, bundleID: id, folderName: "Gone").path == "/Users/u/Library/Application Support/Gone")
        #expect(DataLocationConventions.url(location: .caches, libraryDirectory: library, bundleID: id, folderName: "Gone").path == "/Users/u/Library/Caches/Gone")
        #expect(DataLocationConventions.url(location: .container, libraryDirectory: library, bundleID: id, folderName: "Gone").path == "/Users/u/Library/Containers/com.example.Gone")
        #expect(DataLocationConventions.url(location: .groupContainer, libraryDirectory: library, bundleID: id, folderName: "Gone").path == "/Users/u/Library/Group Containers/com.example.Gone")
        #expect(DataLocationConventions.url(location: .preferences, libraryDirectory: library, bundleID: id, folderName: "Gone").path == "/Users/u/Library/Preferences/com.example.Gone.plist")
        #expect(DataLocationConventions.url(location: .webKit, libraryDirectory: library, bundleID: id, folderName: "Gone").path == "/Users/u/Library/WebKit/com.example.Gone")
        #expect(DataLocationConventions.url(location: .httpStorages, libraryDirectory: library, bundleID: id, folderName: "Gone").path == "/Users/u/Library/HTTPStorages/com.example.Gone")
        #expect(DataLocationConventions.url(location: .savedState, libraryDirectory: library, bundleID: id, folderName: "Gone").path == "/Users/u/Library/Saved Application State/com.example.Gone.savedState")
        #expect(DataLocationConventions.url(location: .logs, libraryDirectory: library, bundleID: id, folderName: "Gone").path == "/Users/u/Library/Logs/Gone")
        #expect(DataLocationConventions.url(location: .launchAgents, libraryDirectory: library, bundleID: id, folderName: "Gone").path == "/Users/u/Library/LaunchAgents/com.example.Gone.plist")
    }

    @Test("every location has a display name")
    func displayNames() {
        for location in DataLocation.allCases {
            #expect(!location.displayName.isEmpty)
        }
    }
}
