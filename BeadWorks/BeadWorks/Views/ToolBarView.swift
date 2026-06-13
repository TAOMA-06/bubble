import SwiftUI

struct ToolBarView: View {
    @ObservedObject var viewModel: CanvasViewModel
    var onFinish: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if #available(iOS 26.0, *) {
                Button("撤销", action: viewModel.undo)
                    .fontWeight(.regular)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .buttonStyle(.glass)
                
                Button("重做", action: viewModel.redo)
                    .fontWeight(.regular)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .buttonStyle(.glass)
                
                Button("清空", action: viewModel.clear)
                    .fontWeight(.regular)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .buttonStyle(.glass)
                
                Button("完成", action: onFinish)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .buttonStyle(.glassProminent)
            } else {
                Button("撤销", action: viewModel.undo)
                    .fontWeight(.regular)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Button("重做", action: viewModel.redo)
                    .fontWeight(.regular)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Button("清空", action: viewModel.clear)
                    .fontWeight(.regular)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Button("完成", action: onFinish)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
