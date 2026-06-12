import SwiftUI

// Placeholder stubs — real implementations in later tasks
struct CanvasView: View {
    @StateObject var viewModel: CanvasViewModel
    var body: some View { Text("Canvas (placeholder)") }
}

@MainActor
final class CanvasViewModel: ObservableObject {
    @Published var state: CanvasState
    init(state: CanvasState) { self.state = state }
}

struct ImageImportView: View {
    var body: some View { Text("Image Import (placeholder)") }
}
