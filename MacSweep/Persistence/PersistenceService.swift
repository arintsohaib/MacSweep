import Foundation

public protocol PersistenceService: Sendable {
    func loadSettings() -> UserSettings
    func saveSettings(_ settings: UserSettings)
    func loadHistory() -> [HistoricalCleanupRecord]
    func appendHistory(_ record: HistoricalCleanupRecord)
    func clearHistory()
}

public final class FilePersistenceService: PersistenceService, @unchecked Sendable {
    private let directory: URL
    private let lock = NSLock()
    private let fileManager: FileManager

    public init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let directory {
            self.directory = directory
        } else {
            let appSupport = fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/MacSweep", isDirectory: true)
            self.directory = appSupport
        }
        try? fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    private var settingsURL: URL {
        directory.appendingPathComponent("settings.json")
    }

    private var historyURL: URL {
        directory.appendingPathComponent("history.json")
    }

    public func loadSettings() -> UserSettings {
        lock.lock()
        defer { lock.unlock() }
        guard let data = try? Data(contentsOf: settingsURL) else {
            return .default
        }
        guard let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return .default
        }
        let migrated = decoded.migratedToCurrentVersion()
        if migrated != decoded {
            writeSettingsLocked(migrated)
        }
        return migrated
    }

    public func saveSettings(_ settings: UserSettings) {
        lock.lock()
        defer { lock.unlock() }
        writeSettingsLocked(settings)
    }

    private func writeSettingsLocked(_ settings: UserSettings) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(settings) else { return }
        try? data.write(to: settingsURL, options: .atomic)
    }

    public func loadHistory() -> [HistoricalCleanupRecord] {
        lock.lock()
        defer { lock.unlock() }
        guard let data = try? Data(contentsOf: historyURL) else {
            return []
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([HistoricalCleanupRecord].self, from: data)) ?? []
    }

    public func appendHistory(_ record: HistoricalCleanupRecord) {
        lock.lock()
        defer { lock.unlock() }
        var current = loadHistoryInternal()
        current.insert(record, at: 0) // Most recent first
        // Retain up to 200 records
        if current.count > 200 {
            current = Array(current.prefix(200))
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(current) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }

    public func clearHistory() {
        lock.lock()
        defer { lock.unlock() }
        try? fileManager.removeItem(at: historyURL)
    }

    private func loadHistoryInternal() -> [HistoricalCleanupRecord] {
        guard let data = try? Data(contentsOf: historyURL) else {
            return []
        }
        return (try? JSONDecoder().decode([HistoricalCleanupRecord].self, from: data)) ?? []
    }
}

public final class InMemoryPersistenceService: PersistenceService, @unchecked Sendable {
    private let lock = NSLock()
    private var settings: UserSettings
    private var history: [HistoricalCleanupRecord]

    public init(settings: UserSettings = .default, history: [HistoricalCleanupRecord] = []) {
        self.settings = settings
        self.history = history
    }

    public func loadSettings() -> UserSettings {
        lock.lock()
        defer { lock.unlock() }
        return settings
    }

    public func saveSettings(_ settings: UserSettings) {
        lock.lock()
        defer { lock.unlock() }
        self.settings = settings
    }

    public func loadHistory() -> [HistoricalCleanupRecord] {
        lock.lock()
        defer { lock.unlock() }
        return history
    }

    public func appendHistory(_ record: HistoricalCleanupRecord) {
        lock.lock()
        defer { lock.unlock() }
        history.insert(record, at: 0)
    }

    public func clearHistory() {
        lock.lock()
        defer { lock.unlock() }
        history.removeAll()
    }
}
