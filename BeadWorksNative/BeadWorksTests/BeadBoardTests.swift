import XCTest
import CoreGraphics
@testable import BeadWorks

final class BeadBoardTests: XCTestCase {
    func testInitCreatesAllEmptyCells() {
        let board = BeadBoard(width: 4, height: 3)
        XCTAssertEqual(board.cells.count, 12)
        XCTAssertTrue(board.cells.allSatisfy { $0 == nil })
        XCTAssertTrue(board.isEmpty)
        XCTAssertEqual(board.filledCount, 0)
    }

    func testPlaceSetsColorAtCoordinate() {
        var board = BeadBoard(width: 4, height: 4)
        board.place(colorId: 2, x: 1, y: 2)
        XCTAssertEqual(board.colorId(atX: 1, y: 2), 2)
        XCTAssertNil(board.colorId(atX: 0, y: 0))
        XCTAssertEqual(board.filledCount, 1)
        XCTAssertFalse(board.isEmpty)
    }

    func testPlaceOverwritesExistingColor() {
        var board = BeadBoard(width: 2, height: 2)
        board.place(colorId: 0, x: 0, y: 0)
        board.place(colorId: 5, x: 0, y: 0)
        XCTAssertEqual(board.colorId(atX: 0, y: 0), 5)
        XCTAssertEqual(board.filledCount, 1)
    }

    func testEraseClearsCell() {
        var board = BeadBoard(width: 3, height: 3)
        board.place(colorId: 4, x: 1, y: 1)
        board.erase(x: 1, y: 1)
        XCTAssertNil(board.colorId(atX: 1, y: 1))
        XCTAssertTrue(board.isEmpty)
    }

    func testClearResetsAllCells() {
        var board = BeadBoard(width: 3, height: 3)
        for i in 0..<3 {
            board.place(colorId: i, x: i, y: 0)
        }
        XCTAssertEqual(board.filledCount, 3)
        board.clear()
        XCTAssertEqual(board.filledCount, 0)
        XCTAssertTrue(board.cells.allSatisfy { $0 == nil })
    }

    func testOutOfBoundsPlaceAndEraseAreNoOps() {
        var board = BeadBoard(width: 2, height: 2)
        board.place(colorId: 1, x: -1, y: 0)
        board.place(colorId: 1, x: 0, y: 5)
        board.erase(x: 10, y: 10)
        XCTAssertTrue(board.isEmpty)
        XCTAssertNil(board.colorId(atX: -1, y: 0))
        XCTAssertNil(board.colorId(atX: 0, y: 5))
    }

    func testTemplateColorIdReadsGuideCells() {
        let template: [Int?] = [0, nil, 2, nil]
        let board = BeadBoard(width: 2, height: 2, templateCells: template)
        XCTAssertEqual(board.templateColorId(atX: 0, y: 0), 0)
        XCTAssertNil(board.templateColorId(atX: 1, y: 0))
        XCTAssertEqual(board.templateColorId(atX: 0, y: 1), 2)
    }

    func testCodableRoundTripPreservesCellState() throws {
        var board = BeadBoard(width: 3, height: 2, templateCells: [1, nil, 3, nil, nil, 5])
        board.place(colorId: 7, x: 2, y: 1)
        board.place(colorId: 1, x: 0, y: 0)

        let data = try JSONEncoder().encode(board)
        let restored = try JSONDecoder().decode(BeadBoard.self, from: data)

        XCTAssertEqual(restored, board)
        XCTAssertEqual(restored.colorId(atX: 2, y: 1), 7)
        XCTAssertEqual(restored.templateColorId(atX: 2, y: 0), 3)
    }

    func testRendererCellSizeFitsSmallestAxis() {
        let board = BeadBoard(width: 29, height: 29)

        XCTAssertEqual(BeadBoardRenderer.cellSize(for: board, in: CGSize(width: 290, height: 580)), 10)
        XCTAssertEqual(BeadBoardRenderer.cellSize(for: board, in: CGSize(width: 580, height: 145)), 5)
    }

    func testBoardSizeOptionsKeepStandardBoardAsDefault() {
        XCTAssertEqual(EditorContext.defaultFreeformSize, 29)
        XCTAssertEqual(BoardSizeOption.freeformOptions.first, .standard)
        XCTAssertEqual(BoardSizeOption.freeformOptions.first?.size, 29)
        XCTAssertTrue(BoardSizeOption.freeformOptions.first?.isDefault == true)
    }

    func testDefaultFusedRenderStyleIsFullFused() {
        XCTAssertEqual(BeadRenderStyle.fusedStyles.first, .fullFused)
        XCTAssertEqual(BeadRenderStyle.fusedStyles.map(\.label), ["全熔", "轻熔"])
    }

    func testBeadMaterialVariationIsStableForCoordinate() {
        let first = BeadMaterial.variation(x: 12, y: 8)
        let second = BeadMaterial.variation(x: 12, y: 8)

        XCTAssertEqual(first, second)
    }

    func testBeadMaterialVariationStaysSubtle() {
        let variation = BeadMaterial.variation(x: 28, y: 17)

        XCTAssertLessThanOrEqual(abs(variation.highlightOffset.width), 0.04)
        XCTAssertLessThanOrEqual(abs(variation.highlightOffset.height), 0.035)
        XCTAssertLessThanOrEqual(abs(variation.brightness), 0.04)
        XCTAssertGreaterThanOrEqual(variation.roundness, 0.96)
        XCTAssertLessThanOrEqual(variation.roundness, 1.01)
    }
}
