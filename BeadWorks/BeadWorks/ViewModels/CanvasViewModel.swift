import Foundation
import Combine

@MainActor
final class CanvasViewModel: ObservableObject {
    @Published var state: CanvasState
    @Published var selectedColorIndex: Int = 0
    @Published var isDragging: Bool = false
    @Published var isFused: Bool = false

    private var history: [CanvasState] = []
    private var historyIndex: Int = -1

    init(state: CanvasState) {
        self.state = state
        pushHistory()
    }

    func applyColor(at coordinate: (row: Int, col: Int)) {
        guard coordinate.row >= 0, coordinate.row < state.height,
              coordinate.col >= 0, coordinate.col < state.width else { return }

        let currentIndex = state.colorIndex(at: coordinate)
        guard currentIndex != selectedColorIndex else { return }

        var next = state
        next.setColorIndex(selectedColorIndex, at: coordinate)
        state = next
        pushHistory()
    }

    func erase(at coordinate: (row: Int, col: Int)) {
        guard coordinate.row >= 0, coordinate.row < state.height,
              coordinate.col >= 0, coordinate.col < state.width else { return }

        let currentIndex = state.colorIndex(at: coordinate)
        guard currentIndex != nil else { return }

        var next = state
        next.setColorIndex(nil, at: coordinate)
        state = next
        pushHistory()
    }

    func undo() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        state = history[historyIndex]
    }

    func redo() {
        guard historyIndex < history.count - 1 else { return }
        historyIndex += 1
        state = history[historyIndex]
    }

    func clear() {
        var next = state
        next.cells = Array(repeating: Array(repeating: nil, count: next.width), count: next.height)
        state = next
        pushHistory()
    }

    func reset() {
        isFused = false
    }

    private func pushHistory() {
        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)...)
        }
        history.append(state)
        historyIndex = history.count - 1
        if history.count > 50 {
            history.removeFirst()
            historyIndex -= 1
        }
    }
}
