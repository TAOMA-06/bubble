import Foundation

/// Five original 16×16 replica patterns, ported from Unity `BuiltinPatternFactory`.
enum BuiltinPatternFactory {
    static let patternSize = 16

    static func all() -> [BeadPattern] {
        [heart(), star(), guofengCloud(), milkTeaCup(), supportSign()]
    }

    static func heart() -> BeadPattern {
        var cells = emptyGrid()
        fillHeart(&cells, cx: 8, cy: 10, color: 2)
        return build(id: "heart", title: "爱心", cells: cells)
    }

    static func star() -> BeadPattern {
        var cells = fillAll(3)
        fillStar(&cells, cx: 8, cy: 8, fillColor: 3, bgColor: 4)
        return build(id: "star", title: "星星", cells: cells)
    }

    static func guofengCloud() -> BeadPattern {
        var cells = fillAll(0)
        drawCloudSwirl(&cells, cx: 8, cy: 8, lineColor: 2, accentColor: 4, bgColor: 1)
        return build(id: "guofeng_cloud", title: "国风云纹", cells: cells)
    }

    static func milkTeaCup() -> BeadPattern {
        var cells = fillAll(1)
        drawMilkTeaCup(&cells)
        return build(id: "milk_tea_cup", title: "奶茶杯", cells: cells)
    }

    static func supportSign() -> BeadPattern {
        var cells = fillAll(1)
        drawSupportSign(&cells)
        return build(id: "support_sign", title: "应援字牌", cells: cells)
    }

    private static func build(id: String, title: String, cells: [Int?]) -> BeadPattern {
        BeadPattern(id: id, title: title, size: patternSize, cells: cells, source: .builtin)
    }

    private static func emptyGrid() -> [Int?] {
        Array(repeating: nil, count: patternSize * patternSize)
    }

    private static func fillAll(_ colorId: Int) -> [Int?] {
        Array(repeating: colorId, count: patternSize * patternSize)
    }

    private static func set(_ cells: inout [Int?], x: Int, y: Int, color: Int?) {
        guard x >= 0, y >= 0, x < patternSize, y < patternSize else { return }
        cells[y * patternSize + x] = color
    }

    private static func fillHeart(_ cells: inout [Int?], cx: Int, cy: Int, color: Int) {
        let offsets: [(Int, Int)] = [
            (0, 2), (-1, 1), (1, 1), (-2, 0), (2, 0),
            (-2, -1), (2, -1), (-1, -2), (1, -2), (0, -3),
            (-1, -3), (1, -3), (0, -4), (-1, -4), (1, -4),
            (0, -5), (-1, -5), (1, -5), (0, -6),
        ]
        for (dx, dy) in offsets {
            set(&cells, x: cx + dx, y: cy + dy, color: color)
        }
        for y in -7...(-2) {
            for x in -3...3 {
                if abs(x) + abs(y + 4) <= 4 {
                    set(&cells, x: cx + x, y: cy + y, color: color)
                }
            }
        }
    }

    private static func fillStar(_ cells: inout [Int?], cx: Int, cy: Int, fillColor: Int, bgColor: Int) {
        var points: [(Int, Int)] = []
        for i in 0..<10 {
            let angle = (Double(i) * 36.0 - 90.0) * .pi / 180.0
            let radius = i % 2 == 0 ? 6.0 : 2.8
            points.append((
                cx + Int((cos(angle) * radius).rounded()),
                cy + Int((sin(angle) * radius).rounded())
            ))
        }
        for y in 0..<patternSize {
            for x in 0..<patternSize {
                set(&cells, x: x, y: y, color: pointInPolygon(px: x, py: y, polygon: points) ? fillColor : bgColor)
            }
        }
    }

    private static func pointInPolygon(px: Int, py: Int, polygon: [(Int, Int)]) -> Bool {
        var inside = false
        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let (xi, yi) = polygon[i]
            let (xj, yj) = polygon[j]
            if (yi > py) != (yj > py) {
                let denom = Float(yj - yi) + 0.0001
                if Float(px) < ((Float(xj - xi) * Float(py - yi)) / denom) + Float(xi) {
                    inside.toggle()
                }
            }
            j = i
        }
        return inside
    }

    private static func drawCloudSwirl(
        _ cells: inout [Int?],
        cx: Int,
        cy: Int,
        lineColor: Int,
        accentColor: Int,
        bgColor: Int
    ) {
        for y in 0..<patternSize {
            for x in 0..<patternSize {
                set(&cells, x: x, y: y, color: bgColor)
            }
        }
        var t = 0
        while t < 360 {
            let rad = Double(t) * .pi / 180.0
            let radius = 1.5 + Double(t) * 0.018
            let px = cx + Int((cos(rad) * radius).rounded())
            let py = cy + Int((sin(rad) * radius).rounded())
            set(&cells, x: px, y: py, color: lineColor)
            set(&cells, x: px + 1, y: py, color: lineColor)
            if t % 40 == 0 {
                set(&cells, x: px, y: py, color: accentColor)
            }
            t += 4
        }
        drawCloudBlob(&cells, cx: cx - 4, cy: cy + 3, color: lineColor)
        drawCloudBlob(&cells, cx: cx + 5, cy: cy - 2, color: lineColor)
        drawCloudBlob(&cells, cx: cx - 1, cy: cy - 5, color: accentColor)
    }

    private static func drawCloudBlob(_ cells: inout [Int?], cx: Int, cy: Int, color: Int) {
        for dy in -1...1 {
            for dx in -2...2 {
                if abs(dx) + abs(dy) <= 2 {
                    set(&cells, x: cx + dx, y: cy + dy, color: color)
                }
            }
        }
    }

    private static func drawMilkTeaCup(_ cells: inout [Int?]) {
        for y in 3...12 {
            for x in 5...10 {
                set(&cells, x: x, y: y, color: 6)
            }
        }
        for x in 4...11 {
            set(&cells, x: x, y: 3, color: 0)
            set(&cells, x: x, y: 12, color: 0)
        }
        for y in 3...12 {
            set(&cells, x: 4, y: y, color: 0)
            set(&cells, x: 11, y: y, color: 0)
        }
        for y in 5...9 {
            for x in 6...9 {
                set(&cells, x: x, y: y, color: 4)
            }
        }
        set(&cells, x: 12, y: 4, color: 0)
        set(&cells, x: 13, y: 3, color: 0)
        set(&cells, x: 14, y: 2, color: 0)
        set(&cells, x: 12, y: 5, color: 0)
        set(&cells, x: 13, y: 5, color: 0)
        for x in 5...10 {
            set(&cells, x: x, y: 13, color: 0)
        }
    }

    private static func drawSupportSign(_ cells: inout [Int?]) {
        for y in 2...13 {
            for x in 2...13 {
                set(&cells, x: x, y: y, color: 1)
            }
        }
        for y in 3...12 {
            for x in 3...12 {
                set(&cells, x: x, y: y, color: 2)
            }
        }
        drawBlockCharJia(&cells, ox: 4, oy: 5)
        drawBlockCharYou(&cells, ox: 9, oy: 5)
    }

    private static func drawBlockCharJia(_ cells: inout [Int?], ox: Int, oy: Int) {
        for x in 0..<3 {
            set(&cells, x: ox + x, y: oy, color: 4)
            set(&cells, x: ox + x, y: oy + 4, color: 4)
        }
        for y in 0..<5 {
            set(&cells, x: ox + 1, y: oy + y, color: 4)
        }
    }

    private static func drawBlockCharYou(_ cells: inout [Int?], ox: Int, oy: Int) {
        for y in 0..<5 {
            set(&cells, x: ox, y: oy + y, color: 4)
            set(&cells, x: ox + 2, y: oy + y, color: 4)
        }
        for x in 0..<3 {
            set(&cells, x: ox + x, y: oy + 2, color: 4)
        }
    }
}
