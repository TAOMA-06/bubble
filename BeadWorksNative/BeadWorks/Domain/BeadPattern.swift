import Foundation

/// A square bead-color template: photo import, builtin replica, or a restored gallery grid.
/// `nil` cells are empty guide slots (transparent after photo conversion, or unused pegs).
struct BeadPattern: Codable, Equatable, Hashable, Identifiable {
    let id: String
    let title: String
    let size: Int
    let cells: [Int?]
    let source: PatternSource

    init(
        id: String = UUID().uuidString,
        title: String = "拼豆模板",
        size: Int,
        cells: [Int?],
        source: PatternSource = .imported
    ) {
        self.id = id
        self.title = title
        self.size = size
        self.cells = cells
        self.source = source
    }

    func colorId(atX x: Int, y: Int) -> Int? {
        guard x >= 0, x < size, y >= 0, y < size else { return nil }
        return cells[y * size + x]
    }

    /// Board with the template already filled — used for import/pattern previews.
    var previewBoard: BeadBoard {
        BeadBoard(width: size, height: size, cells: cells, templateCells: cells)
    }

    /// Empty board that still shows the template as placement guides.
    var guidedBoard: BeadBoard {
        BeadBoard(width: size, height: size, templateCells: cells)
    }
}
