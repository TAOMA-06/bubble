import Foundation

enum Route: Hashable {
    case editor(EditorContext)
    case photoImport
    case gallery
}

enum EditorContext: Hashable {
    case freeform(size: Int)
    case template(pattern: BeadPattern)

    static let defaultFreeformSize = 29
    static let compactFreeformSize = 16
}

struct BoardSizeOption: Identifiable, Equatable {
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
