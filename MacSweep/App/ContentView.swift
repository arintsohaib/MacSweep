import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @State private var showReview = false

    var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
        } detail: {
            DetailContainer(appState: appState, showReview: $showReview)
        }
        .sheet(isPresented: $showReview) {
            CleanupReviewSheet(appState: appState)
        }
        .frame(minWidth: 900, minHeight: 560)
    }
}

private struct DetailContainer: View {
    var appState: AppState
    @Binding var showReview: Bool

    var body: some View {
        switch appState.sidebarItem {
        case .overview:
            OverviewView(appState: appState, showReview: $showReview)
        case .history:
            HistoryView(appState: appState)
        case .settings:
            SettingsView(appState: appState)
        default:
            ResultsView(appState: appState, pane: appState.sidebarItem)
        }
    }
}

#Preview {
    ContentView()
}
