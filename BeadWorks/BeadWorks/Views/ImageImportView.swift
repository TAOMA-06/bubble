import SwiftUI
import PhotosUI

struct ImageImportView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showPreview = false

    var body: some View {
        VStack(spacing: 20) {
            Text("选择一张图片生成拼豆底图")
                .font(.headline)

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("从相册选择", systemImage: "photo")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
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
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                selectedImage = uiImage
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
