import SwiftUI

/// Shared visual language for MacSweep.
enum Theme {
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 18
    static let contentMaxWidth: CGFloat = 880
}

/// A rounded, subtly bordered surface used to group related content.
private struct CardBackground: ViewModifier {
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .padding(Theme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill((tint ?? .clear).opacity(tint == nil ? 0 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            )
    }
}

extension View {
    /// Wraps the view in the standard MacSweep card surface.
    func card(tint: Color? = nil) -> some View {
        modifier(CardBackground(tint: tint))
    }
}
