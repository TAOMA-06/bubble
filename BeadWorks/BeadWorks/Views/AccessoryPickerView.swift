import SwiftUI

struct AccessoryPickerView: View {
    let onSelect: (AccessoryType) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("选择配件")
                .font(BeadWorksFont.headline())
                .foregroundStyle(BeadWorksColor.textPrimary)

            HStack(spacing: 20) {
                ForEach(AccessoryType.allCases) { accessory in
                    Button { onSelect(accessory) } label: {
                        VStack(spacing: 8) {
                            Image(systemName: accessory.iconName)
                                .font(.system(size: 32))
                                .foregroundStyle(BeadWorksColor.accent)
                            Text(accessory.displayName)
                                .font(BeadWorksFont.caption())
                                .foregroundStyle(BeadWorksColor.textPrimary)
                        }
                        .frame(width: 80, height: 80)
                        .background(BeadWorksColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(BeadWorksColor.border, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .transition(.scale.combined(with: .opacity))
    }
}
