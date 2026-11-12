import PhotosUI
import SwiftUI

struct PhotoImportView: View {
    @Binding var path: NavigationPath
    @State private var model = PhotoImportViewModel()

    var body: some View {
        ZStack {
            BeadWorksTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    if let pattern = model.pattern {
                        previewSection(pattern: pattern)
                    } else {
                        pickerSection
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("导入图片")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BeadWorksTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: model.selectedItem) { _, newItem in
            Task { await model.loadImage(from: newItem) }
        }
        .onChange(of: model.gridSize) { _, _ in
            Task { await model.regenerate() }
        }
    }

    private var pickerSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                BeadMark(diameter: 10, spacing: 5, padding: 10)
                VStack(alignment: .leading, spacing: 4) {
                    Text("照片变拼豆模板")
                        .font(.headline)
                        .foregroundStyle(BeadWorksTheme.ink)
                    Text("裁成正方形，再映射到固定珠色")
                        .font(.caption)
                        .foregroundStyle(BeadWorksTheme.ink.opacity(0.58))
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                MaterialNote(text: "居中裁剪", systemImage: "crop")
                MaterialNote(text: "就近取色", systemImage: "paintpalette.fill")
                MaterialNote(text: "一孔一珠", systemImage: "circle.grid.3x3.fill")
            }

            VStack(spacing: 12) {
                PhotosPicker(selection: $model.selectedItem, matching: .images) {
                    Label("选择照片", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(BeadWorksTheme.accent)
                .accessibilityIdentifier("choosePhotoButton")

                if model.isUITestFixtureEnabled {
                    Button {
                        Task { await model.loadFixtureImage() }
                    } label: {
                        Label("使用测试图片", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("useFixtureImageButton")
                }

                if model.isLoading {
                    ProgressView()
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(22)
        .beadPanel(cornerRadius: BeadWorksTheme.panelCornerRadius, fill: BeadWorksTheme.paperBackground)
        .padding(.top, 40)
    }

    private func previewSection(pattern: BeadPattern) -> some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("\(pattern.size)×\(pattern.size) 拼豆模板")
                    .font(.headline)
                    .foregroundStyle(BeadWorksTheme.ink)
                Text("预览是摆满珠子的效果，进入后可逐颗调整。")
                    .font(.caption)
                    .foregroundStyle(BeadWorksTheme.ink.opacity(0.56))
            }

            BeadBoardCanvas(board: pattern.previewBoard, style: .editing, showGuide: false)
                .frame(maxWidth: 300)
                .padding(10)
                .pegboardPanel(cornerRadius: 16)
                .accessibilityIdentifier("templatePreviewCanvas")

            Picker("尺寸", selection: $model.gridSize) {
                ForEach(PhotoTemplateService.supportedSizes, id: \.self) { size in
                    Text("\(size)×\(size) 模板").tag(size)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("templateSizePicker")

            if model.isLoading {
                ProgressView()
            }

            HStack(spacing: 12) {
                Button {
                    model.reset()
                } label: {
                    Label("重新选择", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("retakePhotoButton")

                Button {
                    path.append(Route.editor(.template(pattern: pattern)))
                } label: {
                    Label("开始拼豆", systemImage: "paintpalette.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(BeadWorksTheme.accent)
                .accessibilityIdentifier("startFromTemplateButton")
            }
        }
        .padding(22)
        .beadPanel(cornerRadius: BeadWorksTheme.panelCornerRadius, fill: BeadWorksTheme.paperBackground)
        .padding(.top, 24)
    }
}
