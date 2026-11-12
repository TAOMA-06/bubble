import Foundation

/// Stroke-level undo/redo for pegboard cell arrays. A new snapshot is recorded at the end of
/// a drag, so undoing removes the last continuous paint rather than a single peg.
struct BoardHistory: Equatable {
    private var undoStack: [[Int?]]
    private var redoStack: [[Int?]]
    private let maxDepth: Int

    init(initial: [Int?], maxDepth: Int = 50) {
        undoStack = [initial]
        redoStack = []
        self.maxDepth = max(2, maxDepth)
    }

    var canUndo: Bool { undoStack.count > 1 }
    var canRedo: Bool { !redoStack.isEmpty }

    mutating func commit(_ cells: [Int?]) {
        if undoStack.last == cells { return }
        undoStack.append(cells)
        if undoStack.count > maxDepth {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    mutating func undo() -> [Int?]? {
        guard canUndo else { return nil }
        let current = undoStack.removeLast()
        redoStack.append(current)
        return undoStack.last
    }

    mutating func redo() -> [Int?]? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(next)
        return next
    }
}
