import SwiftUI

struct PegboardCanvasView: View {
    let board: BeadBoard
    var style: BeadRenderStyle = .editing
    var showGuide: Bool = true
    var showMismatches: Bool = false
    var toolMode: ToolMode = .place
    var scale: CGFloat = 1
    var onPaint: (CGPoint, CGFloat) -> Void
    var onPaintEnd: () -> Void
    var onPinchBegan: () -> Void
    var onPinchChanged: (CGFloat) -> Void
    var onResetView: () -> Void

    @State private var isPinching = false

    var body: some View {
        GeometryReader { proxy in
            let fitted = BeadBoardRenderer.cellSize(for: board, in: proxy.size)
            let cellSize = max(fitted * scale, 0.5)
            let boardSize = CGSize(
                width: cellSize * CGFloat(board.width),
                height: cellSize * CGFloat(board.height)
            )

            ScrollView([.horizontal, .vertical]) {
                Canvas { graphicsContext, _ in
                    BeadBoardRenderer.draw(
                        board: board,
                        style: style,
                        in: graphicsContext,
                        cellSize: cellSize,
                        showGuide: showGuide,
                        showMismatches: showMismatches
                    )
                }
                .frame(width: boardSize.width, height: boardSize.height)
                .frame(
                    minWidth: proxy.size.width,
                    minHeight: proxy.size.height
                )
                .contentShape(Rectangle())
                .optionalGesture(
                    toolMode.paints
                        ? paintGesture(cellSize: cellSize, boardSize: boardSize, canvasSize: proxy.size)
                        : nil
                )
                .accessibilityIdentifier("boardCanvas")
            }
            .scrollDisabled(toolMode != .pan)
            .simultaneousGesture(pinchGesture)
            .onTapGesture(count: 2, perform: onResetView)
        }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if !isPinching {
                    isPinching = true
                    onPinchBegan()
                }
                onPinchChanged(value.magnification)
            }
            .onEnded { _ in
                isPinching = false
            }
    }

    private func paintGesture(cellSize: CGFloat, boardSize: CGSize, canvasSize: CGSize) -> DragGesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard toolMode.paints else { return }
                let origin = CGPoint(
                    x: (canvasSize.width - boardSize.width) / 2,
                    y: (canvasSize.height - boardSize.height) / 2
                )
                onPaint(
                    CGPoint(x: value.location.x - max(origin.x, 0), y: value.location.y - max(origin.y, 0)),
                    cellSize
                )
            }
            .onEnded { _ in
                onPaintEnd()
            }
    }
}
