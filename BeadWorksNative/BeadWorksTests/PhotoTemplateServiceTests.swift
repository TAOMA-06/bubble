import XCTest
@testable import BeadWorks

final class PhotoTemplateServiceTests: XCTestCase {
    func testOutputSizeIsCorrect() throws {
        let image = try makeSolidImage(width: 100, height: 100, color: (255, 0, 0, 255))
        let pattern = try PhotoTemplateService.makePattern(from: image, gridSize: 16)

        XCTAssertEqual(pattern.size, 16)
        XCTAssertEqual(pattern.cells.count, 256)
    }

    func testColorIdsAreLegalPaletteIds() throws {
        let image = try makeSolidImage(width: 64, height: 64, color: (30, 140, 220, 255))
        let pattern = try PhotoTemplateService.makePattern(from: image, gridSize: 8)

        let validIds = Set(BeadColor.palette.map(\.id))
        for cell in pattern.cells {
            if let id = cell {
                XCTAssertTrue(validIds.contains(id), "unexpected color id \(id)")
            }
        }
    }

    func testSolidRedImageMapsToRedPaletteColor() throws {
        let image = try makeSolidImage(width: 32, height: 32, color: (229, 57, 53, 255))
        let pattern = try PhotoTemplateService.makePattern(from: image, gridSize: 4)

        let redId = BeadColor.palette.first { $0.name == "红色" }!.id
        XCTAssertTrue(pattern.cells.allSatisfy { $0 == redId })
    }

    func testNonSquareImageCropsToCenterSquare() throws {
        // 4x2 image, four distinct columns of color. The centered 2x2 crop should only ever see
        // columns 1 and 2 (0-indexed) -- never the outer columns 0 and 3.
        let columnColors: [(UInt8, UInt8, UInt8, UInt8)] = [
            (255, 0, 0, 255),   // column 0 (excluded by center crop)
            (0, 255, 0, 255),   // column 1 (included)
            (0, 0, 255, 255),   // column 2 (included)
            (255, 255, 0, 255), // column 3 (excluded by center crop)
        ]
        var pixels = [(UInt8, UInt8, UInt8, UInt8)]()
        for _ in 0..<2 {
            pixels.append(contentsOf: columnColors)
        }
        let image = try makeImage(width: 4, height: 2, pixels: pixels)

        let pattern = try PhotoTemplateService.makePattern(from: image, gridSize: 2)

        let greenId = BeadColor.palette.first { $0.name == "绿色" }!.id
        let blueId = BeadColor.palette.first { $0.name == "蓝色" }!.id
        XCTAssertEqual(pattern.colorId(atX: 0, y: 0), greenId)
        XCTAssertEqual(pattern.colorId(atX: 1, y: 0), blueId)
        XCTAssertEqual(pattern.colorId(atX: 0, y: 1), greenId)
        XCTAssertEqual(pattern.colorId(atX: 1, y: 1), blueId)
    }

    func testFullyTransparentImageProducesAllNilCells() throws {
        let image = try makeSolidImage(width: 16, height: 16, color: (0, 0, 0, 0))
        let pattern = try PhotoTemplateService.makePattern(from: image, gridSize: 4)

        XCTAssertTrue(pattern.cells.allSatisfy { $0 == nil })
    }

    func testTinyOnePixelImageDoesNotCrash() throws {
        let image = try makeSolidImage(width: 1, height: 1, color: (10, 200, 30, 255))
        XCTAssertNoThrow(try PhotoTemplateService.makePattern(from: image, gridSize: 16))
    }

    func testInvalidGridSizeThrows() throws {
        let image = try makeSolidImage(width: 8, height: 8, color: (0, 0, 0, 255))
        XCTAssertThrowsError(try PhotoTemplateService.makePattern(from: image, gridSize: 0)) { error in
            XCTAssertEqual(error as? PhotoTemplateError, .invalidGridSize)
        }
        XCTAssertThrowsError(try PhotoTemplateService.makePattern(from: image, gridSize: -3)) { error in
            XCTAssertEqual(error as? PhotoTemplateError, .invalidGridSize)
        }
    }

    func testImageWithoutBackingCGImageThrows() {
        let brokenImage = UIImage()
        XCTAssertThrowsError(try PhotoTemplateService.makePattern(from: brokenImage, gridSize: 8)) { error in
            XCTAssertEqual(error as? PhotoTemplateError, .invalidImage)
        }
    }

    // MARK: - Test image helpers

    private func makeSolidImage(width: Int, height: Int, color: (UInt8, UInt8, UInt8, UInt8)) throws -> UIImage {
        try makeImage(width: width, height: height, pixels: Array(repeating: color, count: width * height))
    }

    private func makeImage(width: Int, height: Int, pixels: [(UInt8, UInt8, UInt8, UInt8)]) throws -> UIImage {
        precondition(pixels.count == width * height)
        var bytes = [UInt8]()
        bytes.reserveCapacity(pixels.count * 4)
        for p in pixels {
            // Premultiply so the raw bytes are valid premultipliedLast data even for
            // partially-transparent test fixtures.
            let alpha = Double(p.3) / 255.0
            bytes.append(UInt8((Double(p.0) * alpha).rounded()))
            bytes.append(UInt8((Double(p.1) * alpha).rounded()))
            bytes.append(UInt8((Double(p.2) * alpha).rounded()))
            bytes.append(p.3)
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let provider = try XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData))
        let cgImage = try XCTUnwrap(CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ))
        return UIImage(cgImage: cgImage)
    }
}
