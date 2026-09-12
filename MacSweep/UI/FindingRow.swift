import SwiftUI

struct FindingRow: View {
    var appState: AppState
    let item: CleanupItem
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    appState.toggleSelection(item)
                } label: {
                    Image(systemName: appState.isSelected(item) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(appState.isSelected(item) ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .disabled(!item.cleanupAllowed || appState.isExcluded(item))
                .accessibilityLabel("Select \(item.title)")

                Image(systemName: item.category.systemImage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.title)
                            .font(.headline)
                        RiskBadge(risk: item.risk)
                        if !item.cleanupAllowed {
                            tag("Review only", color: .secondary)
                        }
                        if appState.isExcluded(item) {
                            tag("Excluded", color: .secondary)
                        }
                    }
                    Text(item.reason)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(item.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(MacByteFormat.format(item.totalSize))
                        .font(.callout.weight(.semibold))
                        .monospacedDigit()
                    Button {
                        withAnimation(.snappy) {
                            expanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(expanded ? 90 : 0))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(expanded ? "Hide details" : "Show details")
                }
            }

            if expanded {
                FindingDetails(appState: appState, item: item)
                    .padding(.leading, 42)
            }
        }
        .padding(.vertical, 6)
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}
