import XCTest
import Combine
@testable import BeadWorks

@MainActor
final class CanvasViewModelTests: XCTestCase {
    func testApplyColor() {
        let vm = CanvasViewModel(state: .empty(width: 3, height: 3, beadSize: .standard))
        vm.selectedColorIndex = 0
        vm.applyColor(at: (1, 1))
        XCTAssertEqual(vm.state.colorIndex(at: (1, 1)), 0)
    }

    func testUndo() {
        let vm = CanvasViewModel(state: .empty(width: 3, height: 3, beadSize: .standard))
        vm.selectedColorIndex = 0
        vm.applyColor(at: (1, 1))
        vm.undo()
        XCTAssertNil(vm.state.colorIndex(at: (1, 1)))
    }
}
