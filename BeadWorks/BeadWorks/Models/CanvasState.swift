import Foundation

struct CanvasState: Codable, Identifiable, Equatable {
    let id: UUID
    var width: Int
    var height: Int
    var beadSize: BeadSize
    var mode: CanvasMode
    var colorPalette: [BeadColor]
    var cells: [[Int?]]
    var createdAt: Date
    var updatedAt: Date

    static func empty(width: Int, height: Int, beadSize: BeadSize, mode: CanvasMode = .free) -> CanvasState {
        CanvasState(
            id: UUID(),
            width: width,
            height: height,
            beadSize: beadSize,
            mode: mode,
            colorPalette: [],
            cells: Array(repeating: Array(repeating: nil, count: width), count: height),
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func colorIndex(at coordinate: (row: Int, col: Int)) -> Int? {
        guard coordinate.row >= 0, coordinate.row < height,
              coordinate.col >= 0, coordinate.col < width else { return nil }
        return cells[coordinate.row][coordinate.col]
    }

    mutating func setColorIndex(_ index: Int?, at coordinate: (row: Int, col: Int)) {
        guard coordinate.row >= 0, coordinate.row < height,
              coordinate.col >= 0, coordinate.col < width else { return }
        cells[coordinate.row][coordinate.col] = index
        updatedAt = Date()
    }
}
