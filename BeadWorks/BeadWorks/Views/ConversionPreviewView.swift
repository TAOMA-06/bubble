import SwiftUI

struct ConversionPreviewView: View {
    let image: UIImage
    @State private var beadSize: BeadSize = .standard
    @State private var gridWidth: Int = BeadSize.standard.defaultGridSize
    @State private var gridHeight: Int = BeadSize.standard.defaultGridSize
    @State private var widthInput: String = "\(BeadSize.standard.defaultGridSize)"
    @State private var heightInput: String = "\(BeadSize.standard.defaultGridSize)"
    @State private var colorCount: Int = 8
    @State private var mode: CanvasMode = .numbered
    @State private var isConverting = false
    @State private var result: BeadConversionResult?
    @State private var showCanvas = false
    @State private var conversionTask: Task<Void, Never>?
    @FocusState private var focusedGridField: GridField?

    private let minGrid = 8
    private let maxGrid = 640

    private enum GridField: Hashable {
        case width, height
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                BeadWorksCard {
                    VStack(spacing: 12) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text("原图预览")
                            .font(BeadWorksFont.caption())
                            .foregroundStyle(BeadWorksColor.textSecondary)
                    }
                }
                .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    BeadWorksCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("珠粒尺寸")
                                .font(BeadWorksFont.headline())
                                .foregroundStyle(BeadWorksColor.textPrimary)

                            Picker("尺寸", selection: $beadSize) {
                                ForEach(BeadSize.allCases, id: \.self) { size in
                                    Text(size.displayName).tag(size)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: beadSize) { _, new in
                                dismissKeyboard()
                                gridWidth = new.defaultGridSize
                                gridHeight = new.defaultGridSize
                                widthInput = "\(gridWidth)"
                                heightInput = "\(gridHeight)"
                            }
                        }
                    }

                    BeadWorksCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("网格尺寸")
                                .font(BeadWorksFont.headline())
                                .foregroundStyle(BeadWorksColor.textPrimary)

                            if beadSize == .custom {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("宽度")
                                            .font(BeadWorksFont.caption())
                                            .foregroundStyle(BeadWorksColor.textSecondary)
                                        TextField("8-640", text: $widthInput)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.center)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 80)
                                            .focused($focusedGridField, equals: .width)
                                            .onChange(of: widthInput) { _, newValue in
                                                let digits = newValue.filter(\.isNumber)
                                                if digits != newValue {
                                                    widthInput = digits
                                                }
                                            }
                                    }
                                    Text("×")
                                        .font(BeadWorksFont.headline())
                                        .padding(.top, 16)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("高度")
                                            .font(BeadWorksFont.caption())
                                            .foregroundStyle(BeadWorksColor.textSecondary)
                                        TextField("8-640", text: $heightInput)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.center)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 80)
                                            .focused($focusedGridField, equals: .height)
                                            .onChange(of: heightInput) { _, newValue in
                                                let digits = newValue.filter(\.isNumber)
                                                if digits != newValue {
                                                    heightInput = digits
                                                }
                                            }
                                    }
                                    Spacer()
                                }

                                Text("最高 640 × 640")
                                    .font(BeadWorksFont.caption())
                                    .foregroundStyle(BeadWorksColor.textSecondary)
                            } else {
                                HStack {
                                    Text("\(gridWidth) × \(gridHeight)")
                                        .font(BeadWorksFont.body())
                                        .foregroundStyle(BeadWorksColor.textPrimary)

                                    Spacer()

                                    Stepper("宽", value: $gridWidth, in: beadSize.gridRange)
                                        .labelsHidden()
                                    Text("×")
                                    Stepper("高", value: $gridHeight, in: beadSize.gridRange)
                                        .labelsHidden()
                                }
                            }
                        }
                    }

                    BeadWorksCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("颜色数量")
                                .font(BeadWorksFont.headline())
                                .foregroundStyle(BeadWorksColor.textPrimary)

                            Picker("颜色数", selection: $colorCount) {
                                Text("4").tag(4)
                                Text("8").tag(8)
                                Text("16").tag(16)
                                Text("24").tag(24)
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    BeadWorksCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("模式")
                                .font(BeadWorksFont.headline())
                                .foregroundStyle(BeadWorksColor.textPrimary)

                            Picker("模式", selection: $mode) {
                                Text("真实模式").tag(CanvasMode.numbered)
                                Text("自由模式").tag(CanvasMode.free)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .padding(.horizontal, 24)

                BeadWorksButton(
                    title: isConverting ? "生成中..." : "生成底图",
                    icon: isConverting ? nil : "sparkles",
                    style: .primary
                ) {
                    dismissKeyboard()
                    convert()
                }
                .disabled(isConverting)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .background(BeadWorksColor.background)
        .navigationTitle("转换参数")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    dismissKeyboard()
                }
            }
        }
        .navigationDestination(isPresented: $showCanvas) {
            if let result {
                CanvasView(viewModel: CanvasViewModel(state: canvasState(from: result)))
            }
        }
    }

    private func dismissKeyboard() {
        commitGridDimensions()
        focusedGridField = nil
    }

    private func commitGridDimensions() {
        if beadSize == .custom {
            let width = Int(widthInput) ?? gridWidth
            let height = Int(heightInput) ?? gridHeight
            gridWidth = min(max(width, minGrid), maxGrid)
            gridHeight = min(max(height, minGrid), maxGrid)
            widthInput = "\(gridWidth)"
            heightInput = "\(gridHeight)"
        } else {
            gridWidth = min(max(gridWidth, beadSize.gridRange.lowerBound), beadSize.gridRange.upperBound)
            gridHeight = min(max(gridHeight, beadSize.gridRange.lowerBound), beadSize.gridRange.upperBound)
        }
    }

    private func canvasState(from result: BeadConversionResult) -> CanvasState {
        let palette = result.colors
        var flatCells = [UInt8](repeating: 0, count: gridWidth * gridHeight)
        for (r, row) in result.indices.enumerated() {
            for (c, val) in row.enumerated() {
                if r < gridHeight && c < gridWidth {
                    flatCells[r * gridWidth + c] = UInt8(val + 1)
                }
            }
        }
        return CanvasState(
            id: UUID(),
            width: gridWidth,
            height: gridHeight,
            beadSize: beadSize,
            mode: mode,
            colorPalette: palette,
            cells: flatCells,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func convert() {
        commitGridDimensions()
        isConverting = true
        conversionTask?.cancel()
        conversionTask = Task {
            let palette = BeadPaletteRepository.shared.defaultPalette()
            let conversion = ImageToBeadConverter().convert(
                image: image,
                width: gridWidth,
                height: gridHeight,
                colorCount: colorCount,
                palette: palette
            )
            await MainActor.run {
                self.result = conversion
                self.isConverting = false
                self.showCanvas = true
            }
        }
    }
}
