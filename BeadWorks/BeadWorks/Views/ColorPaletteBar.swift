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
                                        .stroke(viewModel.selectedColorIndex == index ? BeadWorksColor.textPrimary : Color.clear, lineWidth: 3)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            if viewModel.state.mode == .numbered {
                                Text("\(index + 1)")
                                    .font(BeadWorksFont.caption(.bold))
                                    .foregroundColor(color.swiftUIColor.contrastText)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}
