import SwiftUI

struct IroningAnimationView: View {
    @Binding var isComplete: Bool
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let maxRadius = hypot(geo.size.width, geo.size.height) / 2

            ZStack {
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(0.35),
                                Color.red.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: maxRadius * progress
                        )
                    )
                    .blendMode(.overlay)

                ForEach(0..<20, id: \.self) { i in
                    let angle = Double(i) / 20.0 * .pi * 2
                    let r = maxRadius * progress
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 4, height: 4)
                        .offset(
                            x: cos(angle) * r,
                            y: sin(angle) * r
                        )
                        .opacity(progress > 0.1 && progress < 0.95 ? 1 : 0)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                progress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                isComplete = true
            }
        }
    }
}
