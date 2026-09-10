import SwiftUI

struct HistoryView: View {
    var appState: AppState
    @State private var showClearConfirmation = false

    var body: some View {
        Group {
            if appState.history.isEmpty {
                ContentUnavailableView(
                    "No Cleanup History",
                    systemImage: "clock",
                    description: Text("Operations will appear here after you move items to the Trash.")
                )
            } else {
                List {
                    ForEach(appState.history) { record in
                        HistoryRecordRow(record: record)
                    }
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !appState.history.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear History") {
                        showClearConfirmation = true
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear Cleanup History?",
            isPresented: $showClearConfirmation,
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

private struct HistoryRecordRow: View {
    let record: HistoricalCleanupRecord
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    Text(record.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(MacByteFormat.format(record.totalMovedSize))
                        .font(.headline)
                    Text("\(record.itemCount) item\(record.itemCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button {
                    withAnimation(.snappy) {
                        expanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
                .buttonStyle(.borderless)
            }

            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                    ForEach(record.results) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: iconName(for: item.status))
                                .foregroundStyle(iconColor(for: item.status))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.callout.bold())
                                Text(item.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if item.size > 0 {
                                Text(MacByteFormat.format(item.size))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(.vertical, 4)
    }

    private func iconName(for status: CleanupItemResult.Status) -> String {
        switch status {
        case .movedToTrash: return "checkmark.circle.fill"
        case .alreadyAbsent: return "info.circle.fill"
        case .rejected: return "exclamationmark.shield.fill"
        case .failed: return "xmark.octagon.fill"
        case .cancelled: return "stop.circle.fill"
        }
    }

    private func iconColor(for status: CleanupItemResult.Status) -> Color {
        switch status {
        case .movedToTrash: return .green
        case .alreadyAbsent: return .blue
        case .rejected: return .orange
        case .failed: return .red
        case .cancelled: return .secondary
        }
    }
}
