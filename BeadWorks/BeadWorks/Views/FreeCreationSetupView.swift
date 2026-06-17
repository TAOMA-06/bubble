import SwiftUI

struct FreeCreationSetupView: View {
    let onStart: (Int) -> Void

    @State private var customSide: Int = 29
    @State private var selectedPreset: Int? = 29
    @State private var sideInput: String = "29"
    @FocusState private var inputFocused: Bool

    private let presets = [29, 57, 100]
    private let maxSide = 640

    private var previewSide: Int {
        Int(sideInput) ?? customSide
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("选择画布尺寸")
                        .font(BeadWorksFont.title())
                        .foregroundStyle(BeadWorksColor.textPrimary)

                    Text("正方形画布，最大 640 × 640")
                        .font(BeadWorksFont.body())
                        .foregroundStyle(BeadWorksColor.textSecondary)
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("预设尺寸")
                        .font(BeadWorksFont.headline())
                        .foregroundStyle(BeadWorksColor.textPrimary)

                    HStack(spacing: 12) {
                        ForEach(presets, id: \.self) { side in
                            Button {
                                dismissKeyboard()
                                selectPreset(side)
                            } label: {
                                Text("\(side) × \(side)")
                                    .font(BeadWorksFont.button(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonBorderShape(.roundedRectangle(radius: 12))
                            .modifier(PresetGlassStyle(isSelected: selectedPreset == side))
                        }
                    }
                }
                .padding(.horizontal, 24)

                BeadWorksCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("自定义边长")
                            .font(BeadWorksFont.headline())
                            .foregroundStyle(BeadWorksColor.textPrimary)

                        HStack(spacing: 8) {
                            TextField("边长", text: $sideInput)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(BeadWorksFont.body())
                                .foregroundStyle(BeadWorksColor.textPrimary)
                                .focused($inputFocused)
                                .frame(width: 72)
                                .padding(.vertical, 8)
                                .background(BeadWorksColor.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .onChange(of: sideInput) { _, newValue in
                                    let digits = newValue.filter(\.isNumber)
                                    if digits != newValue {
                                        sideInput = digits
                                    }
                                }

                            Text("× \(previewSide)")
                                .font(BeadWorksFont.body())
                                .foregroundStyle(BeadWorksColor.textPrimary)

                            Spacer()

                            Stepper("", value: stepperBinding, in: 1...maxSide)
                        }

                        Text("最高 640 × 640")
                            .font(BeadWorksFont.caption())
                            .foregroundStyle(BeadWorksColor.textSecondary)
                    }
                }
                .padding(.horizontal, 24)

                BeadWorksButton(
                    title: "开始创作",
                    icon: "paintbrush.fill",
                    style: .primary
                ) {
                    dismissKeyboard()
                    commitInput()
                    onStart(customSide)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(BeadWorksColor.background)
        .navigationTitle("自由创作")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    dismissKeyboard()
                }
            }
        }
    }

    private var stepperBinding: Binding<Int> {
        Binding(
            get: { customSide },
            set: { newValue in
                customSide = newValue
                sideInput = "\(newValue)"
                selectedPreset = presets.contains(newValue) ? newValue : nil
            }
        )
    }

    private func selectPreset(_ side: Int) {
        selectedPreset = side
        customSide = side
        sideInput = "\(side)"
    }

    private func dismissKeyboard() {
        commitInput()
        inputFocused = false
    }

    private func commitInput() {
        let value = Int(sideInput) ?? customSide
        customSide = min(max(value, 1), maxSide)
        sideInput = "\(customSide)"
        selectedPreset = presets.contains(customSide) ? customSide : nil
    }
}

private struct PresetGlassStyle: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content
                .tint(BeadWorksColor.accent)
                .buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.glass)
        }
    }
}
