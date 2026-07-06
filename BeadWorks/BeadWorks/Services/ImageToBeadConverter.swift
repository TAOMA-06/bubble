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
                let beadColor = BeadPaletteRepository.shared.nearestColor(
                    to: BeadColor(id: 0, name: nil, hex: hex, isRealBead: true),
                    using: palette
                )
                if let id = colorIdMap[beadColor.hex] { return id }
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
        guard count > 0, !colors.isEmpty else { return colors }

        let flat = colors.flatMap { $0 }
        let unique = Array(Set(flat)).sorted()
        if unique.count <= count { return colors }

        var centroids = initialCentroids(from: unique, count: count)
        guard centroids.count == count else { return colors }

        for _ in 0..<12 {
            var buckets = Array(repeating: [String](), count: count)
            for hex in flat {
                let idx = nearestCentroidIndex(hex: hex, centroids: centroids)
                buckets[idx].append(hex)
            }
            centroids = buckets.enumerated().map { index, bucket in
                averageHex(bucket) ?? centroids[index]
            }
        }

        return colors.map { row in
            row.map { hex in
                centroids[nearestCentroidIndex(hex: hex, centroids: centroids)]
            }
        }
    }

    private func nearestCentroidIndex(hex: String, centroids: [String]) -> Int {
        guard let rgb = rgbComponents(from: hex) else { return 0 }
        var bestIndex = 0
        var bestDistance = Double.greatestFiniteMagnitude
        for (index, centroid) in centroids.enumerated() {
            guard let centroidRGB = rgbComponents(from: centroid) else { continue }
            let distance = colorDistance(rgb, centroidRGB)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        return bestIndex
    }

    private func initialCentroids(from unique: [String], count: Int) -> [String] {
        guard count > 0 else { return [] }
        guard unique.count > count else { return unique }
        guard count > 1 else { return [unique[unique.count / 2]] }

        return (0..<count).map { index in
            let position = Double(index) * Double(unique.count - 1) / Double(count - 1)
            return unique[Int(position.rounded())]
        }
    }

    private func averageHex(_ hexes: [String]) -> String? {
        let rgbs = hexes.compactMap(rgbComponents(from:))
        guard !rgbs.isEmpty else { return nil }
        let count = Double(rgbs.count)
        let average = (
            r: rgbs.reduce(0) { $0 + $1.r } / count,
            g: rgbs.reduce(0) { $0 + $1.g } / count,
            b: rgbs.reduce(0) { $0 + $1.b } / count
        )
        return hexString(from: average)
    }

    private func rgbComponents(from hex: String) -> (r: Double, g: Double, b: Double)? {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard clean.count == 6, let value = UInt32(clean, radix: 16) else { return nil }
        return (
            r: Double((value >> 16) & 0xFF),
            g: Double((value >> 8) & 0xFF),
            b: Double(value & 0xFF)
        )
    }

    private func hexString(from rgb: (r: Double, g: Double, b: Double)) -> String {
        String(
            format: "#%02X%02X%02X",
            Int(rgb.r.rounded()).clamped(to: 0...255),
            Int(rgb.g.rounded()).clamped(to: 0...255),
            Int(rgb.b.rounded()).clamped(to: 0...255)
        )
    }

    private func colorDistance(
        _ lhs: (r: Double, g: Double, b: Double),
        _ rhs: (r: Double, g: Double, b: Double)
    ) -> Double {
        let dr = lhs.r - rhs.r
        let dg = lhs.g - rhs.g
        let db = lhs.b - rhs.b
        return dr * dr + dg * dg + db * db
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
