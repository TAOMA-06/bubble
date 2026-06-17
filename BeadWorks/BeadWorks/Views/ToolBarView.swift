import SwiftUI

struct ToolBarView: View {
    @ObservedObject var viewModel: CanvasViewModel
    var onFinish: () -> Void

    var body: some View {
        BeadWorksGlassToolbar {
            HStack(spacing: 12) {
                BeadWorksGlassButton(
                    title: "撤销",
                    icon: "arrow.uturn.backward",
                    action: viewModel.undo
                )
                
                BeadWorksGlassButton(
                    title: "重做",
                    icon: "arrow.uturn.forward",
                    action: viewModel.redo
                )
                
                BeadWorksGlassButton(
                    title: "清空",
                    icon: "trash",
                    action: viewModel.clear
                )

                BeadWorksGlassButton(
                    title: viewModel.isPanMode ? "移动" : "绘制",
                    icon: viewModel.isPanMode ? "hand.draw" : "paintbrush.pointed",
                    isSelected: viewModel.isPanMode,
                    action: { viewModel.isPanMode.toggle() }
                )
                
                BeadWorksToolbarButton(
                    title: "完成",
                    icon: "checkmark.circle.fill",
                    isPrimary: true,
                    action: onFinish
                )
            }
        }
        .padding()
    }
}
