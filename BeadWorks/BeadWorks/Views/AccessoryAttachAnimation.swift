import SwiftUI

struct AccessoryAttachAnimation: View {
    let accessory: AccessoryType
    @Binding var isComplete: Bool
    @State private var offset: CGFloat = -120
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1.5

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: accessory.iconName)
                .font(.system(size: 56))
                .foregroundStyle(BeadWorksColor.accent)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

            Text(accessory.displayName)
                .font(BeadWorksFont.headline())
                .foregroundStyle(BeadWorksColor.textPrimary)
        }
        .offset(y: offset)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                offset = 0
                opacity = 1
                scale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isComplete = true
            }
        }
    }
}
