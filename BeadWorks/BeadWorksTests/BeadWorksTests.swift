import XCTest
@testable import BeadWorks

final class BeadWorksTests: XCTestCase {
    func testExample() throws {
        XCTAssertEqual(2 + 2, 4)
    }
}

@MainActor
final class BeadWorksIntegrationTests: XCTestCase {
    func testFreeCreationFlow() {
        let state = CanvasState.empty(width: 4, height: 4, beadSize: .standard)
        let vm = CanvasViewModel(state: state)
        vm.state.colorPalette = [
            BeadColor(id: 0, name: "Red", hex: "#E53935", isRealBead: true),
            BeadColor(id: 1, name: "Blue", hex: "#1E88E5", isRealBead: true)
        ]
        vm.selectedColorIndex = 0
        vm.applyColor(at: (0, 0))
        vm.applyColor(at: (1, 1))
        XCTAssertEqual(vm.state.colorIndex(at: (0, 0)), 0)
        XCTAssertEqual(vm.state.colorIndex(at: (1, 1)), 0)
        vm.undo()
        XCTAssertNil(vm.state.colorIndex(at: (1, 1)))
    }
}
