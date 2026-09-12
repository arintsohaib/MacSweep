import Testing

@testable import MacSweep

@Suite("CleanupMode")
struct CleanupModeTests {
    @Test("basic scans a safe subset and pre-selects only regenerable categories")
    func basic() {
        #expect(CleanupMode.basic.scanCategories == [.applicationCaches, .logs, .uninstalledAppRemnants, .largeFiles])
        #expect(CleanupMode.basic.autoSelectCategories == [.applicationCaches, .logs])
        #expect(!CleanupMode.basic.scanCategories.contains(.developerCaches))
        #expect(!CleanupMode.basic.scanCategories.contains(.webStorage))
        #expect(!CleanupMode.basic.scanCategories.contains(.savedState))
    }

    @Test("advanced scans everything and pre-selects nothing")
    func advanced() {
        #expect(CleanupMode.advanced.scanCategories == Set(ScanCategory.allCases))
        #expect(CleanupMode.advanced.autoSelectCategories.isEmpty)
    }

    @Test("default settings use the basic profile, not every category")
    func defaultSettings() {
        #expect(UserSettings.default.enabledCategories == CleanupMode.basic.scanCategories)
        #expect(!UserSettings.default.enabledCategories.contains(.developerCaches))
        #expect(!UserSettings.default.enabledCategories.contains(.webStorage))
    }
}
