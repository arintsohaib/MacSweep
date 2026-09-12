import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var newPathText = ""
    @State private var showClearHistoryConfirmation = false

    /// Categories that have a scan rule in this build. Others are shown for
    /// transparency but cannot be enabled.
    private var implementedCategories: Set<ScanCategory> {
        Set(ScanEngine.defaultScanners.map(\.category))
    }

    @ViewBuilder
    private func categoryRow(_ category: ScanCategory) -> some View {
        let implemented = implementedCategories.contains(category)
        Toggle(isOn: Binding(
            get: { appState.settings.enabledCategories.contains(category) },
            set: { enabled in
                var updated = appState.settings.enabledCategories
                if enabled {
                    updated.insert(category)
                } else {
                    updated.remove(category)
                }
                appState.settings.enabledCategories = updated
                appState.updateSettings(appState.settings)
            }
        )) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: category.systemImage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(category.displayName)
                            .font(.body.weight(.medium))
                        riskTag(category)
                    }
                    Text(category.settingsSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(category.settingsCleanupNote)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .disabled(!implemented)
        .opacity(implemented ? 1 : 0.55)
    }

    private func riskTag(_ category: ScanCategory) -> some View {
        let informational = category.cleanupRisk == .informational
        let color: Color = informational ? .secondary : .orange
        return Text(informational ? "Info" : "Review")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private let sizeOptions: [(String, Int64)] = [
        ("100 MB", 100 * 1024 * 1024),
        ("250 MB", 250 * 1024 * 1024),
        ("512 MB (Default)", 512 * 1024 * 1024),
        ("1 GB", 1024 * 1024 * 1024),
        ("2 GB", 2 * 1024 * 1024 * 1024),
        ("5 GB", 5 * 1024 * 1024 * 1024),
    ]

    var body: some View {
        Form {
            Section("Scan Categories") {
                Text("Choose which categories are scanned. Categories marked Review are never pre-selected — you choose each item before anything is moved to the Trash.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(ScanCategory.allCases.filter { $0 != .reviewOnly }) { category in
                    categoryRow(category)
                }
            }

            Section("Large Files Discovery") {
                Picker("Minimum File Size", selection: Binding(
                    get: { appState.settings.minLargeFileSize },
                    set: {
                        appState.settings.minLargeFileSize = $0
                        appState.updateSettings(appState.settings)
                    }
                )) {
                    ForEach(sizeOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                Text("Files in ~/Downloads and ~/Desktop exceeding this size will be discovered for review.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Path Exclusions") {
                Text("Paths listed here are ignored during scans and will never be selected for cleanup.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if appState.settings.excludedPaths.isEmpty {
                    Text("No custom exclusions configured.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(appState.settings.excludedPaths, id: \.self) { path in
                        HStack {
                            Text(path)
                                .font(.caption)
                                .textSelection(.enabled)
                            Spacer()
                            Button("Remove") {
                                appState.removeExcludedPath(path)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                HStack {
                    TextField("Add path to exclude (e.g. /Users/name/Library/Caches/...)", text: $newPathText)
                    Button("Add") {
                        let trimmed = newPathText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            appState.addExcludedPath(trimmed)
                            newPathText = ""
                        }
                    }
                    .disabled(newPathText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section("Safety Policy") {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Protected Paths Cannot Be Overridden", systemImage: "shield.checkered")
                            .font(.callout.bold())
                        Text("System roots (`/System`, `/usr`, `/bin`, `/etc`) and personal folders (`Documents`, `Desktop`, `Downloads`, `~/Library/Preferences`, `.ssh`, `Keychains`) are permanently protected by MacSweep's safety engine and can never be disabled by settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Some Findings Are Never Cleaned", systemImage: "info.circle")
                            .font(.callout.bold())
                        Text("Uninstalled Apps and Large Files are informational only: you review them and act yourself. MacSweep never moves their items.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Cleanup History") {
                HStack {
                    Text("Retained Operations: \(appState.history.count)")
                    Spacer()
                    Button("Clear History", role: .destructive) {
                        showClearHistoryConfirmation = true
                    }
                    .disabled(appState.history.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .confirmationDialog(
            "Clear Cleanup History?",
            isPresented: $showClearHistoryConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All History", role: .destructive) {
                appState.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all saved operation records. Files in the macOS Trash are not affected.")
        }
    }
}
