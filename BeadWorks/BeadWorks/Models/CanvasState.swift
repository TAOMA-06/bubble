import Foundation

struct CanvasState: Codable, Identifiable, Equatable {
    let id: UUID
    var width: Int
    var height: Int
    var beadSize: BeadSize
    var mode: CanvasMode
    var colorPalette: [BeadColor]
    var cells: [UInt8]
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
            cells: [UInt8](repeating: 0, count: width * height),
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func colorIndex(at coordinate: (row: Int, col: Int)) -> Int? {
        guard coordinate.row >= 0, coordinate.row < height,
              coordinate.col >= 0, coordinate.col < width else { return nil }
        let val = cells[coordinate.row * width + coordinate.col]
        return val == 0 ? nil : Int(val) - 1
    }

    mutating func setColorIndex(_ index: Int?, at coordinate: (row: Int, col: Int)) {
        guard coordinate.row >= 0, coordinate.row < height,
              coordinate.col >= 0, coordinate.col < width else { return }
        cells[coordinate.row * width + coordinate.col] = index.map { UInt8($0 + 1) } ?? 0
        updatedAt = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, width, height, beadSize, mode, colorPalette, cells, createdAt, updatedAt
    }

    init(id: UUID, width: Int, height: Int, beadSize: BeadSize, mode: CanvasMode,
         colorPalette: [BeadColor], cells: [UInt8], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.width = width
        self.height = height
        self.beadSize = beadSize
        self.mode = mode
        self.colorPalette = colorPalette
        self.cells = cells
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        beadSize = try container.decode(BeadSize.self, forKey: .beadSize)
        mode = try container.decode(CanvasMode.self, forKey: .mode)
        colorPalette = try container.decode([BeadColor].self, forKey: .colorPalette)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        let expectedCount = max(0, width * height)
        if let flatCells = try? container.decode([UInt8].self, forKey: .cells) {
            if flatCells.count == expectedCount {
                cells = flatCells
            } else {
                var fixed = [UInt8](repeating: 0, count: expectedCount)
                for i in 0..<min(expectedCount, flatCells.count) {
                    fixed[i] = flatCells[i]
                }
                cells = fixed
            }
        } else if let nestedCells = try? container.decode([[Int?]].self, forKey: .cells) {
            var flat = [UInt8](repeating: 0, count: width * height)
            for (r, row) in nestedCells.enumerated() {
                for (c, val) in row.enumerated() {
                    if let v = val, r * width + c < flat.count {
                        flat[r * width + c] = UInt8(v + 1)
                    }
                }
            }
            cells = flat
        } else {
            cells = [UInt8](repeating: 0, count: width * height)
        }
    }
}
