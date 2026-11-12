import Foundation

/// Display type for a finished (ironed) piece. Native MVP keeps this as metadata plus a
/// 2D decorative frame; Unity's 3D rotate-to-inspect view is out of scope.
enum FinishedProductType: String, Codable, CaseIterable, Hashable, Identifiable {
    case fridgeMagnet
    case keychain
    case pendant

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fridgeMagnet: return "冰箱贴"
        case .keychain: return "钥匙扣"
        case .pendant: return "挂件"
        }
    }

    var systemImage: String {
        switch self {
        case .fridgeMagnet: return "magnet"
        case .keychain: return "key.fill"
        case .pendant: return "circle.circle"
        }
    }
}
