import Foundation

/// How a session was started. Used for navigation, draft restore, and the editor title.
enum EditorContext: Hashable, Codable {
    case freeform(size: Int)
    case template(pattern: BeadPattern)
    case restored(board: BeadBoard, title: String)

    static let defaultFreeformSize = 29
    static let compactFreeformSize = 16

    var title: String {
        switch self {
        case .freeform:
            return "自由创作"
        case .template(let pattern):
            return pattern.source == .builtin ? pattern.title : "拼豆模板"
        case .restored(_, let title):
            return title
        }
    }

    func makeBoard() -> BeadBoard {
        switch self {
        case .freeform(let size):
            return BeadBoard(width: size, height: size)
        case .template(let pattern):
            return pattern.guidedBoard
        case .restored(let board, _):
            return board
        }
    }
}

struct BoardSizeOption: Identifiable, Equatable, Hashable {
    let id: Int
    let size: Int
    let title: String
    let subtitle: String
    let detail: String
    let symbolName: String
    let isDefault: Bool

    static let standard = BoardSizeOption(
        id: 29,
        size: EditorContext.defaultFreeformSize,
        title: "29 × 29 标准板",
        subtitle: "最常见的 Midi beads 单块板",
        detail: "约 5.7 英寸见方，一孔一珠",
        symbolName: "square.grid.3x3.fill",
        isDefault: true
    )

    static let compact = BoardSizeOption(
        id: 16,
        size: EditorContext.compactFreeformSize,
        title: "16 × 16 快速板",
        subtitle: "适合小图标和练手",
        detail: "更快完成，保留拼豆手作感",
        symbolName: "square.grid.2x2.fill",
        isDefault: false
    )

    static let freeformOptions: [BoardSizeOption] = [.standard, .compact]
}
