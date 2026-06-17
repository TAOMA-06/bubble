import SwiftUI
import PhotosUI

struct ImageImportView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showPreview = false

    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(BeadWorksColor.accentGreen)
                
                Text("选择一张图片生成拼豆底图")
                    .font(BeadWorksFont.headline())
                    .foregroundStyle(BeadWorksColor.textPrimary)
                
                Text("从相册选择图片，转换为拼豆图案")
                    .font(BeadWorksFont.body())
                    .foregroundStyle(BeadWorksColor.textSecondary)
            }
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("从相册选择", systemImage: "photo")
                    .font(BeadWorksFont.button())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .controlSize(.large)
            .buttonBorderShape(.capsule)
            .tint(BeadWorksColor.accentGreen)
            .buttonStyle(.glassProminent)
            .padding(.horizontal, 24)
            
            if selectedImage != nil {
                BeadWorksButton(
                    title: "下一步：调整参数",
                    icon: "arrow.right",
                    style: .primary
                ) {
                    showPreview = true
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .background(BeadWorksColor.background)
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
