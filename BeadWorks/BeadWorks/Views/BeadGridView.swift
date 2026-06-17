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
        let cellPx = baseCellSize * scale + spacing

        GeometryReader { geo in
            let totalWidth = CGFloat(viewModel.state.width) * cellPx
            let totalHeight = CGFloat(viewModel.state.height) * cellPx
            let rawStartX = max(0, (geo.size.width - totalWidth) / 2) + offset.width
            let rawStartY = max(0, (geo.size.height - totalHeight) / 2) + offset.height
            let visible = visibleRange(
                viewportSize: geo.size,
                rawStartX: rawStartX,
                rawStartY: rawStartY,
                cellPx: cellPx,
                width: viewModel.state.width,
                height: viewModel.state.height
            )

            ZStack {
                PegboardBackground(
                    rows: viewModel.state.height,
                    cols: viewModel.state.width,
                    cellSize: baseCellSize * scale,
                    visibleMinRow: visible.minRow,
                    visibleMaxRow: visible.maxRow,
                    visibleMinCol: visible.minCol,
                    visibleMaxCol: visible.maxCol
                )
                .frame(width: totalWidth, height: totalHeight)

                Canvas { context, size in
                    let cellSize = baseCellSize * scale
                    let showDetail = cellSize >= 6
                    for row in visible.minRow..<visible.maxRow {
                        for col in visible.minCol..<visible.maxCol {
                            let x = CGFloat(col) * cellPx
                            let y = CGFloat(row) * cellPx
                            let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                            let index = viewModel.state.colorIndex(at: (row, col))
                            let color = index.flatMap { idx in
                                viewModel.state.colorPalette.indices.contains(idx)
                                    ? viewModel.state.colorPalette[idx]
                                    : nil
                            }

                            if let color {
                                if showDetail {
                                    let shadowRect = CGRect(x: x + cellSize * 0.08, y: y + cellSize * 0.75,
                                                            width: cellSize * 0.84, height: cellSize * 0.15)
                                    context.fill(Path(ellipseIn: shadowRect), with: .color(.black.opacity(0.2)))

                                    let outerRect = CGRect(x: x + cellSize * 0.06, y: y + cellSize * 0.06,
                                                           width: cellSize * 0.88, height: cellSize * 0.88)
                                    context.fill(Path(ellipseIn: outerRect), with: .color(color.swiftUIColor))

                                    let highlightRect = CGRect(x: x + cellSize * 0.18, y: y + cellSize * 0.12,
                                                               width: cellSize * 0.45, height: cellSize * 0.32)
                                    context.fill(Path(ellipseIn: highlightRect), with: .color(.white.opacity(0.45)))

                                    let holeRect = CGRect(x: x + cellSize * 0.29, y: y + cellSize * 0.29,
                                                          width: cellSize * 0.42, height: cellSize * 0.42)
                                    context.fill(Path(ellipseIn: holeRect), with: .color(Color(.systemGray4)))

                                    context.stroke(Path(ellipseIn: holeRect),
                                                   with: .color(.black.opacity(0.35)),
                                                   lineWidth: cellSize * 0.05)

                                    context.stroke(Path(ellipseIn: outerRect),
                                                   with: .color(color.swiftUIColor.opacity(0.65)),
                                                   lineWidth: cellSize * 0.04)
                                } else {
                                    context.fill(Path(rect), with: .color(color.swiftUIColor))
                                }
                            } else if showDetail {
                                let path = RoundedRectangle(cornerRadius: cellSize * 0.18).path(in: rect)
                                context.fill(path, with: .color(Color(.systemGray6)))

                                let holeRect = CGRect(
                                    x: x + cellSize * 0.375,
                                    y: y + cellSize * 0.375,
                                    width: cellSize * 0.25,
                                    height: cellSize * 0.25
                                )
                                context.fill(Path(ellipseIn: holeRect), with: .color(Color(.systemGray4)))
                            }

                            if showDetail && viewModel.state.mode == .numbered, let index {
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
            }
            .position(x: rawStartX + totalWidth / 2, y: rawStartY + totalHeight / 2)
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        scale = max(0.1, min(8.0, lastScale * value.magnification))
                    }
                    .onEnded { _ in
                        lastScale = scale
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if viewModel.isPanMode {
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        } else {
                            let col = Int(value.location.x / cellPx)
                            let row = Int(value.location.y / cellPx)
                            if row >= 0 && row < viewModel.state.height && col >= 0 && col < viewModel.state.width {
                                viewModel.applyColor(at: (row, col))
                            }
                        }
                    }
                    .onEnded { _ in
                        if viewModel.isPanMode {
                            lastOffset = offset
                        }
                    }
            )
        }
    }

    private func baseCellSize(for size: BeadSize) -> CGFloat {
        switch size {
        case .biggie: return 44
        case .standard: return 28
        case .mini: return 18
        case .custom: return 28
        }
    }

    private func visibleRange(
        viewportSize: CGSize,
        rawStartX: CGFloat,
        rawStartY: CGFloat,
        cellPx: CGFloat,
        width: Int,
        height: Int
    ) -> (minRow: Int, maxRow: Int, minCol: Int, maxCol: Int) {
        guard cellPx > 0, width > 0, height > 0 else {
            return (0, height, 0, width)
        }

        let minCol = max(0, Int(floor((0 - rawStartX) / cellPx)) - 1)
        let maxCol = min(width, Int(ceil((viewportSize.width - rawStartX) / cellPx)) + 1)
        let minRow = max(0, Int(floor((0 - rawStartY) / cellPx)) - 1)
        let maxRow = min(height, Int(ceil((viewportSize.height - rawStartY) / cellPx)) + 1)
        return (minRow, maxRow, minCol, maxCol)
    }
}
