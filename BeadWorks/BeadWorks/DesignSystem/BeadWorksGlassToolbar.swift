import SwiftUI

// 液态玻璃工具栏容器：仅用 GlassEffectContainer 协调内部多个玻璃元素的采样与融合，
// 不再对整组可交互内容套一层 glassEffect（那会拦截子按钮的点击命中）。
struct BeadWorksGlassToolbar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            content
        }
    }
}

// 液态玻璃工具栏按钮（图标 + 文字，纵向布局）
struct BeadWorksGlassButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(height: 20)
                }

                Text(title)
                    .font(BeadWorksFont.caption(.medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonBorderShape(.capsule)
        .modifier(ToolbarGlassStyle(selected: isSelected))
    }
}

private struct ToolbarGlassStyle: ViewModifier {
    let selected: Bool

    func body(content: Content) -> some View {
        if selected {
            content
                .tint(BeadWorksColor.accent)
                .buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.glass)
        }
    }
}
