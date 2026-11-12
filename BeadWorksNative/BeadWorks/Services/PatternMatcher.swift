import Foundation

/// Compares placed beads against a template for replica / photo-import guides.
struct PatternMatchStats: Equatable {
    var requiredCells: Int = 0
    var correctCells: Int = 0
    var wrongCells: Int = 0
    var missingCells: Int = 0
    var extraCells: Int = 0

    var completion: Double {
        requiredCells > 0 ? Double(correctCells) / Double(requiredCells) : 1
    }

    var summary: String {
        let percent = Int((completion * 100).rounded())
        return "完成度 \(percent)% · 正确 \(correctCells) · 错误 \(wrongCells) · 缺失 \(missingCells)"
    }
}

enum PatternCellStatus: Equatable {
    case none
    case correct
    case missing
    case wrong
    case extra
}

enum PatternMatcher {
    static func evaluate(board: BeadBoard) -> PatternMatchStats {
        guard let template = board.templateCells else {
            return PatternMatchStats()
        }

        var stats = PatternMatchStats()
        let count = min(template.count, board.cells.count)
        for i in 0..<count {
            let expected = template[i]
            let placed = board.cells[i]
            if expected == nil {
                if placed != nil { stats.extraCells += 1 }
                continue
            }
            stats.requiredCells += 1
            if placed == nil {
                stats.missingCells += 1
            } else if placed == expected {
                stats.correctCells += 1
            } else {
                stats.wrongCells += 1
            }
        }
        return stats
    }

    static func status(board: BeadBoard, x: Int, y: Int) -> PatternCellStatus {
        guard board.hasTemplate else { return .none }
        let expected = board.templateColorId(atX: x, y: y)
        let placed = board.colorId(atX: x, y: y)
        if expected == nil {
            return placed == nil ? .none : .extra
        }
        if placed == nil { return .missing }
        return placed == expected ? .correct : .wrong
    }
}
