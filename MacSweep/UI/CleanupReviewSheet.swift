import SwiftUI

struct CleanupReviewSheet: View {
    var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var items: [CleanupItem] { appState.selectedItems }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(titleText)
                .font(.title2.bold())

            switch appState.cleanupPhase {
            case .idle:
                idleContent
            case .running:
                runningContent
            case .finished:
                finishedContent
            }

            Divider()

            buttonRow
        }
        .padding(20)
        .frame(width: 580)
    }

    private var titleText: String {
        switch appState.cleanupPhase {
        case .idle:
            return "Review Cleanup"
        case .running:
            return "Cleaning…"
        case .finished:
            return "Cleanup Report"
        }
    }

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if items.isEmpty {
                Text("No items are selected. Select findings to review before cleanup.")
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 20) {
                    Label("\(items.count) item\(items.count == 1 ? "" : "s")", systemImage: "checkmark.circle")
                    Label(MacByteFormat.format(appState.selectedSize), systemImage: "internaldrive")
                }
                .font(.callout)

                riskSummary

                if items.count > 50 {
                    Label(
                        "You are about to move \(items.count) items to the Trash. Review the affected locations carefully before continuing.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.callout)
                    .foregroundStyle(.orange)
                }

                Text(trashExplanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                locationsList
            }
        }
    }

    private var runningContent: some View {
        VStack(alignment: .center, spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Moving selected items to the Trash…")
                .font(.headline)
            Text("Items are revalidated immediately before each move. You can cancel at any time; completed moves remain in the Trash.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var finishedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let report = appState.cleanupReport {
                Text(report.summary)
                    .font(.headline)

                let rawLookup = Dictionary(uniqueKeysWithValues: appState.rawItems.map { ($0.id, $0) })

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.results) { res in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: iconName(for: res.status))
                                    .foregroundStyle(iconColor(for: res.status))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rawLookup[res.itemID]?.title ?? "Item")
                                        .font(.callout.bold())
                                    Text(res.message)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let suggestion = res.recoverySuggestion {
                                        Text(suggestion)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                if res.size > 0 {
                                    Text(MacByteFormat.format(res.size))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
    }

    private var buttonRow: some View {
        HStack {
            switch appState.cleanupPhase {
            case .idle:
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button {
                    appState.startCleanup()
                } label: {
                    Text(confirmTitle)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(items.isEmpty || appState.isScanning)
            case .running:
                Button("Cancel Cleanup") {
                    appState.cancelCleanup()
                }
                Spacer()
            case .finished:
                Spacer()
                Button("Done") {
                    appState.finishCleanupReview()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
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

    private var confirmTitle: String {
        "Move \(items.count) Item\(items.count == 1 ? "" : "s") to Trash"
    }

    private var trashExplanation: String {
        "Moving to Trash puts each selected item in the macOS Trash, where it stays recoverable. Nothing is permanently deleted by MacSweep. You can restore items from the Trash, or empty the Trash manually when you are sure."
    }

    private var riskSummary: some View {
        let low = items.filter { $0.risk == .low }.count
        let review = items.filter { $0.risk == .review }.count
        return VStack(alignment: .leading, spacing: 4) {
            if low > 0 {
                Text("\(low) low-risk item\(low == 1 ? "" : "s")")
            }
            if review > 0 {
                Text("\(review) item\(review == 1 ? "" : "s") you should review")
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private var locationsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Affected locations")
                .font(.callout.bold())
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(items, id: \.id) { item in
                        ForEach(item.paths, id: \.url.path) { path in
                            Text(path.path)
                                .font(.caption)
                                .textSelection(.enabled)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
            }
            .frame(maxHeight: 160)
        }
    }
}
