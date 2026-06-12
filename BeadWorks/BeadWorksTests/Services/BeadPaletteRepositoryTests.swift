import XCTest
@testable import BeadWorks

final class BeadPaletteRepositoryTests: XCTestCase {
    func testDefaultPaletteHas48Colors() {
        let palette = BeadPaletteRepository.shared.defaultPalette()
        XCTAssertEqual(palette.count, 48)
    }

    func testFirstColorIsBlack() {
        let palette = BeadPaletteRepository.shared.defaultPalette()
        let first = palette.first
        XCTAssertEqual(first?.name, "Black")
        XCTAssertEqual(first?.hex, "#1A1A1A")
        XCTAssertTrue(first?.isRealBead == true)
    }
    
    func testColorWithId() {
        let color = BeadPaletteRepository.shared.color(withId: 0)
        XCTAssertNotNil(color)
        XCTAssertEqual(color?.name, "Black")
    }
    
    func testColorWithIdNotFound() {
        let color = BeadPaletteRepository.shared.color(withId: 999)
        XCTAssertNil(color)
    }
    
    func testNearestColor() {
        let red = BeadColor(id: 999, name: "TestRed", hex: "#E53935", isRealBead: false)
        let nearest = BeadPaletteRepository.shared.nearestColor(to: red)
        XCTAssertEqual(nearest.name, "Red")
    }
}
