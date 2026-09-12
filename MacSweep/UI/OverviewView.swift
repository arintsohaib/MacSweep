import SwiftUI

struct OverviewView: View {
    var appState: AppState
    @Binding var showReview: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                header

                if appState.isScanning {
                    scanningCard
                } else {
                    modeCards
                }

                if let result = appState.result, !appState.isScanning {
                    if result.isCancelled {
                        cancelledCard
                    } else if appState.allItems.isEmpty {
                        emptyCard
                    } else {
                        statsRow
                        actionRow
                        breakdownCard
                        if appState.scanMode == .advanced {
                            advancedCaution
                        }
                    }
                    warningsSection
                }
            }
            .padding(28)
            .frame(maxWidth: Theme.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Overview")
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 14) {
            Image(.sweep)
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("MacSweep")
                    .font(.title.bold())
                Text("Safe, deterministic storage cleanup — nothing is deleted, only moved to the Trash.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: Scan controls

    private var modeCards: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let result = appState.result {
                Text("Last scan: \(result.finishedAt.formatted(date: .abbreviated, time: .shortened)) · \(appState.scanMode.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .top, spacing: 16) {
                modeCard(.basic)
                modeCard(.advanced)
            }
        }
    }

    private func modeCard(_ mode: CleanupMode) -> some View {
        let tint: Color = mode == .basic ? .accentColor : .orange
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: mode.systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(mode.title)
                    .font(.headline)
            }
            Text(mode.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Button {
                appState.startScan(mode: mode)
            } label: {
                Text(mode == .basic ? "Start Basic Clean" : "Start Advanced Clean")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(tint)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        .card(tint: mode == .basic ? nil : .orange)
    }

    private var scanningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(appState.scanMode.title, systemImage: appState.scanMode.systemImage)
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    appState.cancelScan()
                }
            }
            if let progress = appState.progress, let fraction = progress.fractionComplete {
                ProgressView(value: fraction)
            } else {
                ProgressView()
            }
            Text(appState.progress?.message ?? "Scanning…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    // MARK: Results

    private var statsRow: some View {
        HStack(spacing: 16) {
            statCard("Reclaimable", MacByteFormat.format(appState.remainingReclaimableSize), "internaldrive", .accentColor)
            statCard("Findings", "\(appState.allItems.count)", "list.bullet", .primary)
            statCard("Selected", "\(appState.selectedItems.count)", "checkmark.circle", .green)
        }
    }

    private func statCard(_ title: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            if !appState.selectedItems.isEmpty {
                Button {
                    showReview = true
                } label: {
                    Label(reviewButtonTitle, systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Text("Select the items you want to review — nothing is selected automatically.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            let selectable = appState.selectableItems(in: appState.allItems)
            if !selectable.isEmpty {
                Button(allSelectableSelected ? "Deselect All" : "Select All (\(selectable.count))") {
                    if allSelectableSelected {
                        appState.deselectAll(in: appState.allItems)
                    } else {
                        appState.selectAll(in: appState.allItems)
                    }
                }
                .controlSize(.large)
            }
        }
    }

    private var reviewButtonTitle: String {
        let count = appState.selectedItems.count
        return "Review \(count) Item\(count == 1 ? "" : "s") (\(MacByteFormat.format(appState.selectedSize)))"
    }

    private var allSelectableSelected: Bool {
        let selectable = appState.selectableItems(in: appState.allItems)
        return !selectable.isEmpty && selectable.allSatisfy { appState.isSelected($0) }
    }

    private var breakdownCard: some View {
        let byCategory = Dictionary(grouping: appState.allItems, by: \.category)
        let maxSize = byCategory.values
            .map { $0.reduce(Int64(0)) { $0 + $1.totalSize } }
            .max() ?? 0
        return VStack(alignment: .leading, spacing: 14) {
            Text("By Category")
                .font(.headline)
            ForEach(ScanCategory.allCases, id: \.self) { category in
                if let group = byCategory[category] {
                    breakdownRow(category, items: group, maxSize: maxSize)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func breakdownRow(_ category: ScanCategory, items: [CleanupItem], maxSize: Int64) -> some View {
        let size = items.reduce(Int64(0)) { $0 + $1.totalSize }
        let fraction = maxSize > 0 ? Double(size) / Double(maxSize) : 0
        return HStack(spacing: 12) {
            Image(systemName: category.systemImage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(category.displayName)
                        .font(.callout.weight(.medium))
                    Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(MacByteFormat.format(size))
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: fraction)
                    .tint(categoryColor(category))
            }
        }
    }

    private func categoryColor(_ category: ScanCategory) -> Color {
        switch category.cleanupRisk {
        case .informational: .secondary
        case .review: .accentColor
        }
    }

    // MARK: Notices

    private var cancelledCard: some View {
        noticeCard(
            title: "Scan cancelled",
            message: "The scan was stopped before it finished. Run it again when you are ready.",
            icon: "stop.circle",
            tint: .secondary
        )
    }

    private var emptyCard: some View {
        noticeCard(
            title: "Nothing found",
            message: "No reclaimable storage was found in this scan.",
            icon: "checkmark.circle",
            tint: .green
        )
    }

    private var advancedCaution: some View {
        noticeCard(
            title: "Advanced scan",
            message: "This scan included developer caches, web storage and saved state. Review each item before cleaning — removing them can slow the next build, re-download data, or sign you out of web sites. Nothing is selected automatically.",
            icon: "exclamationmark.triangle.fill",
            tint: .orange
        )
    }

    @ViewBuilder
    private var warningsSection: some View {
        if !appState.permissionWarnings.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Some areas could not be fully scanned", systemImage: "exclamationmark.triangle")
                    .font(.callout.bold())
                ForEach(appState.permissionWarnings) { warning in
                    Text(warning.message)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Text("MacSweep does not request extra privileges for these areas. The scan results may be incomplete.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(tint: .yellow)
        }
    }

    private func noticeCard(title: String, message: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(tint: tint == .orange || tint == .yellow ? tint : nil)
    }
}
