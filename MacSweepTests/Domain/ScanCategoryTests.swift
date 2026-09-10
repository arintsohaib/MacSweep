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
}
