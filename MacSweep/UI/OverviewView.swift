import SwiftUI

struct OverviewView: View {
    var appState: AppState
    @Binding var showReview: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if appState.result == nil, !appState.isScanning {
                    initialHero
                }
                scanSection
                if let result = appState.result, !appState.isScanning {
                    if result.isCancelled {
                        cancelledNotice
                    } else if appState.allItems.isEmpty {
                        ContentUnavailableView(
                            "Nothing found",
                            image: "SweepBrush",
                            description: Text("No reclaimable storage was found in this scan.")
                        )
                    } else {
                        reclaimableSection
                        breakdownSection
                    }
                    warningsSection
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Overview")
    }

    private var initialHero: some View {
        VStack(spacing: 16) {
            Image(.sweep)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
            Text("Ready to Sweep")
                .font(.title2.bold())
            Text("Scan your Mac to find caches, logs, leftover app files, and other storage you can safely reclaim.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    private var scanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let result = appState.result, !appState.isScanning {
                Text("Last scan: \(result.finishedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if appState.isScanning {
                VStack(alignment: .leading, spacing: 8) {
                    if let progress = appState.progress, let fraction = progress.fractionComplete {
                        ProgressView(value: fraction)
                    } else {
                        ProgressView()
                    }
                    Text(appState.progress?.message ?? "Scanning…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Cancel Scan") {
                        appState.cancelScan()
                    }
                }
            } else {
                Button {
                    appState.startScan()
                } label: {
                    Label(appState.result == nil ? "Scan for Reclaimable Storage" : "Scan Again", systemImage: "magnifyingglass")
                }
                .controlSize(.large)
            }
        }
    }

    private var cancelledNotice: some View {
        ContentUnavailableView(
            "Scan cancelled",
            systemImage: "stop.circle",
            description: Text("The scan was stopped before it finished. Run it again when you are ready.")
        )
    }

    private var reclaimableSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reclaimable Storage")
                .font(.title3.bold())
            Text(MacByteFormat.format(appState.remainingReclaimableSize))
                .font(.system(size: 34, weight: .bold, design: .rounded))
            if !appState.selectedItems.isEmpty {
                Button {
                    showReview = true
                } label: {
                    Text(reviewButtonTitle)
                }
                .controlSize(.large)
                .padding(.top, 4)
            }
        }
    }

    private var reviewButtonTitle: String {
        let count = appState.selectedItems.count
        return "Review \(count) Selected Item\(count == 1 ? "" : "s") (\(MacByteFormat.format(appState.selectedSize)))"
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Category")
                .font(.title3.bold())
            let byCategory = Dictionary(grouping: appState.allItems, by: \.category)
            ForEach(ScanCategory.allCases, id: \.self) { category in
                if let group = byCategory[category] {
                    HStack {
                        Text(category.displayName)
                        Spacer()
                        Text("\(group.count) item\(group.count == 1 ? "" : "s")")
                            .foregroundStyle(.secondary)
                            .frame(width: 110, alignment: .trailing)
                        Text(MacByteFormat.format(group.reduce(0) { $0 + $1.totalSize }))
                            .frame(width: 110, alignment: .trailing)
                    }
                    .font(.callout)
                }
            }
        }
    }

    private var warningsSection: some View {
        Group {
            if !appState.permissionWarnings.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
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
                .padding(12)
                .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
