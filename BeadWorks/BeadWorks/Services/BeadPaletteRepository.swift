import Foundation
import SwiftUI

final class BeadPaletteRepository {
    static let shared = BeadPaletteRepository()

    private let palette: [BeadColor]

    private init() {
        self.palette = BeadPaletteRepository.loadPalette()
    }

    func defaultPalette() -> [BeadColor] { palette }

    func color(withId id: Int) -> BeadColor? {
        palette.first { $0.id == id }
    }

    func nearestColor(to color: BeadColor, using palette: [BeadColor]? = nil) -> BeadColor {
        let target = palette ?? self.palette
        guard let first = target.first else { return color }
        return target.min {
            color.distance(to: $0) < color.distance(to: $1)
        } ?? first
    }

    private static func loadPalette() -> [BeadColor] {
        guard let url = Bundle.main.url(forResource: "bead_palette", withExtension: "json") else {
            assertionFailure("bead_palette.json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let wrapper = try JSONDecoder().decode(PaletteWrapper.self, from: data)
            return wrapper.colors
        } catch {
            assertionFailure("Failed to decode bead palette: \(error)")
            return []
        }
    }
}

private struct PaletteWrapper: Codable {
    let colors: [BeadColor]
}

extension BeadColor {
    func distance(to other: BeadColor) -> Double {
        let c1 = Color(hex: hex)?.rgb ?? RGB(r: 0, g: 0, b: 0)
        let c2 = Color(hex: other.hex)?.rgb ?? RGB(r: 0, g: 0, b: 0)
        let dr = c1.r - c2.r
        let dg = c1.g - c2.g
        let db = c1.b - c2.b
        return sqrt(dr * dr + dg * dg + db * db)
    }
}

private struct RGB { let r, g, b: Double }

private extension Color {
    var rgb: RGB {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGB(r: Double(r), g: Double(g), b: Double(b))
    }
}
