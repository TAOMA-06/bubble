import SwiftUI

struct CanvasView: View {
    @StateObject var viewModel: CanvasViewModel

    var body: some View {
        VStack(spacing: 0) {
            ColorPaletteBar(viewModel: viewModel)
                .background(Color(.systemBackground))

            BeadGridView(viewModel: viewModel)
                .background(Color(.systemGray5))

            ToolBarView(viewModel: viewModel, onFinish: { viewModel.finish() })
                .background(Color(.systemBackground))
        }
        .overlay {
            if viewModel.isFused {
                FinishedWorkView(viewModel: viewModel)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.isFused)
    }
}
