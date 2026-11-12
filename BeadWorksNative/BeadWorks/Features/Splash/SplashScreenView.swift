import SwiftUI

/// App-launch splash shown briefly by `AppRootView` above `HomeView`. Uses a cross-fade (plus a
/// very small scale flourish when motion is allowed) so it stays comfortable under Reduce Motion,
/// which collapses to a plain fade per the design brief.
struct SplashScreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var body: some View {
        ZStack {
            BeadWorksTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 18) {
                BeadMark(diameter: 16, spacing: 7, padding: 16)

                VStack(spacing: 4) {
                    Text("bubble")
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundStyle(BeadWorksTheme.ink)
                        .tracking(1)
                    Text("拼豆工坊")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BeadWorksTheme.ink.opacity(0.55))
                        .tracking(4)
                }
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(reduceMotion ? 1 : (isVisible ? 1 : 0.92))
        }
        .accessibilityIdentifier("splashScreen")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("bubble 拼豆工坊")
        .onAppear {
            withAnimation(reduceMotion ? .easeIn(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.78)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
