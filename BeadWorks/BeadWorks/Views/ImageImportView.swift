import SwiftUI
import PhotosUI

struct ImageImportView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showPreview = false

    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            Text("选择一张图片生成拼豆底图")
                .font(.headline)

            if #available(iOS 26.0, *) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("从相册选择", systemImage: "photo")
                        .font(.headline)
                        .padding()
                }
                .buttonStyle(.glass)
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("从相册选择", systemImage: "photo")
                        .font(.headline)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            if selectedImage != nil {
                Button("下一步：调整参数") {
                    showPreview = true
                }
                .buttonStyle(MenuButtonStyle())
            }
        }
        .padding()
        .onChange(of: selectedItem) { _, newItem in
            loadTask?.cancel()
            loadTask = Task {
                do {
                    guard let item = newItem else { return }
                    let data = try await item.loadTransferable(type: Data.self)
                    guard let data, let uiImage = UIImage(data: data) else { return }
                    await MainActor.run {
                        selectedImage = uiImage
                    }
                } catch {
                    if !(error is CancellationError) {
                        print("Failed to load image: \(error)")
                    }
                }
            }
        }
        .sheet(isPresented: $showPreview) {
            if let image = selectedImage {
                NavigationStack {
                    ConversionPreviewView(image: image)
                }
            }
        }
    }
}
