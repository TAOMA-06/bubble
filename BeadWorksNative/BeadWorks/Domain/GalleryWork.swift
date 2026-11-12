import Foundation

/// A finished (ironed) piece of work saved to the local gallery. The grid state is stored as
/// JSON via `BoardStore`; the finished-look preview image is stored alongside as a PNG file
/// named `previewFileName`.
struct GalleryWork: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    let createdAt: Date
    let width: Int
    let height: Int
    let cells: [Int?]
    let previewFileName: String
    var productType: FinishedProductType
    var renderStyle: BeadRenderStyle?

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        board: BeadBoard,
        previewFileName: String,
        productType: FinishedProductType = .fridgeMagnet,
        renderStyle: BeadRenderStyle? = .fullFused
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.width = board.width
        self.height = board.height
        self.cells = board.cells
        self.previewFileName = previewFileName
        self.productType = productType
        self.renderStyle = renderStyle
    }

    var board: BeadBoard {
        BeadBoard(width: width, height: height, cells: cells)
    }

    var filledCount: Int {
        cells.reduce(0) { $1 == nil ? $0 : $0 + 1 }
    }

    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, width, height, cells, previewFileName, productType, renderStyle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        cells = try container.decode([Int?].self, forKey: .cells)
        previewFileName = try container.decode(String.self, forKey: .previewFileName)
        productType = try container.decodeIfPresent(FinishedProductType.self, forKey: .productType) ?? .fridgeMagnet
        renderStyle = try container.decodeIfPresent(BeadRenderStyle.self, forKey: .renderStyle)
    }
}
