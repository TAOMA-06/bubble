import SwiftUI

struct ConversionPreviewView: View {
    let image: UIImage
    @State private var beadSize: BeadSize = .standard
    @State private var gridSize: Int = BeadSize.standard.defaultGridSize
    @State private var colorCount: Int = 8
    @State private var mode: CanvasMode = .numbered
    @State private var isConverting = false
    @State private var result: BeadConversionResult?
    @State private var showCanvas = false

    var body: some View {
        Form {
            Section("珠粒尺寸") {
                Picker("尺寸", selection: $beadSize) {
                    ForEach(BeadSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: beadSize) { _, new in
                    gridSize = new.defaultGridSize
                }
            }

            Section("网格尺寸") {
                Stepper("\(gridSize) × \(gridSize)", value: $gridSize, in: beadSize.gridRange)
            }

            Section("颜色数量") {
                Picker("颜色数", selection: $colorCount) {
                    Text("4").tag(4)
                    Text("8").tag(8)
                    Text("16").tag(16)
                    Text("24").tag(24)
                }
                .pickerStyle(.segmented)
            }

            Section("模式") {
                Picker("模式", selection: $mode) {
                    Text("真实模式").tag(CanvasMode.numbered)
                    Text("自由模式").tag(CanvasMode.free)
                }
                .pickerStyle(.segmented)
            }

            Button("生成底图") {
                convert()
            }
            .disabled(isConverting)
        }
        .navigationTitle("转换参数")
        .navigationDestination(isPresented: $showCanvas) {
            if let result {
                let palette = mode == .numbered ? result.colors : result.colors
                let state = CanvasState(
                    id: UUID(),
                    width: gridSize,
                    height: gridSize,
                    beadSize: beadSize,
                    mode: mode,
                    colorPalette: palette,
                    cells: result.indices.map { $0.map { $0 >= 0 ? $0 : nil } },
                    createdAt: Date(),
                    updatedAt: Date()
                )
                CanvasView(viewModel: CanvasViewModel(state: state))
            }
        }
    }

    private func convert() {
        isConverting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let palette = BeadPaletteRepository.shared.defaultPalette()
            let conversion = ImageToBeadConverter().convert(
                image: image,
                width: gridSize,
                height: gridSize,
                colorCount: colorCount,
                palette: palette
            )
            DispatchQueue.main.async {
                self.result = conversion
                self.isConverting = false
                self.showCanvas = true
            }
        }
    }
}
