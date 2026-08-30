import CoreGraphics
import Foundation
import UIKit

enum PhotoTemplateError: Error, Equatable {
    case invalidImage
    case invalidGridSize
}

/// Converts an arbitrary photo into a square `BeadPattern` by cropping to a centered square,
/// box-downsampling to the target grid, and mapping each cell's average color to the nearest
/// palette color. Mirrors `PhotoToPatternConverter` from the Unity project so both versions
/// produce comparable results. Pure logic (no UIKit view code), so it is easy to unit test.
enum PhotoTemplateService {
    static let supportedSizes = [16, 24, 32, 48]
    static let defaultSize = 32
    static let alphaThreshold: Double = 0.1

    static func makePattern(
        from image: UIImage,
        gridSize: Int,
        palette: [BeadColor] = BeadColor.palette,
        title: String = "照片拼豆"
    ) throws -> BeadPattern {
        guard gridSize > 0 else { throw PhotoTemplateError.invalidGridSize }
        guard let cgImage = image.cgImage, cgImage.width > 0, cgImage.height > 0 else {
            throw PhotoTemplateError.invalidImage
        }
        guard !palette.isEmpty else { throw PhotoTemplateError.invalidImage }

        let pixels = try readPixels(cgImage: cgImage)
        let cropSize = min(pixels.width, pixels.height)
        let cropX = (pixels.width - cropSize) / 2
        let cropY = (pixels.height - cropSize) / 2

        var cells = [Int?](repeating: nil, count: gridSize * gridSize)
        for gy in 0..<gridSize {
            for gx in 0..<gridSize {
                let average = averageColor(
                    in: pixels,
                    cropX: cropX, cropY: cropY, cropSize: cropSize,
                    cellX: gx, cellY: gy, gridSize: gridSize
                )
                cells[gy * gridSize + gx] = average.a < alphaThreshold
                    ? nil
                    : nearestColorId(to: average, palette: palette)
            }
        }

        return BeadPattern(
            title: title,
            size: gridSize,
            cells: cells,
            source: .imported
        )
    }

    /// Runs conversion off the main thread so large photos do not freeze the import screen.
    static func makePatternAsync(
        from image: UIImage,
        gridSize: Int,
        palette: [BeadColor] = BeadColor.palette,
        title: String = "照片拼豆"
    ) async throws -> BeadPattern {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let pattern = try makePattern(from: image, gridSize: gridSize, palette: palette, title: title)
                    continuation.resume(returning: pattern)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Pixel sampling

    private struct PixelBuffer {
        let width: Int
        let height: Int
        let bytes: [UInt8]
    }

    private static func readPixels(cgImage: CGImage) throws -> PixelBuffer {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let drew: Bool = bytes.withUnsafeMutableBytes { rawBuffer in
            guard let context = CGContext(
                data: rawBuffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drew else { throw PhotoTemplateError.invalidImage }

        return PixelBuffer(width: width, height: height, bytes: bytes)
    }

    /// Box-averages the source pixels covered by one destination grid cell. Colors are read back
    /// out of premultiplied storage before averaging, matching how the Unity converter averages
    /// straight (non-premultiplied) `Color` samples.
    private static func averageColor(
        in pixels: PixelBuffer,
        cropX: Int, cropY: Int, cropSize: Int,
        cellX: Int, cellY: Int, gridSize: Int
    ) -> (r: Double, g: Double, b: Double, a: Double) {
        let cellPixelSize = Double(cropSize) / Double(gridSize)
        let startX = cropX + Int((Double(cellX) * cellPixelSize).rounded(.down))
        let startY = cropY + Int((Double(cellY) * cellPixelSize).rounded(.down))
        let endX = cropX + Int((Double(cellX + 1) * cellPixelSize).rounded(.up))
        let endY = cropY + Int((Double(cellY + 1) * cellPixelSize).rounded(.up))

        let clampedStartX = min(max(startX, 0), pixels.width - 1)
        let clampedStartY = min(max(startY, 0), pixels.height - 1)
        let clampedEndX = min(max(endX, clampedStartX + 1), pixels.width)
        let clampedEndY = min(max(endY, clampedStartY + 1), pixels.height)

        var sumR = 0.0, sumG = 0.0, sumB = 0.0, sumA = 0.0
        var count = 0
        for y in clampedStartY..<clampedEndY {
            for x in clampedStartX..<clampedEndX {
                let offset = (y * pixels.width + x) * 4
                let a = Double(pixels.bytes[offset + 3]) / 255.0
                var r = Double(pixels.bytes[offset]) / 255.0
                var g = Double(pixels.bytes[offset + 1]) / 255.0
                var b = Double(pixels.bytes[offset + 2]) / 255.0
                if a > 0 {
                    r /= a
                    g /= a
                    b /= a
                }
                sumR += r; sumG += g; sumB += b; sumA += a
                count += 1
            }
        }

        guard count > 0 else { return (0, 0, 0, 0) }
        let n = Double(count)
        return (sumR / n, sumG / n, sumB / n, sumA / n)
    }

    private static func nearestColorId(
        to color: (r: Double, g: Double, b: Double, a: Double),
        palette: [BeadColor]
    ) -> Int {
        var bestId = palette[0].id
        var bestDistance = Double.greatestFiniteMagnitude
        for entry in palette {
            let c = entry.rgbComponents
            let dr = color.r - c.r
            let dg = color.g - c.g
            let db = color.b - c.b
            let distance = dr * dr + dg * dg + db * db
            if distance < bestDistance {
                bestDistance = distance
                bestId = entry.id
            }
        }
        return bestId
    }
}
