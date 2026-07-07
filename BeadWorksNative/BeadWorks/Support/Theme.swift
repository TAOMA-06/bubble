import SwiftUI

/// Warm handcraft-workbench visual language shared across the app: soft pegboard surfaces,
/// restrained wood, and small saturated bead accents.
enum BeadWorksTheme {
    // Surfaces
    static let pegboardBackground = Color(hex: "#F7E9D0")
    static let pegboardHole = Color(hex: "#A6785D").opacity(0.18)
    static let workbenchWood = Color(hex: "#D8A86A")
    static let workbenchWoodDark = Color(hex: "#8E5C38")
    static let cardBackground = Color(hex: "#FFF9EC")
    static let panelBackground = Color(hex: "#FFF2D8")
    static let trayBackground = Color(hex: "#FFE8B8")
    static let paperBackground = Color(hex: "#FFFDF8")

    // Brand
    static let accent = Color(hex: "#F05A28")
    static let accentDeep = Color(hex: "#B83D20")
    static let coolAccent = Color(hex: "#1E88E5")
    static let mintAccent = Color(hex: "#43A047")
    static let yellowAccent = Color(hex: "#FDD835")
    static let ink = Color(hex: "#33231E")

    // Structure
    static let divider = Color(hex: "#3E2C23").opacity(0.1)
    static let strongDivider = Color(hex: "#3E2C23").opacity(0.18)
    static let cardShadow = Color.black.opacity(0.1)

    static let cardCornerRadius: CGFloat = 14
    static let panelCornerRadius: CGFloat = 18
    static let controlCornerRadius: CGFloat = 12

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#FFF8E8"), Color(hex: "#F6E2C2"), Color(hex: "#EFD2A8")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
