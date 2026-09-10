import Testing

@testable import MacSweep

@Suite("RiskLevel")
struct RiskLevelTests {
    @Test("default selection follows risk")
    func defaultSelection() {
        #expect(RiskLevel.low.defaultSelected)
        #expect(!RiskLevel.review.defaultSelected)
        #expect(!RiskLevel.protected.defaultSelected)
    }

    @Test("protected cannot be cleaned")
    func cleanup() {
        #expect(RiskLevel.low.cleanupAllowed)
        #expect(RiskLevel.review.cleanupAllowed)
        #expect(!RiskLevel.protected.cleanupAllowed)
    }
}
