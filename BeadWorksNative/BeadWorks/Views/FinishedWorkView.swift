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

    var body: some View {
        ZStack {
            BeadWorksTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    VStack(spacing: 18) {
                        BeadBoardCanvas(board: board, style: selectedRenderStyle)
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

                        TextField("作品名称", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .disabled(didSave)
                            .accessibilityIdentifier("workTitleField")

                        if let saveErrorMessage {
                            Text(saveErrorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        saveButton
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
        // Explicit override so the icon added above never changes the computed accessibility
        // label away from the exact "已保存到作品库" / "保存到作品库" strings UI tests assert on.
        .accessibilityLabel(label)
    }

    private func save() {
        do {
            try boardStore.save(
                board: board,
                title: title.trimmingCharacters(in: .whitespaces),
                previewImage: renderedPreviewImage() ?? previewImage
            )
            didSave = true
            saveErrorMessage = nil
        } catch {
            saveErrorMessage = "保存失败，请重试"
        }
    }

    private func renderedPreviewImage() -> UIImage? {
        let renderer = ImageRenderer(content: IroningRenderView(board: board, style: selectedRenderStyle))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
