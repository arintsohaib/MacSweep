import Testing

@testable import MacSweep

@Suite("ScanCategory")
struct ScanCategoryTests {
    @Test("every category has a display name")
    func displayNames() {
        for category in ScanCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    @Test("ordering is stable")
    func ordering() {
        let sorted = ScanCategory.allCases.sorted()
        #expect(sorted == ScanCategory.allCases)
    }

    @Test("every category documents what it scans and its cleanup risk")
    func settingsDescriptions() {
        for category in ScanCategory.allCases {
            #expect(!category.settingsSummary.isEmpty, "\(category) has no summary")
            #expect(!category.settingsCleanupNote.isEmpty, "\(category) has no cleanup note")
        }
    }

    @Test("informational categories are never cleanable")
    func informationalRisk() {
        let informational: Set<ScanCategory> = [.uninstalledAppRemnants, .largeFiles, .reviewOnly]
        for category in ScanCategory.allCases {
            if informational.contains(category) {
                #expect(category.cleanupRisk == .informational, "\(category) should be informational")
            } else {
                #expect(category.cleanupRisk == .review, "\(category) should be review")
            }
        }
    }
}
