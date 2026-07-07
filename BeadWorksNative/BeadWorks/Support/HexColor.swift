import Foundation

/// Parses `#RRGGBB` hex strings into 0...1 RGB components. Shared by `Color(hex:)` and the
/// bead palette's nearest-color matching so both use identical parsing semantics.
enum HexColor {
    static func components(_ hex: String) -> (r: Double, g: Double, b: Double) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            return (1, 0, 1)
        }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        return (r, g, b)
    }
}
