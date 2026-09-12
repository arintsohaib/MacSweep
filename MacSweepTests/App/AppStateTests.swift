import Foundation
import Testing

@testable import MacSweep

@Suite("AppState")
struct AppStateTests {
    private func sampleResult() throws -> ScanResult {
        let low = try CleanupItem(
            category: .uninstalledAppRemnants,
            title: "Gone",
            reason: "app absent",
            paths: [PathSnapshot(url: URL(fileURLWithPath: "/Users/u/Library/Containers/com.vendor.Gone"), kind: .directory, size: 1000, modificationDate: nil)],
            risk: .low,
            confidence: .high,
            evidence: [Evidence(kind: .applicationAbsent, detail: "d")],
            recommendedAction: .moveToTrash,
            selectedByDefault: true,
            cleanupAllowed: true
        )
        let review = try CleanupItem(
            category: .uninstalledAppRemnants,
            title: "Shared",
            reason: "shared",
            paths: [PathSnapshot(url: URL(fileURLWithPath: "/Users/u/Library/Group Containers/group.com.vendor.Gone"), kind: .directory, size: 500, modificationDate: nil)],
            risk: .review,
            confidence: .medium,
            evidence: [Evidence(kind: .sharedOwnership, detail: "d")],
            recommendedAction: .moveToTrash,
            selectedByDefault: false,
            cleanupAllowed: true
        )
        let protected = try CleanupItem(
            category: .reviewOnly,
            title: "Docs",
            reason: "protected",
            paths: [PathSnapshot(url: URL(fileURLWithPath: "/Users/u/Documents/x"), kind: .directory, size: 100, modificationDate: nil)],
            risk: .protected,
            confidence: .high,
            evidence: [Evidence(kind: .systemOwnership, detail: "d")],
            recommendedAction: .reviewOnly,
            selectedByDefault: false,
            cleanupAllowed: false
        )
        return ScanResult(items: [low, review, protected], diagnostics: [])
    }

    @MainActor
    @Test("nothing is selected automatically after a finished scan")
    func defaults() throws {
        let state = AppState(persistence: InMemoryPersistenceService())
        state.applyResult(try sampleResult())
        #expect(state.phase == AppState.ScanPhase.finished)
        #expect(state.selectedItems.isEmpty)
        #expect(state.selectedSize == 0)
    }

    private func resultWithCleanableCategories() throws -> ScanResult {
        let cache = try CleanupItem(
            category: .applicationCaches,
            title: "Cache",
            reason: "regenerable",
            paths: [PathSnapshot(url: URL(fileURLWithPath: "/Users/u/Library/Caches/com.vendor.App"), kind: .directory, size: 100, modificationDate: nil)],
            risk: .review,
            confidence: .medium,
            evidence: [Evidence(kind: .pathConvention, detail: "d")],
            recommendedAction: .moveToTrash,
            selectedByDefault: false,
            cleanupAllowed: true
        )
        let developer = try CleanupItem(
            category: .developerCaches,
            title: "DerivedData",
            reason: "regenerable but disruptive",
            paths: [PathSnapshot(url: URL(fileURLWithPath: "/Users/u/Library/Developer/Xcode/DerivedData"), kind: .directory, size: 200, modificationDate: nil)],
            risk: .review,
            confidence: .high,
            evidence: [Evidence(kind: .pathConvention, detail: "d")],
            recommendedAction: .moveToTrash,
            selectedByDefault: false,
            cleanupAllowed: true
        )
        return ScanResult(items: [cache, developer])
    }

    @MainActor
    @Test("basic mode pre-selects regenerable items; advanced selects nothing")
    func defaultSelectionByMode() throws {
        let state = AppState(persistence: InMemoryPersistenceService())
        state.applyResult(try resultWithCleanableCategories())

        state.applyDefaultSelection(for: .advanced)
        #expect(state.selectedItems.isEmpty)

        state.applyDefaultSelection(for: .basic)
        #expect(state.selectedItems.map(\.title) == ["Cache"])
    }

    @MainActor
    @Test("select all selects only cleanable, non-excluded items")
    func selectAllHelpers() throws {
        let state = AppState(persistence: InMemoryPersistenceService())
        state.applyResult(try sampleResult())

        state.selectAll(in: state.allItems)
        #expect(state.selectedItems.count == 2)
        #expect(!state.selectedItems.contains { $0.risk == .protected })

        state.deselectAll(in: state.allItems)
        #expect(state.selectedItems.isEmpty)
    }

    @MainActor
    @Test("review items can be selected, protected items cannot")
    func selectionRules() throws {
        let state = AppState(persistence: InMemoryPersistenceService())
        state.applyResult(try sampleResult())
        let items = state.allItems
        let review = items[1]
        let protected = items[2]
        state.toggleSelection(review)
        #expect(state.isSelected(review))
        state.toggleSelection(protected)
        #expect(!state.isSelected(protected))
    }

    @MainActor
    @Test("exclusion deselects and blocks selection")
    func exclusion() throws {
        let state = AppState(persistence: InMemoryPersistenceService())
        state.applyResult(try sampleResult())
        let low = state.allItems[0]
        state.toggleExclusion(low)
        #expect(state.isExcluded(low))
        #expect(!state.isSelected(low))
        state.toggleSelection(low)
        #expect(!state.isSelected(low))
        state.toggleExclusion(low)
        #expect(!state.isExcluded(low))
    }

    @MainActor
    @Test("pane filtering matches the sidebar")
    func panes() throws {
        let state = AppState(persistence: InMemoryPersistenceService())
        state.applyResult(try sampleResult())
        #expect(state.items(for: .review).count == 2)
        #expect(state.items(for: .uninstalled).count == 2)
        #expect(state.items(for: .overview).count == 3)
        #expect(state.items(for: .largeFiles).isEmpty)
        #expect(state.items(for: .history).isEmpty)
    }

    @MainActor
    @Test("selection survives a new scan for unexcluded defaults")
    func reselectionOnNewScan() throws {
        let state = AppState(persistence: InMemoryPersistenceService())
        state.applyResult(try sampleResult())
        let low = state.allItems[0]
        state.toggleExclusion(low)
        state.applyResult(try sampleResult())
        #expect(state.isExcluded(low))
        #expect(!state.isSelected(low))
        #expect(state.selectedItems.isEmpty)
    }

    @MainActor
    @Test("applying cleanup report removes cleaned items from allItems and selection")
    func cleanupReportUpdatesState() throws {
        let state = AppState(persistence: InMemoryPersistenceService())
        state.applyResult(try sampleResult())
        let low = state.allItems[0]

        let report = CleanupReport(results: [
            CleanupItemResult(itemID: low.id, status: .movedToTrash, message: "Moved to Trash", size: 1000),
        ])
        state.applyCleanupReport(report)

        #expect(state.cleanupPhase == .finished)
        #expect(state.cleanupReport != nil)
        #expect(state.cleanedIDs.contains(low.id))
        #expect(!state.allItems.contains { $0.id == low.id })
        #expect(state.selectedItems.isEmpty)
        #expect(state.rawItems.contains { $0.id == low.id })

        state.finishCleanupReview()
        #expect(state.cleanupPhase == .idle)
        #expect(state.cleanupReport == nil)

        // Verify history recorded in persistence
        #expect(state.history.count == 1)
        #expect(state.history.first?.totalMovedSize == 1000)
        #expect(state.history.first?.results.first?.title == "Gone")

        state.clearHistory()
        #expect(state.history.isEmpty)
    }

    @MainActor
    @Test("remaining reclaimable size excludes cleaned and non-cleanable items")
    func remainingReclaimableSize() throws {
        let state = AppState(persistence: InMemoryPersistenceService())
        state.applyResult(try sampleResult())

        // 1000 (low) + 500 (review); the protected item is not cleanable
        #expect(state.remainingReclaimableSize == 1500)

        let low = state.allItems[0]
        let report = CleanupReport(results: [
            CleanupItemResult(itemID: low.id, status: .movedToTrash, message: "Moved to Trash", size: 1000),
        ])
        state.applyCleanupReport(report)

        #expect(state.remainingReclaimableSize == 500)
        #expect(state.history.first?.totalMovedSize == 1000)
    }

    @MainActor
    @Test("settings exclusions persist and update state")
    func settingsExclusions() {
        let persistence = InMemoryPersistenceService()
        let state = AppState(persistence: persistence)

        #expect(state.settings.excludedPaths.isEmpty)

        state.addExcludedPath("/Users/u/CustomExclusion")
        #expect(state.settings.excludedPaths == ["/Users/u/CustomExclusion"])
        #expect(persistence.loadSettings().excludedPaths == ["/Users/u/CustomExclusion"])

        state.removeExcludedPath("/Users/u/CustomExclusion")
        #expect(state.settings.excludedPaths.isEmpty)
        #expect(persistence.loadSettings().excludedPaths.isEmpty)
    }
}
