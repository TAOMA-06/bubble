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
                        .frame(width: 200, height: 200)
                }
                .padding(20)
            }
            .frame(width: 260, height: 280)

            HStack(spacing: 16) {
                Button("保存") { saveToAlbum() }
                Button("分享") { share() }
                Button("再做一次") { viewModel.isFused = false }
            }
            .padding()

            Spacer()
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea())
    }

    private func saveToAlbum() {
        // 后续实现：把 view 渲染成 UIImage 保存
    }

    private func share() {
        // 后续实现：系统分享
    }
}
