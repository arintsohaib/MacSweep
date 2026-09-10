import SwiftUI

struct SidebarView: View {
    var appState: AppState

    var body: some View {
        List(SidebarItem.allCases, id: \.self, selection: Binding(
            get: { Optional(appState.sidebarItem) },
            set: { appState.sidebarItem = $0 ?? .overview }
        )) { item in
            Label(item.title, systemImage: item.systemImage)
                .tag(item)
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 280)
    }
}
