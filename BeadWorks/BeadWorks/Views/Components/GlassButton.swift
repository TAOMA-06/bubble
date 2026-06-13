import SwiftUI

struct GlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

struct GlassButtonProminentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

extension View {
    func glassButton() -> some View {
        modifier(GlassButtonModifier())
    }
    
    func glassButtonProminent() -> some View {
        modifier(GlassButtonProminentModifier())
    }
}
