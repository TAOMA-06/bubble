import SwiftUI

enum BeadWorksButtonStyle {
    case primary
    case secondary
    case accent
}

struct BeadWorksButton: View {
    let title: String
    let icon: String?
    let style: BeadWorksButtonStyle
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        style: BeadWorksButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(BeadWorksFont.button())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .modifier(GlassStyle(style: style))
    }
}

// 用于工具栏的紧凑按钮
struct BeadWorksToolbarButton: View {
    let title: String
    let icon: String?
    let isPrimary: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isPrimary = isPrimary
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(BeadWorksFont.button(.medium))
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
        .buttonBorderShape(.capsule)
        .modifier(GlassStyle(isPrimary: isPrimary))
    }
}

// 统一切换 .glass / .glassProminent 的样式封装；仅 prominent 保留 tint 着色
private struct GlassStyle: ViewModifier {
    let style: BeadWorksButtonStyle?

    init(style: BeadWorksButtonStyle) {
        self.style = style
    }

    init(isPrimary: Bool) {
        self.style = isPrimary ? .primary : .secondary
    }

    func body(content: Content) -> some View {
        switch style {
        case .primary:
            content
                .tint(BeadWorksColor.accent)
                .buttonStyle(.glassProminent)
        case .accent:
            content
                .tint(BeadWorksColor.accentBlue)
                .buttonStyle(.glassProminent)
        case .secondary, .none:
            content.buttonStyle(.glass)
        }
    }
}
