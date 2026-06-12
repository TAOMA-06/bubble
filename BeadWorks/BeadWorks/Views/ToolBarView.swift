import SwiftUI

struct ToolBarView: View {
    @ObservedObject var viewModel: CanvasViewModel
    var onFinish: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            Button("撤销") { viewModel.undo() }
            Button("重做") { viewModel.redo() }
            Button("清空") { viewModel.clear() }
            Button("完成") { onFinish() }
                .fontWeight(.bold)
        }
        .padding()
    }
}
