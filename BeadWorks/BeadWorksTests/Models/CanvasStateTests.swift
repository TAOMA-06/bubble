import XCTest
@testable import BeadWorks

final class CanvasStateTests: XCTestCase {
    func testCanvasStateCreation() {
        let palette = [
            BeadColor(id: 0, name: "Black", hex: "#333333", isRealBead: true),
            BeadColor(id: 1, name: "White", hex: "#FFFFFF", isRealBead: true)
        ]
        let state = CanvasState(
            id: UUID(),
            width: 4,
            height: 4,
            beadSize: .standard,
            mode: .free,
            colorPalette: palette,
            cells: [UInt8](repeating: 0, count: 16),
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(state.width, 4)
        XCTAssertEqual(state.height, 4)
        XCTAssertEqual(state.beadSize, .standard)
        XCTAssertEqual(state.colorPalette.count, 2)
    }

    func testCellIndexAccess() {
        var state = CanvasState.empty(width: 3, height: 3, beadSize: .standard)
        state.setColorIndex(0, at: (1, 1))
        XCTAssertEqual(state.colorIndex(at: (1, 1)), 0)
        XCTAssertNil(state.colorIndex(at: (0, 0)))
    }
}
