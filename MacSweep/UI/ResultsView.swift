import SwiftUI

struct ResultsView: View {
    var appState: AppState
    let pane: SidebarItem

    private var items: [CleanupItem] { appState.items(for: pane) }

    var body: some View {
        List {
            ForEach(items) { item in
                FindingRow(appState: appState, item: item)
            }
        }
        .overlay {
            if items.isEmpty {
                emptyState
            }
        }
        .navigationTitle(pane.title)
    }

    @ViewBuilder
    private var emptyState: some View {
        switch appState.phase {
        case .idle:
            ContentUnavailableView(
                "No scan yet",
                image: "MacStudio",
                description: Text("Run a scan from the Overview to find reclaimable storage.")
            )
        case .running:
            ContentUnavailableView("Scanning…", image: "MacStudioOutline")
        case .finished:
            if appState.result?.isCancelled == true {
                ContentUnavailableView(
                    "Scan cancelled",
                    systemImage: "stop.circle",
                    description: Text("The scan was stopped before it finished.")
                )
            } else {
                ContentUnavailableView(
                    "Nothing found",
                    image: "SweepBrush",
                    description: Text("No findings in this section.")
                )
            }
        }
    }
}
