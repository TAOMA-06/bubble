import Foundation

enum AccessoryType: String, CaseIterable, Identifiable {
    case keychain
    case strap
    case frame

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .keychain: return "钥匙扣"
        case .strap:    return "挂绳"
        case .frame:    return "相框"
        }
    }

    var iconName: String {
        switch self {
        case .keychain: return "key.fill"
        case .strap:    return "link"
        case .frame:    return "photo.on.rectangle"
        }
    }
}
