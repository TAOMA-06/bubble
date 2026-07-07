/// The active editing tool on the pegboard: placing beads or erasing them.
enum ToolMode: String, Codable, CaseIterable, Hashable {
    case place
    case erase
}
