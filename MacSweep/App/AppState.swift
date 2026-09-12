import Foundation
import Observation

enum SidebarItem: String, CaseIterable, Identifiable, Hashable, Sendable {
    case overview
    case uninstalled
    case caches
    case logs
    case developer
    case largeFiles
    case review
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .uninstalled: "Uninstalled Apps"
        case .caches: "Caches"
        case .logs: "Logs"
        case .developer: "Developer"
        case .largeFiles: "Large Files"
        case .review: "Protected / Review"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .uninstalled: "trash"
        case .caches: "arrow.triangle.2.circlepath"
        case .logs: "doc.text"
        case .developer: "chevron.left.forwardslash.chevron.right"
        case .largeFiles: "externaldrive.fill"
        case .review: "exclamationmark.shield"
        case .history: "clock"
        case .settings: "gearshape"
        }
    }
}

@MainActor
@Observable
final class AppState {
    enum ScanPhase: Equatable {
        case idle
        case running
        case finished
    }

    enum CleanupPhase: Equatable {
        case idle
        case running
        case finished
    }

    private(set) var phase: ScanPhase = .idle
    private(set) var result: ScanResult?
    private(set) var progress: ScanProgress?
    private(set) var selection: Set<CleanupItemID> = []
    private(set) var excluded: Set<CleanupItemID> = []
    private(set) var cleanupPhase: CleanupPhase = .idle
    private(set) var cleanupReport: CleanupReport?
    private(set) var cleanedIDs: Set<CleanupItemID> = []
    var sidebarItem: SidebarItem = .overview
    private(set) var scanMode: CleanupMode = .basic
    /// A read-only snapshot of the current Mac, shown on the dashboard.
    let systemInfo: SystemInfo

    private let persistence: any PersistenceService
    var settings: UserSettings

    private var scanTask: Task<Void, Never>?
    private var cleanupTask: Task<Void, Never>?

    init(persistence: any PersistenceService = FilePersistenceService(), systemInfo: SystemInfo = .current()) {
        self.persistence = persistence
        self.systemInfo = systemInfo
        let loaded = persistence.loadSettings()
        self.settings = loaded
    }

    var isScanning: Bool { phase == .running }
    var isCleaning: Bool { cleanupPhase == .running }

    var allItems: [CleanupItem] {
        (result?.items ?? []).filter { !cleanedIDs.contains($0.id) }
    }

    var rawItems: [CleanupItem] {
        result?.items ?? []
    }

    var selectedItems: [CleanupItem] {
        allItems.filter { selection.contains($0.id) && !excluded.contains($0.id) }
    }

    var selectedSize: Int64 {
        selectedItems.reduce(0) { $0 + $1.totalSize }
    }

    var remainingReclaimableSize: Int64 {
        allItems.filter(\.cleanupAllowed).reduce(0) { $0 + $1.totalSize }
    }

    var permissionWarnings: [ScanDiagnostic] {
        result?.permissionLimitations ?? []
    }

    func items(for pane: SidebarItem) -> [CleanupItem] {
        switch pane {
        case .overview:
            return allItems
        case .uninstalled:
            return allItems.filter { $0.category == .uninstalledAppRemnants }
        case .caches:
            return allItems.filter { $0.category == .applicationCaches || $0.category == .savedState || $0.category == .webStorage }
        case .logs:
            return allItems.filter { $0.category == .logs }
        case .developer:
            return allItems.filter { $0.category == .developerCaches }
        case .largeFiles:
            return allItems.filter { $0.category == .largeFiles }
        case .review:
            return allItems.filter { $0.risk == .review || $0.risk == .protected }
        case .history, .settings:
            return []
        }
    }

    func isSelected(_ item: CleanupItem) -> Bool {
        selection.contains(item.id) && !excluded.contains(item.id)
    }

    func isExcluded(_ item: CleanupItem) -> Bool {
        if excluded.contains(item.id) { return true }
        let itemPaths = item.paths.map { $0.url.standardizedFileURL.resolvingSymlinksInPath().path }
        return settings.excludedPaths.contains { exc in
            itemPaths.contains { $0 == exc || $0.hasPrefix(exc + "/") }
        }
    }

    func toggleSelection(_ item: CleanupItem) {
        guard item.cleanupAllowed, !isExcluded(item) else { return }
        if selection.contains(item.id) {
            selection.remove(item.id)
        } else {
            selection.insert(item.id)
        }
    }

    func toggleExclusion(_ item: CleanupItem) {
        let paths = item.paths.map { $0.url.standardizedFileURL.resolvingSymlinksInPath().path }
        if isExcluded(item) {
            excluded.remove(item.id)
            settings.excludedPaths.removeAll { paths.contains($0) }
        } else {
            excluded.insert(item.id)
            for path in paths where !settings.excludedPaths.contains(path) {
                settings.excludedPaths.append(path)
            }
        }
        persistence.saveSettings(settings)
        selection.remove(item.id)
    }

    func addExcludedPath(_ path: String) {
        guard !settings.excludedPaths.contains(path) else { return }
        settings.excludedPaths.append(path)
        persistence.saveSettings(settings)
    }

    func removeExcludedPath(_ path: String) {
        settings.excludedPaths.removeAll { $0 == path }
        persistence.saveSettings(settings)
    }

    func updateSettings(_ newSettings: UserSettings) {
        self.settings = newSettings
        persistence.saveSettings(newSettings)
    }

    var history: [HistoricalCleanupRecord] {
        persistence.loadHistory()
    }

    func clearHistory() {
        persistence.clearHistory()
    }

    func startScan(mode: CleanupMode) {
        guard !isScanning else { return }
        scanMode = mode
        settings.enabledCategories = mode.scanCategories
        persistence.saveSettings(settings)
        phase = .running
        progress = ScanProgress(phase: .running, message: "Starting scan")
        let engine = ScanEngine(scanners: ScanEngine.defaultScanners)
        let fileSystem = RealFileSystem()
        let registry = SystemApplicationRegistry()
        let home = FileManager.default.homeDirectoryForCurrentUser
        let reporter = MainActorProgressReporter(appState: self)
        let exclusions = PathExclusions(paths: settings.excludedPaths.map { URL(fileURLWithPath: $0) })
        let config = ScanConfiguration(minLargeFileSize: settings.minLargeFileSize)
        let categories = mode.scanCategories
        scanTask = Task {
            let scanResult = await engine.scan(
                fileSystem: fileSystem,
                applications: registry,
                exclusions: exclusions,
                configuration: config,
                progress: reporter,
                homeDirectory: home,
                enabledCategories: categories
            )
            self.applyResult(scanResult)
            self.applyDefaultSelection(for: mode)
        }
    }

    func cancelScan() {
        scanTask?.cancel()
    }

    func applyResult(_ scanResult: ScanResult) {
        result = scanResult
        phase = .finished
        progress = nil
        cleanedIDs = []
        cleanupReport = nil
        cleanupPhase = .idle
        // Nothing is selected automatically. MacSweep recommends; the user decides.
        selection = []
    }

    /// Applies the mode's pre-selection. Basic pre-selects only regenerable
    /// cache and log items; Advanced pre-selects nothing.
    func applyDefaultSelection(for mode: CleanupMode) {
        let categories = mode.autoSelectCategories
        guard !categories.isEmpty else { return }
        for item in allItems where item.cleanupAllowed && categories.contains(item.category) && !isExcluded(item) {
            selection.insert(item.id)
        }
    }

    /// Items that can be selected right now (cleanable and not excluded).
    func selectableItems(in items: [CleanupItem]) -> [CleanupItem] {
        items.filter { $0.cleanupAllowed && !isExcluded($0) }
    }

    func selectAll(in items: [CleanupItem]) {
        for item in selectableItems(in: items) {
            selection.insert(item.id)
        }
    }

    func deselectAll(in items: [CleanupItem]) {
        for item in items {
            selection.remove(item.id)
        }
    }

    func startCleanup() {
        guard !isCleaning, !isScanning, !selectedItems.isEmpty else { return }
        let items = selectedItems
        cleanupPhase = .running
        cleanupReport = nil
        let engine = CleanupEngine(
            fileSystem: RealFileSystem(),
            trash: RealTrashService(),
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
        cleanupTask = Task.detached(priority: .userInitiated) {
            let report = await engine.cleanup(selectedItems: items)
            await MainActor.run {
                self.applyCleanupReport(report)
            }
        }
    }

    func cancelCleanup() {
        cleanupTask?.cancel()
    }

    func finishCleanupReview() {
        cleanupPhase = .idle
        cleanupReport = nil
    }

    func applyCleanupReport(_ report: CleanupReport) {
        cleanupReport = report
        cleanupPhase = .finished
        var cleaned: Set<CleanupItemID> = []
        let rawLookup = Dictionary(uniqueKeysWithValues: rawItems.map { ($0.id, $0) })
        var itemHistories: [HistoricalItemResult] = []

        for res in report.results {
            if res.status == .movedToTrash || res.status == .alreadyAbsent {
                cleaned.insert(res.itemID)
            }
            let item = rawLookup[res.itemID]
            itemHistories.append(HistoricalItemResult(
                itemID: res.itemID.rawValue,
                title: item?.title ?? "Item",
                category: item?.category ?? .uninstalledAppRemnants,
                status: res.status,
                size: res.size,
                message: res.message,
                paths: item?.paths.map { $0.url.path }
            ))
        }
        cleanedIDs.formUnion(cleaned)
        selection.subtract(cleaned)
        cleanupTask = nil

        let record = HistoricalCleanupRecord(
            timestamp: report.finishedAt,
            itemCount: report.results.count,
            totalMovedSize: report.totalMovedSize,
            summary: report.summary,
            results: itemHistories
        )
        persistence.appendHistory(record)
    }
}

extension ScanEngine {
    static var defaultScanners: [any FindingsScanner] {
        [
            UninstalledAppRemnantsScanner(),
            ApplicationCacheScanner(),
            LogScanner(),
            SavedStateScanner(),
            WebStorageScanner(),
            DeveloperScanner(),
            LargeFileScanner(),
        ]
    }
}

final class MainActorProgressReporter: ProgressReporter, @unchecked Sendable {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func report(_ progress: ScanProgress) {
        Task { @MainActor [appState] in
            appState.setProgress(progress)
        }
    }
}

extension AppState {
    fileprivate func setProgress(_ progress: ScanProgress) {
        self.progress = progress
    }
}
