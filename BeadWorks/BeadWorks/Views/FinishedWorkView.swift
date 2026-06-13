import SwiftUI

struct FinishedWorkView: View {
    @ObservedObject var viewModel: CanvasViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)

                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 2)
                        )

                    BeadGridView(viewModel: viewModel)
                        .frame(
                            width: min(200, CGFloat(viewModel.state.width) * 28),
                            height: min(200, CGFloat(viewModel.state.height) * 28)
                        )
                }
                .padding(20)
            }
            .frame(width: 260, height: 280)

            HStack(spacing: 16) {
                glassButton("保存") { saveToAlbum() }
                glassButton("分享") { share() }
                glassButton("再做一次") { reset() }
            }
            .padding()

            Spacer()
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea())
    }

    @ViewBuilder
    private func glassButton(_ title: String, action: @escaping () -> Void) -> some View {
        if #available(iOS 26.0, *) {
            Button(title, action: action)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .buttonStyle(.glass)
        } else {
            Button(title, action: action)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    private func reset() {
        viewModel.isFused = false
    }

    private func saveToAlbum() {
        // 后续实现：把 view 渲染成 UIImage 保存
    }

    private func share() {
        // 后续实现：系统分享
    }
}
