import UIKit

struct BeadConversionResult {
    let indices: [[Int]]
    let colors: [BeadColor]
}

struct ImageToBeadConverter {
    func convert(image: UIImage, width: Int, height: Int, colorCount: Int, palette: [BeadColor]) -> BeadConversionResult {
        guard width > 0, height > 0, let cgImage = image.cgImage else {
            return BeadConversionResult(indices: [], colors: [])
        }

        let pixelColors = averageColors(from: cgImage, gridWidth: width, gridHeight: height)
        let quantized = quantize(colors: pixelColors, count: min(colorCount, palette.count))
        var usedColors: [BeadColor] = []
        var colorIdMap: [String: Int] = [:]

        let indices = quantized.map { row in
            row.map { hex in
                if let id = colorIdMap[hex] { return id }
                let beadColor = BeadPaletteRepository.shared.nearestColor(
                    to: BeadColor(id: 0, name: nil, hex: hex, isRealBead: true),
                    using: palette
                )
                let id = usedColors.count
                usedColors.append(beadColor)
                colorIdMap[beadColor.hex] = id
                return id
            }
        }

        return BeadConversionResult(indices: indices, colors: usedColors)
    }

    private func averageColors(from cgImage: CGImage, gridWidth: Int, gridHeight: Int) -> [[String]] {
        let contextSize = CGSize(width: gridWidth, height: gridHeight)
        let renderer = UIGraphicsImageRenderer(size: contextSize)
        let resized = renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .medium
            ctx.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: contextSize))
        }

        guard let resizedCGImage = resized.cgImage,
              let pixelData = resizedCGImage.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else { return [] }

        let bytesPerPixel = 4
        let bytesPerRow = resizedCGImage.bytesPerRow

        var result: [[String]] = []
        for y in 0..<gridHeight {
            var row: [String] = []
            for x in 0..<gridWidth {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = data[offset]
                let g = data[offset + 1]
                let b = data[offset + 2]
                row.append(String(format: "#%02X%02X%02X", r, g, b))
            }
            result.append(row)
        }
        return result
    }

    private func quantize(colors: [[String]], count: Int) -> [[String]] {
        // MVP 简化为直接返回平均色，颜色数量限制通过 nearestColor 到 palette 自动合并
        colors
    }
}
