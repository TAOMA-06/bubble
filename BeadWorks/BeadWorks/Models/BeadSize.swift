import Foundation

enum BeadSize: String, Codable, CaseIterable {
    case biggie   // 10mm
    case standard // 5mm
    case mini     // 2.6mm
    case custom

    var displayName: String {
        switch self {
        case .biggie: return "Biggie (10mm)"
        case .standard: return "标准 (5mm)"
        case .mini: return "Mini (2.6mm)"
        case .custom: return "自定义"
        }
    }

    var defaultGridSize: Int {
        switch self {
        case .biggie: return 12
        case .standard: return 24
        case .mini: return 32
        case .custom: return 64
        }
    }

    var gridRange: ClosedRange<Int> {
        switch self {
        case .biggie: return 8...32
        case .standard: return 10...128
        case .mini: return 16...640
        case .custom: return 8...640
        }
    }
}
