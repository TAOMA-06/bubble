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

    func testConvertLimitsColorIndicesForUInt8Storage() throws {
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            for y in 0..<64 {
                for x in 0..<64 {
                    UIColor(
                        red: CGFloat(x) / 63,
                        green: CGFloat(y) / 63,
                        blue: 0.5,
                        alpha: 1
                    ).setFill()
                    ctx.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }

        let converter = ImageToBeadConverter()
        let palette = BeadPaletteRepository.shared.defaultPalette()
        let result = converter.convert(image: image, width: 16, height: 16, colorCount: 8, palette: palette)

        XCTAssertEqual(result.indices.count, 16)
        XCTAssertEqual(result.indices[0].count, 16)
        XCTAssertLessThanOrEqual(result.colors.count, palette.count)
        XCTAssertLessThanOrEqual(result.colors.count, 8)
        let maxIndex = result.indices.flatMap { $0 }.max() ?? 0
        XCTAssertLessThan(maxIndex, 255)
    }
}
