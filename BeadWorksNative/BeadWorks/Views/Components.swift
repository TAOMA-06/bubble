import SwiftUI

/// Small 2x2 bead badge used as the app's mark on the splash screen and home header. Colors
/// mirror four entries from the real in-game palette so the mark reads as "made of beads"
/// rather than an arbitrary logo.
struct BeadMark: View {
    var diameter: CGFloat = 14
    var spacing: CGFloat = 6
    var padding: CGFloat = 14

    private let dotColors: [Color] = [
        Color(hex: "#E53935"), // red
        Color(hex: "#FDD835"), // yellow
        Color(hex: "#1E88E5"), // blue
        Color(hex: "#43A047"), // green
    ]

    var body: some View {
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                BeadDot(color: dotColors[0], diameter: diameter)
                BeadDot(color: dotColors[1], diameter: diameter)
            }
            HStack(spacing: spacing) {
                BeadDot(color: dotColors[2], diameter: diameter)
                BeadDot(color: dotColors[3], diameter: diameter)
            }
        }
        .padding(padding)
        .beadPanel(cornerRadius: padding + diameter / 2)
        .accessibilityHidden(true)
    }
}

struct BeadDot: View {
    let color: Color
    var diameter: CGFloat = 40
    var showsHole = true

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
                .insetBy(dx: max(1, diameter * 0.04), dy: max(1, diameter * 0.04))
            BeadMaterial.drawBead(
                in: rect,
                color: color,
                style: .editing,
                variation: .swatch,
                showsHole: showsHole,
                context: context
            )
        }
        .frame(width: diameter, height: diameter)
    }
}

struct MenuButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(BeadWorksTheme.accentGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.white.opacity(0.24), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(BeadWorksTheme.ink)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(BeadWorksTheme.ink.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BeadWorksTheme.ink.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 64)
            .beadPanel(cornerRadius: 16)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityIdentifier("menuButton_\(title)")
    }
}

struct ColorSwatchButton: View {
    let color: BeadColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BeadDot(color: color.color, diameter: 42)
                .padding(5)
                .background(
                    Circle()
                        .fill(isSelected ? BeadWorksTheme.paperBackground : BeadWorksTheme.trayBackground.opacity(0.55))
                )
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? BeadWorksTheme.ink : BeadWorksTheme.strongDivider, lineWidth: isSelected ? 3 : 1)
                )
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityIdentifier("colorSwatch_\(color.id)")
        .accessibilityLabel(color.name)
    }
}

struct BoardSizeOptionButton: View {
    let option: BoardSizeOption
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(BeadWorksTheme.pegboardBackground)
                    Image(systemName: option.symbolName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(option.isDefault ? BeadWorksTheme.accent : BeadWorksTheme.coolAccent)
                }
                .frame(width: 52, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(BeadWorksTheme.strongDivider, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(option.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(BeadWorksTheme.ink)
                            .lineLimit(1)
                        if option.isDefault {
                            Text("默认")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BeadWorksTheme.yellowAccent.opacity(0.55), in: Capsule())
                                .foregroundStyle(BeadWorksTheme.ink)
                        }
                    }
                    Text(option.subtitle)
                        .font(.caption)
                        .foregroundStyle(BeadWorksTheme.ink.opacity(0.62))
                        .lineLimit(1)
                    Text(option.detail)
                        .font(.caption2)
                        .foregroundStyle(BeadWorksTheme.ink.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
            }
            .padding(12)
            .beadPanel(cornerRadius: 16, fill: BeadWorksTheme.paperBackground)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(option.title)
        .accessibilityIdentifier("boardSize_\(option.size)")
    }
}

struct MaterialNote: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(BeadWorksTheme.ink.opacity(0.66))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(BeadWorksTheme.trayBackground.opacity(0.65), in: Capsule())
    }
}

struct GalleryCard: View {
    let work: GalleryWork
    let image: UIImage?

    private var filledCount: Int {
        work.cells.reduce(0) { $1 == nil ? $0 : $0 + 1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(8)
            .background(BeadWorksTheme.pegboardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(BeadWorksTheme.strongDivider, lineWidth: 1)
            )

            Text(work.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BeadWorksTheme.ink)
                .lineLimit(1)

            HStack(spacing: 6) {
                MaterialNote(text: "\(work.width)×\(work.height)", systemImage: "square.grid.3x3")
                MaterialNote(text: "\(filledCount) 颗", systemImage: "circle.grid.3x3.fill")
            }
        }
        .padding(11)
        .beadPanel(cornerRadius: 16)
        .accessibilityIdentifier("galleryCard_\(work.title)")
    }
}

struct EmptyGalleryState: View {
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                BeadDot(color: BeadWorksTheme.accent, diameter: 28)
                BeadDot(color: BeadWorksTheme.coolAccent, diameter: 28)
                BeadDot(color: BeadWorksTheme.mintAccent, diameter: 28)
            }
            Text("还没有完成的作品")
                .font(.headline)
                .foregroundStyle(BeadWorksTheme.ink)
            Text("摆好一块拼豆板，熨烫成型后会收进这个材料盒。")
                .font(.subheadline)
                .foregroundStyle(BeadWorksTheme.ink.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: 320)
        .beadPanel(cornerRadius: BeadWorksTheme.panelCornerRadius)
        .padding(.top, 80)
        .padding(.horizontal, 24)
    }
}
