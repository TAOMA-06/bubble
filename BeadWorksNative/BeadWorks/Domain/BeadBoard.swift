import Foundation

/// The editable pegboard grid: a `width` x `height` array of placed bead color ids
/// (`nil` = empty peg), plus an optional read-only `templateCells` guide copied from a
/// `BeadPattern` when the board was started from a photo import or builtin replica.
struct BeadBoard: Codable, Equatable, Hashable {
    let width: Int
    let height: Int
    private(set) var cells: [Int?]
    let templateCells: [Int?]?

    var hasTemplate: Bool { templateCells != nil }

    init(width: Int, height: Int, templateCells: [Int?]? = nil) {
        self.width = width
        self.height = height
        self.templateCells = templateCells
        self.cells = Array(repeating: nil, count: width * height)
    }

    /// Builds a board with pre-filled cells, e.g. to preview a `BeadPattern` as if every guide
    /// slot had already been placed, or to restore a saved `GalleryWork`.
    init(width: Int, height: Int, cells: [Int?], templateCells: [Int?]? = nil) {
        self.width = width
        self.height = height
        self.templateCells = templateCells
        let expected = width * height
        if cells.count == expected {
            self.cells = cells
        } else {
            var padded = Array<Int?>(repeating: nil, count: expected)
            for i in 0..<min(expected, cells.count) {
                padded[i] = cells[i]
            }
            self.cells = padded
        }
    }

    func index(x: Int, y: Int) -> Int? {
        guard x >= 0, x < width, y >= 0, y < height else { return nil }
        return y * width + x
    }

    func colorId(atX x: Int, y: Int) -> Int? {
        guard let i = index(x: x, y: y) else { return nil }
        return cells[i]
    }

    func templateColorId(atX x: Int, y: Int) -> Int? {
        guard let i = index(x: x, y: y) else { return nil }
        return templateCells?[i] ?? nil
    }

    @discardableResult
    mutating func place(colorId: Int, x: Int, y: Int) -> Bool {
        guard let i = index(x: x, y: y) else { return false }
        guard cells[i] != colorId else { return false }
        cells[i] = colorId
        return true
    }

    @discardableResult
    mutating func erase(x: Int, y: Int) -> Bool {
        guard let i = index(x: x, y: y) else { return false }
        guard cells[i] != nil else { return false }
        cells[i] = nil
        return true
    }

    mutating func clear() {
        cells = Array(repeating: nil, count: width * height)
    }

    mutating func replaceCells(_ newCells: [Int?]) {
        guard newCells.count == width * height else { return }
        cells = newCells
    }

    var filledCount: Int { cells.reduce(0) { $1 == nil ? $0 : $0 + 1 } }
    var isEmpty: Bool { filledCount == 0 }
}
