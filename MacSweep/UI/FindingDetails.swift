import AppKit
import SwiftUI

struct FindingDetails: View {
    var appState: AppState
    let item: CleanupItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    Text("Why detected")
                        .foregroundStyle(.secondary)
                    Text(item.reason)
                }
                if let app = item.application {
                    GridRow {
                        Text("Application")
                            .foregroundStyle(.secondary)
                        Text("\(app.name) — \(app.isInstalled ? "installed" : "not installed")")
                    }
                }
                if let bundleID = item.application?.bundleIdentifier {
                    GridRow {
                        Text("Bundle ID")
                            .foregroundStyle(.secondary)
                        Text(bundleID.rawValue)
                            .textSelection(.enabled)
                    }
                }
                GridRow {
                    Text("Risk")
                        .foregroundStyle(.secondary)
                    Text(item.risk.displayName)
                }
                GridRow {
                    Text("Confidence")
                        .foregroundStyle(.secondary)
                    Text(item.confidence.displayName)
                }
                if let modified = item.modifiedAt {
                    GridRow {
                        Text("Modified")
                            .foregroundStyle(.secondary)
                        Text(modified.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                GridRow {
                    Text("On cleanup")
                        .foregroundStyle(.secondary)
                    Text(item.recommendedAction.description)
                }
            }
            .font(.callout)

            VStack(alignment: .leading, spacing: 4) {
                Text("Evidence")
                    .font(.callout.bold())
                    .foregroundStyle(.secondary)
                ForEach(Array(item.evidence.enumerated()), id: \.offset) { _, evidence in
                    Text("• \(evidence.detail)")
                        .font(.callout)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Locations")
                    .font(.callout.bold())
                    .foregroundStyle(.secondary)
                ForEach(item.paths, id: \.url.path) { path in
                    HStack {
                        Text(path.path)
                            .font(.callout)
                            .textSelection(.enabled)
                        Spacer()
                        Button("Show in Finder") {
                            showInFinder(path.url)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                if let primary = item.primaryPath {
                    Button("Show in Finder") {
                        showInFinder(primary.url)
                    }
                }
                Button(appState.isExcluded(item) ? "Include Again" : "Exclude") {
                    appState.toggleExclusion(item)
                }
                .disabled(!item.cleanupAllowed)
                Spacer()
            }
        }
    }

    private func showInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
