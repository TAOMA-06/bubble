import SwiftUI
import UIKit

struct FinishedWorkView: View {
    let board: BeadBoard
    let previewImage: UIImage

    @Environment(BoardStore.self) private var boardStore
    @State private var title: String = "我的拼豆作品"
    @State private var didSave = false
    @State private var saveErrorMessage: String?
    @State private var selectedRenderStyle: BeadRenderStyle = .fullFused
    @State private var productType: FinishedProductType = .fridgeMagnet
    @State private var shareImage: UIImage?
    @State private var photoSaveMessage: String?
    @State private var isSharing = false

    var body: some View {
        ZStack {
            BeadWorksTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    VStack(spacing: 18) {
                        BeadBoardCanvas(board: board, style: selectedRenderStyle, showGuide: false)
                            .frame(maxWidth: 280)
                            .padding(12)
                            .background(BeadWorksTheme.paperBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(BeadWorksTheme.strongDivider, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
                            .accessibilityIdentifier("ironedPreviewImage")

                        VStack(spacing: 8) {
                            Picker("熨烫效果", selection: $selectedRenderStyle) {
                                ForEach(BeadRenderStyle.fusedStyles, id: \.self) { style in
                                    Text(style.label).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityIdentifier("fusionStylePicker")

                            Text(selectedRenderStyle.description)
                                .font(.caption)
                                .foregroundStyle(BeadWorksTheme.ink.opacity(0.56))
                        }

                        Picker("成品类型", selection: $productType) {
                            ForEach(FinishedProductType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("productTypePicker")

                        TextField("作品名称", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .disabled(didSave)
                            .accessibilityIdentifier("workTitleField")

                        if let saveErrorMessage {
                            Text(saveErrorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                        if let photoSaveMessage {
                            Text(photoSaveMessage)
                                .font(.footnote)
                                .foregroundStyle(BeadWorksTheme.ink.opacity(0.6))
                        }

                        saveButton
                        shareButtons
                    }
                    .padding(24)
                    .beadPanel(cornerRadius: BeadWorksTheme.panelCornerRadius, fill: BeadWorksTheme.paperBackground)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
        }
        .navigationTitle("成品")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BeadWorksTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isSharing) {
            if let shareImage {
                ShareSheet(items: [shareImage])
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("熨烫完成！")
                .font(.title2.bold())
                .foregroundStyle(BeadWorksTheme.ink)
            Text("塑料珠已经融合成一块手作像素板")
                .font(.footnote)
                .foregroundStyle(BeadWorksTheme.ink.opacity(0.5))
        }
    }

    private var saveButton: some View {
        let label = didSave ? "已保存到作品库" : "保存到作品库"
        return Button(action: save) {
            Label(label, systemImage: didSave ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .tint(didSave ? Color(hex: "#43A047") : BeadWorksTheme.accent)
        .disabled(didSave || title.trimmingCharacters(in: .whitespaces).isEmpty)
        .accessibilityIdentifier("saveWorkButton")
        .accessibilityLabel(label)
    }

    private var shareButtons: some View {
        HStack(spacing: 12) {
            Button {
                shareImage = makeShareImage()
                isSharing = true
            } label: {
                Label("分享", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("shareWorkButton")

            Button {
                Task { await saveToPhotos() }
            } label: {
                Label("存相册", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("saveToPhotosButton")
        }
    }

    private func save() {
        do {
            try boardStore.save(
                board: board,
                title: title.trimmingCharacters(in: .whitespaces),
                previewImage: renderedPreviewImage() ?? previewImage,
                productType: productType,
                renderStyle: selectedRenderStyle
            )
            didSave = true
            saveErrorMessage = nil
            boardStore.clearDraft()
        } catch {
            saveErrorMessage = "保存失败，请重试"
        }
    }

    private func saveToPhotos() async {
        let image = makeShareImage()
        do {
            try await PhotoLibraryService.save(image)
            photoSaveMessage = "已保存到系统相册"
        } catch PhotoLibraryServiceError.denied {
            photoSaveMessage = "没有相册权限，请在设置中允许写入"
        } catch {
            photoSaveMessage = "保存到相册失败，请重试"
        }
    }

    private func renderedPreviewImage() -> UIImage? {
        let renderer = ImageRenderer(content: IroningRenderView(board: board, style: selectedRenderStyle))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private func makeShareImage() -> UIImage {
        let boardImage = renderedPreviewImage() ?? previewImage
        return ShareImageService.composeCard(
            boardImage: boardImage,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "我的拼豆作品" : title,
            beadCount: board.filledCount,
            width: board.width,
            height: board.height,
            productType: productType
        )
    }
}
