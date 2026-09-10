import SwiftUI

struct FindingRow: View {
    var appState: AppState
    let item: CleanupItem
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    appState.toggleSelection(item)
                } label: {
                    Image(systemName: appState.isSelected(item) ? "checkmark.square.fill" : "square")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .disabled(!item.cleanupAllowed || appState.isExcluded(item))
                .accessibilityLabel("Select \(item.title)")

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(item.title)
                            .fontWeight(.semibold)
                        RiskBadge(risk: item.risk)
                        if appState.isExcluded(item) {
                            Text("Excluded")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(item.reason)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                        Text(MacByteFormat.format(item.totalSize))
                        Text("·")
                        Text(item.category.displayName)
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    withAnimation(.snappy) {
                        expanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(expanded ? "Hide details" : "Show details")
            }

            if expanded {
                FindingDetails(appState: appState, item: item)
                    .padding(.leading, 38)
            }
        }
        .padding(.vertical, 4)
    }
}
