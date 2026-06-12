import SwiftUI

struct BeadGridView: View {
    @ObservedObject var viewModel: CanvasViewModel
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

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

                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: viewModel.state.width),
                    spacing: spacing
                ) {
                    ForEach(0..<viewModel.state.height, id: \.self) { row in
                        ForEach(0..<viewModel.state.width, id: \.self) { col in
                            let index = viewModel.state.colorIndex(at: (row, col))
                            BeadCell(
                                color: index.flatMap { viewModel.state.colorPalette[$0] },
                                number: viewModel.state.mode == .numbered ? index.map { $0 + 1 } : nil,
                                isFused: viewModel.isFused,
                                size: cellSize
                            )
                            .onTapGesture {
                                viewModel.applyColor(at: (row, col))
                            }
                        }
                    }
                }
                .frame(width: totalWidth, height: totalHeight)
            }
            .position(x: startX + totalWidth / 2, y: startY + totalHeight / 2)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(0.5, min(4.0, value.magnitude))
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
            )
            .onTapGesture(count: 2) {
                scale = 1.0
                offset = .zero
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
