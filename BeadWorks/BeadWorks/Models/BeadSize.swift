import Foundation

enum BeadSize: String, Codable, CaseIterable {
    case biggie   // 10mm
    case standard // 5mm
    case mini     // 2.6mm

    var displayName: String {
        switch self {
        case .biggie: return "Biggie (10mm)"
        case .standard: return "标准 (5mm)"
        case .mini: return "Mini (2.6mm)"
        }
    }

    var defaultGridSize: Int {
        switch self {
        case .biggie: return 12
        case .standard: return 24
        case .mini: return 32
        }
    }

    var gridRange: ClosedRange<Int> {
        switch self {
        case .biggie: return 8...16
        case .standard: return 10...48
        case .mini: return 16...64
        }
    }
}
