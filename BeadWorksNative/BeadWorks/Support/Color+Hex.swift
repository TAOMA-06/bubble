import SwiftUI

extension Color {
    init(hex: String) {
        let c = HexColor.components(hex)
        self.init(red: c.r, green: c.g, blue: c.b)
    }
}
