import SwiftUI

struct RiskBadge: View {
    let risk: RiskLevel

    var body: some View {
        Label(risk.displayName, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var icon: String {
        switch risk {
        case .low: "checkmark.shield.fill"
        case .review: "exclamationmark.triangle.fill"
        case .protected: "lock.fill"
        }
    }

    private var color: Color {
        switch risk {
        case .low: .green
        case .review: .orange
        case .protected: .red
        }
    }
}
