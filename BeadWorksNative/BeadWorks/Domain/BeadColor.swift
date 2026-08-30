import SwiftUI

/// A single color in the fixed bead palette. Mirrors the Unity project's
/// `bead_palette.json`, extended with a few extra hues so photo-import color
/// matching (`PhotoTemplateService`) has enough range to look reasonable.
struct BeadColor: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    let hex: String

    var color: Color { Color(hex: hex) }
    var rgbComponents: (r: Double, g: Double, b: Double) { HexColor.components(hex) }
}

extension BeadColor {
    static let palette: [BeadColor] = [
        BeadColor(id: 0, name: "黑色", hex: "#1A1A1A"),
        BeadColor(id: 1, name: "白色", hex: "#F5F5F5"),
        BeadColor(id: 2, name: "红色", hex: "#E53935"),
        BeadColor(id: 3, name: "蓝色", hex: "#1E88E5"),
        BeadColor(id: 4, name: "黄色", hex: "#FDD835"),
        BeadColor(id: 5, name: "绿色", hex: "#43A047"),
        BeadColor(id: 6, name: "橙色", hex: "#FB8C00"),
        BeadColor(id: 7, name: "紫色", hex: "#8E24AA"),
        BeadColor(id: 8, name: "粉色", hex: "#EC407A"),
        BeadColor(id: 9, name: "棕色", hex: "#6D4C41"),
        BeadColor(id: 10, name: "灰色", hex: "#9E9E9E"),
        BeadColor(id: 11, name: "浅蓝", hex: "#81D4FA"),
    ]

    static func byId(_ id: Int) -> BeadColor? {
        palette.first { $0.id == id }
    }
}
