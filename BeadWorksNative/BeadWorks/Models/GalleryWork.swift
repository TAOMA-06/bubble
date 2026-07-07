import Foundation

/// A finished (ironed) piece of work saved to the local gallery. The grid state is stored as
/// JSON via `BoardStore`; the finished-look preview image is stored alongside as a PNG file
/// named `previewFileName`.
struct GalleryWork: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    let createdAt: Date
    let width: Int
    let height: Int
    let cells: [Int?]
    let previewFileName: String

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        board: BeadBoard,
        previewFileName: String
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.width = board.width
        self.height = board.height
        self.cells = board.cells
        self.previewFileName = previewFileName
    }
}
