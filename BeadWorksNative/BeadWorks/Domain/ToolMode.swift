/// The active editing tool on the pegboard.
enum ToolMode: String, Codable, CaseIterable, Hashable, Identifiable {
    case place
    case erase
    case eyedropper
    case pan

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .place: return "hand.point.up.left.fill"
        case .erase: return "eraser.fill"
        case .eyedropper: return "eyedropper.halffull"
        case .pan: return "hand.draw.fill"
        }
    }

    var label: String {
        switch self {
        case .place: return "摆豆"
        case .erase: return "擦除"
        case .eyedropper: return "取色"
        case .pan: return "移动"
        }
    }

    var paints: Bool {
        self == .place || self == .erase || self == .eyedropper
    }
}
