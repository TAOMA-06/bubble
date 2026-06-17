import SwiftUI

struct BeadCell: View {
    let color: BeadColor?
    let number: Int?
    let isFused: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            if let color {
                // 1. 底部阴影（最底层）
                Ellipse()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: size * 0.85, height: size * 0.15)
                    .offset(y: size * 0.35)
                    .blur(radius: size * 0.05)

                // 2. 边缘厚度层
                Circle()
                    .fill(color.swiftUIColor.opacity(0.8))
                    .frame(width: size * 0.88, height: size * 0.88)

                // 3. 表面层
                Circle()
                    .fill(color.swiftUIColor)
                    .frame(width: size * 0.82, height: size * 0.82)
                    .overlay(
                        // 主高光（左上角）
                        RadialGradient(
                            colors: [Color.white.opacity(0.6), Color.clear],
                            center: .init(x: 0.3, y: 0.25),
                            startRadius: 0,
                            endRadius: size * 0.35
                        )
                    )
                    .overlay(
                        // 次高光（右下角微弱反光）
                        RadialGradient(
                            colors: [Color.white.opacity(0.15), Color.clear],
                            center: .init(x: 0.7, y: 0.75),
                            startRadius: 0,
                            endRadius: size * 0.25
                        )
                    )

                // 4. 中心孔洞（带倒角）
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(0.9),
                                Color.black.opacity(0.7),
                                Color.gray.opacity(0.5)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.14
                        )
                    )
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(
                        // 孔洞边缘倒角
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: size * 0.02
                            )
                    )

                // 5. 外边缘描边
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.swiftUIColor.opacity(0.6),
                                color.swiftUIColor.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size * 0.04
                    )
                    .frame(width: size * 0.88, height: size * 0.88)
            } else {
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(Color(.systemGray6))
                    .overlay(
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: size * 0.25, height: size * 0.25)
                    )
            }

            if let number {
                Text("\(number)")
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(color?.swiftUIColor.contrastText ?? .gray)
            }
        }
        .frame(width: size, height: size)
    }
}

extension Color {
    var contrastText: Color {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return .black.opacity(0.7)
        }
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.6 ? Color.black.opacity(0.7) : Color.white.opacity(0.9)
    }
}
