import Foundation
import Combine

enum IroningPhase: Equatable {
    case idle
    case ironing
    case choosingAccessory
    case attaching(AccessoryType)
    case done
}

@MainActor
final class CanvasViewModel: ObservableObject {
    @Published var state: CanvasState
    @Published var selectedColorIndex: Int = 0
    @Published var isDragging: Bool = false
    @Published var isPanMode: Bool = false
    @Published var isFused: Bool = false
    @Published var ironingPhase: IroningPhase = .idle
    @Published var selectedAccessory: AccessoryType?

    private var history: [CanvasState] = []
    private var historyIndex: Int = -1
    private var historyPending = false
    private var lastHistoryTime: Date = .distantPast

    private var maxHistoryCount: Int {
        state.width * state.height > 10000 ? 20 : 50
    }

    init(state: CanvasState) {
        var initialState = state
        if initialState.colorPalette.isEmpty {
            initialState.colorPalette = BeadPaletteRepository.shared.defaultPalette()
        }
        self.state = initialState
        if !initialState.colorPalette.isEmpty {
            selectedColorIndex = min(selectedColorIndex, initialState.colorPalette.count - 1)
        }
        pushHistory()
    }

    func applyColor(at coordinate: (row: Int, col: Int)) {
        guard !state.colorPalette.isEmpty,
              selectedColorIndex >= 0,
              selectedColorIndex < state.colorPalette.count else { return }
        guard coordinate.row >= 0, coordinate.row < state.height,
              coordinate.col >= 0, coordinate.col < state.width else { return }

        let currentIndex = state.colorIndex(at: coordinate)
        guard currentIndex != selectedColorIndex else { return }

        state.setColorIndex(selectedColorIndex, at: coordinate)
        objectWillChange.send()
        throttledPushHistory()
    }

    func erase(at coordinate: (row: Int, col: Int)) {
        guard coordinate.row >= 0, coordinate.row < state.height,
              coordinate.col >= 0, coordinate.col < state.width else { return }

        let currentIndex = state.colorIndex(at: coordinate)
        guard currentIndex != nil else { return }

        state.setColorIndex(nil, at: coordinate)
        objectWillChange.send()
        throttledPushHistory()
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
        next.cells = [UInt8](repeating: 0, count: next.width * next.height)
        state = next
        pushHistory()
    }

    func reset() {
        isFused = false
        ironingPhase = .idle
        selectedAccessory = nil
    }

    func finish() {
        ironingPhase = .ironing
    }

    func onIroningComplete() {
        ironingPhase = .choosingAccessory
    }

    func selectAccessory(_ type: AccessoryType) {
        selectedAccessory = type
        ironingPhase = .attaching(type)
    }

    func onAttachComplete() {
        ironingPhase = .done
        isFused = true
    }

    private func throttledPushHistory() {
        let now = Date()
        if now.timeIntervalSince(lastHistoryTime) < 0.5 {
            // 在节流窗口内：安排一个收尾快照，确保最后一笔被记录
            guard !historyPending else { return }
            historyPending = true
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(500))
                self?.pushHistoryIfPending()
            }
            return
        }
        lastHistoryTime = now
        pushHistory()
    }

    private func pushHistoryIfPending() {
        guard historyPending else { return }
        historyPending = false
        lastHistoryTime = Date()
        pushHistory()
    }

    private func pushHistory() {
        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)...)
        }
        history.append(state)
        historyIndex = history.count - 1
        if history.count > maxHistoryCount {
            history.removeFirst()
            historyIndex -= 1
        }
    }
}
