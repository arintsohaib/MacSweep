import SwiftUI

struct PlaceholderPane: View {
    let title: String
    let message: String
    var systemImage: String = "clock"

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}
