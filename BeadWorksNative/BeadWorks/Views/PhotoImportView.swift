import PhotosUI
import SwiftUI

struct PhotoImportView: View {
    @Binding var path: NavigationPath

    @State private var selectedItem: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var gridSize: Int = PhotoTemplateService.defaultSize
    @State private var pattern: BeadPattern?
    @State private var isLoading = false
    @State private var errorMessage: String?

    /// When the app is launched with `-uiTestFixtureImage`, an extra button generates a small
    /// synthetic image in-process instead of opening the system Photos picker. UI tests can't
    /// reliably drive the system picker (it runs out-of-process and depends on simulator photo
    /// library seeding), so this keeps the "import a photo" flow deterministically testable
    /// without checking a binary fixture image into the repo.
    private var isUITestFixtureEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTestFixtureImage")
    }

    var body: some View {
        ZStack {
            BeadWorksTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    if let pattern {
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
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
        .onChange(of: gridSize) { _, _ in
            regenerate()
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
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("选择照片", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(BeadWorksTheme.accent)
                .accessibilityIdentifier("choosePhotoButton")

                if isUITestFixtureEnabled {
                    Button {
                        Task { await loadFixtureImage() }
                    } label: {
                        Label("使用测试图片", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("useFixtureImageButton")
                }

                if isLoading {
                    ProgressView()
                }

                if let errorMessage {
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

            BeadBoardCanvas(
                board: BeadBoard(width: pattern.size, height: pattern.size, cells: pattern.cells),
                style: .editing
            )
            .frame(maxWidth: 300)
            .padding(10)
            .pegboardPanel(cornerRadius: 16)
            .accessibilityIdentifier("templatePreviewCanvas")

            Picker("尺寸", selection: $gridSize) {
                ForEach(PhotoTemplateService.supportedSizes, id: \.self) { size in
                    Text("\(size)×\(size) 模板").tag(size)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("templateSizePicker")

            HStack(spacing: 12) {
                Button {
                    reset()
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

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                errorMessage = "无法读取所选照片"
                return
            }
            sourceImage = image
            regenerate()
        } catch {
            errorMessage = "读取照片失败，请重试"
        }
    }

    private func loadFixtureImage() async {
        sourceImage = Self.makeFixtureImage()
        regenerate()
    }

    private func regenerate() {
        guard let sourceImage else { return }
        do {
            pattern = try PhotoTemplateService.makePattern(from: sourceImage, gridSize: gridSize)
            errorMessage = nil
        } catch {
            errorMessage = "生成拼豆模板失败"
        }
    }

    private func reset() {
        pattern = nil
        sourceImage = nil
        selectedItem = nil
        errorMessage = nil
    }

    private static func makeFixtureImage() -> UIImage {
        let tile = 16
        let size = CGSize(width: tile * 4, height: tile * 4)
        let renderer = UIGraphicsImageRenderer(size: size)
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow]
        return renderer.image { _ in
            for row in 0..<4 {
                for col in 0..<4 {
                    colors[(row + col) % colors.count].setFill()
                    UIRectFill(CGRect(x: col * tile, y: row * tile, width: tile, height: tile))
                }
            }
        }
    }
}
