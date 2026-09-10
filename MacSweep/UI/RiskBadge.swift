import SwiftUI

struct RiskBadge: View {
    let risk: RiskLevel

    var body: some View {
        Text(risk.displayName)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch risk {
        case .low: .green
        case .review: .orange
        case .protected: .red
        }
    }
}
