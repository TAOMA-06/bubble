import SwiftUI

struct GlassEffectModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .buttonStyle(.glass)
    }
}

struct GlassEffectCircleModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .buttonStyle(.glass)
    }
}

extension View {
    func glassEffect() -> some View {
        modifier(GlassEffectModifier())
    }
    
    func glassEffectCircle() -> some View {
        modifier(GlassEffectCircleModifier())
    }
}
