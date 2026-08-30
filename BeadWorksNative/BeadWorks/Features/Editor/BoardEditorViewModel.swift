import Observation
import SwiftUI
import UIKit

@MainActor
@Observable
final class BoardEditorViewModel {
    let context: EditorContext
    var board: BeadBoard
    var selectedColorId: Int
    var toolMode: ToolMode = .place
    var showGuide = true
    var showMismatches = false
    var scale: CGFloat = 1
    var ironedImage: UIImage?
    var showFinished = false

    private var history: BoardHistory
    private var lastPaintedCell: (Int, Int)?
    private var strokeChanged = false
    private var pinchBase: CGFloat = 1

    init(context: EditorContext) {
        self.context = context
        let board = context.makeBoard()
        self.board = board
        self.selectedColorId = BeadColor.palette[0].id
        self.history = BoardHistory(initial: board.cells)
        if board.hasTemplate {
            showMismatches = true
        }
    }

    var title: String { context.title }

    var boardDescription: String {
        if board.width == 29, board.height == 29 {
            return "29×29 标准拼豆板"
        }
        return "\(board.width)×\(board.height) 拼豆板"
    }

    var selectedColorName: String {
        BeadColor.byId(selectedColorId)?.name ?? "拼豆"
    }

    var canUndo: Bool { history.canUndo }
    var canRedo: Bool { history.canRedo }
    var matchStats: PatternMatchStats { PatternMatcher.evaluate(board: board) }

    func handleTouch(at location: CGPoint, cellSize: CGFloat) {
        guard toolMode.paints, cellSize > 0 else { return }
        let x = Int(floor(location.x / cellSize))
        let y = Int(floor(location.y / cellSize))
        guard board.index(x: x, y: y) != nil else { return }
        if let last = lastPaintedCell, last == (x, y) { return }
        lastPaintedCell = (x, y)

        switch toolMode {
        case .place:
            if board.place(colorId: selectedColorId, x: x, y: y) {
                strokeChanged = true
            }
        case .erase:
            if board.erase(x: x, y: y) {
                strokeChanged = true
            }
        case .eyedropper:
            if let colorId = board.colorId(atX: x, y: y) {
                selectedColorId = colorId
                toolMode = .place
            } else if let templateId = board.templateColorId(atX: x, y: y) {
                selectedColorId = templateId
                toolMode = .place
            }
        case .pan:
            break
        }
    }

    func endStroke() {
        lastPaintedCell = nil
        if strokeChanged {
            history.commit(board.cells)
            strokeChanged = false
        }
    }

    func undo() {
        guard let cells = history.undo() else { return }
        board.replaceCells(cells)
    }

    func redo() {
        guard let cells = history.redo() else { return }
        board.replaceCells(cells)
    }

    func clear() {
        board.clear()
        history.commit(board.cells)
    }

    func beginPinch() {
        pinchBase = scale
    }

    func updatePinch(magnification: CGFloat) {
        scale = min(4, max(1, pinchBase * magnification))
    }

    func resetView() {
        scale = 1
    }

    func selectColor(_ id: Int) {
        selectedColorId = id
        if toolMode == .erase || toolMode == .pan {
            toolMode = .place
        }
    }

    func makeDraft() -> WorkshopDraft? {
        guard !board.isEmpty || board.hasTemplate else { return nil }
        return WorkshopDraft(
            context: context,
            board: board,
            selectedColorId: selectedColorId,
            updatedAt: Date()
        )
    }
}
