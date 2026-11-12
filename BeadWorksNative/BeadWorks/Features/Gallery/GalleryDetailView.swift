import SwiftUI
import UIKit

struct GalleryDetailView: View {
    let work: GalleryWork
    @Binding var path: NavigationPath
    @Environment(BoardStore.self) private var boardStore
    @State private var shareImage: UIImage?
    @State private var isSharing = false

    var body: some View {
        ZStack {
            BeadWorksTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    if let image = boardStore.previewImage(for: work) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .background(BeadWorksTheme.paperBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .accessibilityIdentifier("galleryDetailPreview")
                    } else {
                        BeadBoardCanvas(board: work.board, style: work.renderStyle ?? .fullFused, showGuide: false)
                            .padding(12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(work.title)
                            .font(.title2.bold())
                            .foregroundStyle(BeadWorksTheme.ink)
                        HStack(spacing: 8) {
                            MaterialNote(text: "\(work.width)×\(work.height)", systemImage: "square.grid.3x3")
                            MaterialNote(text: "\(work.filledCount) 颗", systemImage: "circle.grid.3x3.fill")
                            MaterialNote(text: work.productType.displayName, systemImage: work.productType.systemImage)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        path.append(Route.editor(.restored(board: work.board, title: work.title)))
                    } label: {
                        Label("重新编辑", systemImage: "paintbrush.pointed.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BeadWorksTheme.accent)
                    .accessibilityIdentifier("reopenWorkButton")

                    Button {
                        shareImage = makeShareImage()
                        isSharing = true
                    } label: {
                        Label("分享", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("galleryShareButton")

                    Button(role: .destructive) {
                        boardStore.delete(work)
                        path.removeLast()
                    } label: {
                        Label("删除作品", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("deleteWorkButton")
                }
                .padding(24)
                .beadPanel(cornerRadius: BeadWorksTheme.panelCornerRadius, fill: BeadWorksTheme.paperBackground)
                .padding(20)
            }
        }
        .navigationTitle("作品")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isSharing) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    private func makeShareImage() -> UIImage {
        let boardImage = boardStore.previewImage(for: work) ?? UIImage()
        return ShareImageService.composeCard(
            boardImage: boardImage,
            title: work.title,
            beadCount: work.filledCount,
            width: work.width,
            height: work.height,
            productType: work.productType,
            date: work.createdAt
        )
    }
}
