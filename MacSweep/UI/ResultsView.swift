import SwiftUI

struct ResultsView: View {
    var appState: AppState
    let pane: SidebarItem

    private var items: [CleanupItem] { appState.items(for: pane) }

    var body: some View {
        VStack(spacing: 0) {
            if !items.isEmpty {
                selectionBar
                Divider()
            }
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
        }
        .navigationTitle(pane.title)
    }

    private var selectableItems: [CleanupItem] { appState.selectableItems(in: items) }

    private var selectedSelectableCount: Int {
        selectableItems.filter { appState.isSelected($0) }.count
    }

    private var allSelected: Bool {
        !selectableItems.isEmpty && selectedSelectableCount == selectableItems.count
    }

    private var selectionBar: some View {
        HStack {
            Text("\(selectedSelectableCount) of \(selectableItems.count) selectable item\(selectableItems.count == 1 ? "" : "s") selected")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Button(allSelected ? "Deselect All" : "Select All") {
                if allSelected {
                    appState.deselectAll(in: items)
                } else {
                    appState.selectAll(in: items)
                }
            }
            .disabled(selectableItems.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
