import Foundation

/// A square bead-color template produced by `PhotoTemplateService` from an imported photo.
/// `nil` cells are transparent (below the alpha threshold) and are left as empty guide slots.
struct BeadPattern: Codable, Equatable, Hashable {
    let size: Int
    let cells: [Int?]

    func colorId(atX x: Int, y: Int) -> Int? {
        guard x >= 0, x < size, y >= 0, y < size else { return nil }
        return cells[y * size + x]
    }
}
