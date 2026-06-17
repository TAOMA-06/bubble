import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .create
    @State private var createPath = NavigationPath()
    @State private var importPath = NavigationPath()
    @State private var galleryPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $createPath) {
                FreeCreationSetupView { side in
                    createPath.append(MainRoute.freeCanvas(side: side))
                }
                .navigationDestination(for: MainRoute.self) { route in
                    switch route {
                    case .freeCanvas(let side):
                        CanvasView(viewModel: CanvasViewModel(state: .empty(
                            width: side,
                            height: side,
                            beadSize: .custom
                        )))
                        .toolbar(.hidden, for: .tabBar)
                    }
                }
            }
            .tabItem {
                Label("自由创作", systemImage: "paintpalette.fill")
            }
            .tag(AppTab.create)

            NavigationStack(path: $importPath) {
                ImageImportView()
                    .navigationTitle("图片转拼豆")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("图片转拼豆", systemImage: "photo.fill")
            }
            .tag(AppTab.imageImport)

            NavigationStack(path: $galleryPath) {
                GalleryPlaceholderView()
                    .navigationTitle("我的作品")
            }
            .tabItem {
                Label("我的作品", systemImage: "rectangle.stack.fill")
            }
            .tag(AppTab.gallery)
        }
        .tint(BeadWorksColor.accent)
    }
}

enum AppTab: Hashable {
    case create
    case imageImport
    case gallery
}

private struct GalleryPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(BeadWorksColor.accentPurple)

            Text("我的作品")
                .font(BeadWorksFont.headline())
                .foregroundStyle(BeadWorksColor.textPrimary)

            Text("完成的拼豆作品会出现在这里")
                .font(BeadWorksFont.body())
                .foregroundStyle(BeadWorksColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BeadWorksColor.background)
    }
}
