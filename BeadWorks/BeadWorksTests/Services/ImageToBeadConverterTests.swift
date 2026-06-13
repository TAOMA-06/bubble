import XCTest
import UIKit
@testable import BeadWorks

final class ImageToBeadConverterTests: XCTestCase {
    func testConvertToGrid() throws {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        let converter = ImageToBeadConverter()
        let palette = [
            BeadColor(id: 0, name: "Red", hex: "#E53935", isRealBead: true),
            BeadColor(id: 1, name: "White", hex: "#F5F5F5", isRealBead: true)
        ]
        let result = converter.convert(image: image, width: 4, height: 4, colorCount: 2, palette: palette)

        XCTAssertEqual(result.indices.count, 4)
        XCTAssertEqual(result.indices[0].count, 4)
        XCTAssertEqual(Set(result.colors.map { $0.hex }).count, 1)
    }
}
