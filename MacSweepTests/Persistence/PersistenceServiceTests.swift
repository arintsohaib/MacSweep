import Foundation
import Testing

@testable import MacSweep

@Suite("PersistenceService")
struct PersistenceServiceTests {
    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacSweepPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("settings round-trip through file persistence")
    func settingsRoundTrip() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let service = FilePersistenceService(directory: dir)
        var settings = UserSettings.default
        settings.minLargeFileSize = 100 * 1024 * 1024
        settings.excludedPaths = ["/Users/u/Skip"]
        settings.enabledCategories = [.uninstalledAppRemnants, .logs]

        service.saveSettings(settings)

        let loaded = service.loadSettings()
        #expect(loaded.version == 1)
        #expect(loaded.minLargeFileSize == 100 * 1024 * 1024)
        #expect(loaded.excludedPaths == ["/Users/u/Skip"])
        #expect(loaded.enabledCategories == [.uninstalledAppRemnants, .logs])
    }

    @Test("missing settings file returns defaults")
    func missingSettingsDefaults() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let service = FilePersistenceService(directory: dir)
        let loaded = service.loadSettings()
        #expect(loaded == UserSettings.default)
    }

    @Test("history records append, persist, and clear")
    func historyOperations() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let service = FilePersistenceService(directory: dir)
        #expect(service.loadHistory().isEmpty)

        let record1 = HistoricalCleanupRecord(
            timestamp: Date(timeIntervalSince1970: 1000),
            itemCount: 2,
            totalMovedSize: 5000,
            summary: "Cleaned 2 items",
            results: [
                HistoricalItemResult(
                    itemID: "ms_1",
                    title: "Item 1",
                    category: .uninstalledAppRemnants,
                    status: .movedToTrash,
                    size: 5000,
                    message: "Moved"
                ),
            ]
        )
        service.appendHistory(record1)

        let loadedAfter1 = service.loadHistory()
        #expect(loadedAfter1.count == 1)
        #expect(loadedAfter1.first?.totalMovedSize == 5000)

        let record2 = HistoricalCleanupRecord(
            timestamp: Date(timeIntervalSince1970: 2000),
            itemCount: 1,
            totalMovedSize: 200,
            summary: "Cleaned 1 item",
            results: []
        )
        service.appendHistory(record2)

        let loadedAfter2 = service.loadHistory()
        #expect(loadedAfter2.count == 2)
        #expect(loadedAfter2.first?.summary == "Cleaned 1 item") // Most recent first

        service.clearHistory()
        #expect(service.loadHistory().isEmpty)
    }
}
