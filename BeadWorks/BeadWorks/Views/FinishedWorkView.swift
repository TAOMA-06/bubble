import SwiftUI

struct FinishedWorkView: View {
    @ObservedObject var viewModel: CanvasViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            BeadWorksCard {
                VStack(spacing: 16) {
                    // 挂件图标
                    if let accessory = viewModel.selectedAccessory {
                        Image(systemName: accessory.iconName)
                            .font(.system(size: 28))
                            .foregroundStyle(BeadWorksColor.accent)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // 作品展示
                    BeadGridView(viewModel: viewModel)
                        .frame(
                            width: min(200, CGFloat(viewModel.state.width) * 28),
                            height: min(200, CGFloat(viewModel.state.height) * 28)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    // 作品信息
                    VStack(spacing: 4) {
                        Text("作品完成！")
                            .font(BeadWorksFont.headline())
                            .foregroundStyle(BeadWorksColor.textPrimary)
                        
                        Text("\(viewModel.state.width) × \(viewModel.state.height) 拼豆")
                            .font(BeadWorksFont.caption())
                            .foregroundStyle(BeadWorksColor.textSecondary)
                    }
                }
            }
            .frame(width: 280)
            
            // 操作按钮
            HStack(spacing: 16) {
                BeadWorksButton(
                    title: "保存",
                    icon: "square.and.arrow.down",
                    style: .secondary
                ) {
                    saveToAlbum()
                }
                
                BeadWorksButton(
                    title: "分享",
                    icon: "square.and.arrow.up",
                    style: .accent
                ) {
                    share()
                }
            }
            .padding(.horizontal, 24)
            
            BeadWorksButton(
                title: "再做一次",
                icon: "arrow.counterclockwise",
                style: .primary
            ) {
                reset()
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(
            BeadWorksColor.background
                .opacity(0.95)
                .ignoresSafeArea()
        )
    }

    private func reset() {
        viewModel.reset()
    }

    private func saveToAlbum() {
        // 后续实现：把 view 渲染成 UIImage 保存
    }

    private func share() {
        // 后续实现：系统分享
    }
}
