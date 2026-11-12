import Foundation

/// How a `BeadBoard` should be painted: mid-craft on the pegboard, lightly fused with bead holes
/// still visible, or fully fused into soft plastic pixels.
enum BeadRenderStyle: String, Codable, Hashable, CaseIterable {
    case editing
    case lightFused
    case fullFused

    static let fusedStyles: [BeadRenderStyle] = [.fullFused, .lightFused]

    var label: String {
        switch self {
        case .editing: return "摆豆中"
        case .lightFused: return "轻熔"
        case .fullFused: return "全熔"
        }
    }

    var description: String {
        switch self {
        case .editing: return "圆珠和孔洞清晰可见"
        case .lightFused: return "保留圆珠轮廓和小孔"
        case .fullFused: return "压平成光滑像素块"
        }
    }
}
