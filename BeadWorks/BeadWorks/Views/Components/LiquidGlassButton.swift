import SwiftUI

@available(iOS 26.0, *)
struct LiquidGlassButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        Button(action: action) {
            label()
        }
        .glassBackgroundEffect(
            displayMode: .always,
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

@available(iOS 26.0, *)
struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassBackgroundEffect(
                displayMode: .always,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}
