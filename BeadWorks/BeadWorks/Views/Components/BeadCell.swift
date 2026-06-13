import SwiftUI

struct BeadCell: View {
    let color: BeadColor?
    let number: Int?
    let isFused: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            if let color {
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(color.swiftUIColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.18)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.35), Color.clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.18)
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(
                        color: Color.black.opacity(isFused ? 0.05 : 0.12),
                        radius: isFused ? 1 : 2,
                        x: 0,
                        y: isFused ? 0.5 : 1
                    )
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
