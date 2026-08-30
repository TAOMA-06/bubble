import SwiftUI

/// Shared material panel for trays, previews, and gallery items. The corners are modest and the
/// border is a little tactile so the app reads as a work surface instead of generic cards.
struct BeadPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = BeadWorksTheme.cardCornerRadius
    var fill: Color = BeadWorksTheme.cardBackground

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(BeadWorksTheme.strongDivider, lineWidth: 1)
            )
            .shadow(color: BeadWorksTheme.cardShadow, radius: 6, y: 3)
    }
}

extension View {
    func beadPanel(cornerRadius: CGFloat = BeadWorksTheme.cardCornerRadius, fill: Color = BeadWorksTheme.cardBackground) -> some View {
        modifier(BeadPanelModifier(cornerRadius: cornerRadius, fill: fill))
    }

    func pegboardPanel(cornerRadius: CGFloat = BeadWorksTheme.panelCornerRadius) -> some View {
        self
            .background(BeadWorksTheme.pegboardBackground, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(BeadWorksTheme.workbenchWoodDark.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 10, y: 6)
    }
}

extension View {
    /// Applies `gesture` only when it is non-nil so drawing and scrolling can share the canvas.
    @ViewBuilder
    func optionalGesture<G: Gesture>(_ gesture: G?) -> some View {
        if let gesture {
            self.gesture(gesture)
        } else {
            self
        }
    }
}

/// Light press feedback (slight scale + fade) for card-like tappable surfaces, e.g. the home
/// menu buttons, which otherwise get no pressed-state feedback under `.plain` button style.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
