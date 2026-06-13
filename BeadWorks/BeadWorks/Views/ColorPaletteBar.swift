import SwiftUI

struct ColorPaletteBar: View {
    @ObservedObject var viewModel: CanvasViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(viewModel.state.colorPalette.enumerated()), id: \.element.id) { index, color in
                    Button {
                        viewModel.selectedColorIndex = index
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color.swiftUIColor)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.selectedColorIndex == index ? Color.primary : Color.clear, lineWidth: 3)
                                )
                            if viewModel.state.mode == .numbered {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(color.swiftUIColor.contrastText)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .applyGlassEffectCircle()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

extension View {
    func applyGlassEffectCircle() -> some View {
        if #available(iOS 26.0, *) {
            return self.buttonStyle(.glass)
        } else {
            return self
        }
    }
}
