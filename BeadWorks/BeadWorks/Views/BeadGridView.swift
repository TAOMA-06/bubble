import SwiftUI

struct BeadGridView: View {
    @ObservedObject var viewModel: CanvasViewModel
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        let spacing: CGFloat = 2
        let baseCellSize = baseCellSize(for: viewModel.state.beadSize)
        let cellSize = baseCellSize * scale

        GeometryReader { geo in
            let totalWidth = CGFloat(viewModel.state.width) * (cellSize + spacing)
            let totalHeight = CGFloat(viewModel.state.height) * (cellSize + spacing)
            let startX = max(0, (geo.size.width - totalWidth) / 2) + offset.width
            let startY = max(0, (geo.size.height - totalHeight) / 2) + offset.height

            ZStack {
                PegboardBackground(
                    rows: viewModel.state.height,
                    cols: viewModel.state.width,
                    cellSize: cellSize
                )
                .frame(width: totalWidth, height: totalHeight)

                Canvas { context, size in
                    for row in 0..<viewModel.state.height {
                        for col in 0..<viewModel.state.width {
                            let x = CGFloat(col) * (cellSize + spacing)
                            let y = CGFloat(row) * (cellSize + spacing)
                            let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                            let index = viewModel.state.colorIndex(at: (row, col))
                            let color = index.flatMap { viewModel.state.colorPalette[$0] }
                            
                            if let color {
                                let path = RoundedRectangle(cornerRadius: cellSize * 0.18).path(in: rect)
                                context.fill(path, with: .color(color.swiftUIColor))
                                
                                // Highlight overlay
                                let highlightPath = RoundedRectangle(cornerRadius: cellSize * 0.18).path(in: rect)
                                context.fill(highlightPath, with: .color(Color.white.opacity(0.35)))
                                
                                // Stroke
                                context.stroke(path, with: .color(Color.black.opacity(0.08)), lineWidth: 0.5)
                            } else {
                                let path = RoundedRectangle(cornerRadius: cellSize * 0.18).path(in: rect)
                                context.fill(path, with: .color(Color(.systemGray6)))
                                
                                // Peg hole
                                let holeRect = CGRect(
                                    x: x + cellSize * 0.375,
                                    y: y + cellSize * 0.375,
                                    width: cellSize * 0.25,
                                    height: cellSize * 0.25
                                )
                                context.fill(Path(ellipseIn: holeRect), with: .color(Color(.systemGray4)))
                            }
                            
                            if viewModel.state.mode == .numbered, let index {
                                let text = Text("\(index + 1)")
                                    .font(.system(size: cellSize * 0.4, weight: .medium))
                                    .foregroundColor(color?.swiftUIColor.contrastText ?? .gray)
                                context.draw(text, at: CGPoint(x: x + cellSize / 2, y: y + cellSize / 2))
                            }
                        }
                    }
                }
                .frame(width: totalWidth, height: totalHeight)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let col = Int((value.location.x - offset.width) / (cellSize + spacing))
                            let row = Int((value.location.y - offset.height) / (cellSize + spacing))
                            if row >= 0 && row < viewModel.state.height && col >= 0 && col < viewModel.state.width {
                                viewModel.applyColor(at: (row, col))
                            }
                        }
                )
            }
            .position(x: startX + totalWidth / 2, y: startY + totalHeight / 2)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(0.5, min(4.0, lastScale * value.magnitude))
                    }
                    .onEnded { _ in
                        lastScale = scale
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .onTapGesture(count: 2) {
                scale = 1.0
                lastScale = 1.0
                offset = .zero
                lastOffset = .zero
            }
        }
    }

    private func baseCellSize(for size: BeadSize) -> CGFloat {
        switch size {
        case .biggie: return 44
        case .standard: return 28
        case .mini: return 18
        }
    }
}
