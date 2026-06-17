import SwiftUI

struct CanvasView: View {
    @StateObject var viewModel: CanvasViewModel

    var body: some View {
        VStack(spacing: 0) {
            ColorPaletteBar(viewModel: viewModel)

            BeadGridView(viewModel: viewModel)
                .background(BeadWorksColor.canvasBackground)
        }
        .background(BeadWorksColor.background)
        .overlay(alignment: .bottom) {
            if viewModel.ironingPhase == .idle {
                ToolBarView(viewModel: viewModel, onFinish: { viewModel.finish() })
            }
        }
        .overlay {
            switch viewModel.ironingPhase {
            case .ironing:
                Color.black.opacity(0.15).ignoresSafeArea()
                    .overlay {
                        IroningAnimationView(isComplete: .init(
                            get: { false },
                            set: { if $0 { viewModel.onIroningComplete() } }
                        ))
                    }
                    .transition(.opacity)

            case .choosingAccessory:
                Color.black.opacity(0.3).ignoresSafeArea()
                    .overlay {
                        AccessoryPickerView { accessory in
                            viewModel.selectAccessory(accessory)
                        }
                    }
                    .transition(.opacity)

            case .attaching(let accessory):
                Color.black.opacity(0.15).ignoresSafeArea()
                    .overlay {
                        AccessoryAttachAnimation(
                            accessory: accessory,
                            isComplete: .init(
                                get: { false },
                                set: { if $0 { viewModel.onAttachComplete() } }
                            )
                        )
                    }
                    .transition(.opacity)

            case .done:
                FinishedWorkView(viewModel: viewModel)
                    .transition(.opacity.combined(with: .scale))

            case .idle:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.ironingPhase)
    }
}
