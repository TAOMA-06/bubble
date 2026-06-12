import SwiftUI

struct MainMenuView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Text("拼豆工坊")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Button("自由创作") { path.append(MainRoute.freeCreation) }
                    .buttonStyle(MenuButtonStyle())

                Button("图片转拼豆") { path.append(MainRoute.imageImport) }
                    .buttonStyle(MenuButtonStyle())

                Button("我的作品") { path.append(MainRoute.gallery) }
                    .buttonStyle(MenuButtonStyle())
            }
            .padding()
            .navigationDestination(for: MainRoute.self) { route in
                switch route {
                case .freeCreation:
                    CanvasView(viewModel: CanvasViewModel(state: .empty(
                        width: BeadSize.standard.defaultGridSize,
                        height: BeadSize.standard.defaultGridSize,
                        beadSize: .standard
                    )))
                case .imageImport:
                    ImageImportView()
                case .gallery:
                    Text("我的作品（占位）")
                }
            }
        }
    }
}

enum MainRoute: Hashable {
    case freeCreation
    case imageImport
    case gallery
}

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: 240)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
