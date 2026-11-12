import Foundation

/// Where a pegboard template came from. Mirrors Unity `PatternSource`.
enum PatternSource: String, Codable, Hashable {
    case none
    case builtin
    case imported
}
