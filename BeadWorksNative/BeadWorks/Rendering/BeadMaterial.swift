import SwiftUI

struct BeadMaterialVariation: Equatable {
    let highlightOffset: CGSize
    let brightness: Double
    let roundness: CGFloat
    let texturePhase: CGFloat

    static let swatch = BeadMaterial.variation(x: -7, y: 13)
}

enum BeadMaterial {
    static func variation(x: Int, y: Int) -> BeadMaterialVariation {
        let u = normalized(x: x, y: y, salt: 17)
        let v = normalized(x: x, y: y, salt: 43)
        let w = normalized(x: x, y: y, salt: 89)
        return BeadMaterialVariation(
            highlightOffset: CGSize(width: (u - 0.5) * 0.08, height: (v - 0.5) * 0.07),
            brightness: Double((w - 0.5) * 0.08),
            roundness: 0.96 + CGFloat(u) * 0.05,
            texturePhase: CGFloat(v)
        )
    }

    static func drawBead(
        in beadRect: CGRect,
        color: Color,
        style: BeadRenderStyle,
        variation: BeadMaterialVariation,
        showsHole: Bool = true,
        context: GraphicsContext
    ) {
        let rect = beadRect.insetBy(dx: beadRect.width * (1 - variation.roundness) * 0.03, dy: 0)
        let shape = beadShape(in: rect, style: style)
        let shadowOpacity: Double = style == .fullFused ? 0.08 : 0.22
        let shadowRect = rect.offsetBy(dx: rect.width * 0.035, dy: rect.height * 0.055)
            .insetBy(dx: rect.width * 0.03, dy: rect.height * 0.02)

        context.fill(beadShape(in: shadowRect, style: style), with: .color(.black.opacity(shadowOpacity)))
        context.fill(shape, with: .color(color))
        drawPlasticVolume(in: rect, shape: shape, style: style, variation: variation, context: context)
        drawRim(in: rect, shape: shape, style: style, context: context)

        if showsHole {
            switch style {
            case .editing:
                drawRecessedHole(in: rect, opacity: 0.32, context: context)
            case .lightFused:
                drawRecessedHole(in: rect.insetBy(dx: rect.width * 0.06, dy: rect.height * 0.06), opacity: 0.16, context: context)
            case .fullFused:
                drawSoftCenterDimple(in: rect, context: context)
            }
        }

        drawSpecularGlint(in: rect, style: style, variation: variation, context: context)
        drawMicroTexture(in: rect, shape: shape, style: style, variation: variation, context: context)
    }

    private static func normalized(x: Int, y: Int, salt: Int) -> CGFloat {
        let raw = sin(Double(x * 12_989 + y * 78_233 + salt * 37)) * 43_758.5453
        return CGFloat(raw - floor(raw))
    }

    private static func beadShape(in rect: CGRect, style: BeadRenderStyle) -> Path {
        switch style {
        case .editing, .lightFused:
            return Path(ellipseIn: rect)
        case .fullFused:
            return Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) * 0.28)
        }
    }

    private static func drawPlasticVolume(
        in rect: CGRect,
        shape: Path,
        style: BeadRenderStyle,
        variation: BeadMaterialVariation,
        context: GraphicsContext
    ) {
        let center = CGPoint(
            x: rect.minX + rect.width * (0.34 + variation.highlightOffset.width),
            y: rect.minY + rect.height * (0.28 + variation.highlightOffset.height)
        )
        let darkEdge = style == .fullFused ? 0.13 : 0.20
        let bright = max(0.12, 0.34 + variation.brightness)
        context.fill(
            shape,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: .white.opacity(bright), location: 0),
                    .init(color: .white.opacity(0.08), location: 0.34),
                    .init(color: .clear, location: 0.58),
                    .init(color: .black.opacity(darkEdge), location: 1),
                ]),
                center: center,
                startRadius: 0,
                endRadius: max(rect.width, rect.height) * 0.82
            )
        )
    }

    private static func drawRim(in rect: CGRect, shape: Path, style: BeadRenderStyle, context: GraphicsContext) {
        let lineWidth = max(0.55, rect.width * (style == .fullFused ? 0.025 : 0.045))
        context.stroke(shape, with: .color(.white.opacity(style == .fullFused ? 0.14 : 0.24)), lineWidth: lineWidth)
        context.stroke(shape, with: .color(.black.opacity(style == .fullFused ? 0.10 : 0.20)), lineWidth: max(0.5, lineWidth * 0.7))

        var lowerRim = Path()
        lowerRim.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.midY + rect.height * 0.23))
        lowerRim.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.midY + rect.height * 0.22),
            control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.03)
        )
        context.stroke(lowerRim, with: .color(.black.opacity(style == .fullFused ? 0.07 : 0.18)), lineWidth: max(0.6, rect.width * 0.035))
    }

    private static func drawRecessedHole(in rect: CGRect, opacity: Double, context: GraphicsContext) {
        let hole = CGRect(
            x: rect.midX - rect.width * 0.145,
            y: rect.midY - rect.height * 0.145,
            width: rect.width * 0.29,
            height: rect.height * 0.29
        )
        let holePath = Path(ellipseIn: hole)
        context.fill(Path(ellipseIn: hole.offsetBy(dx: rect.width * 0.018, dy: rect.height * 0.028)), with: .color(.black.opacity(opacity * 0.75)))
        context.fill(
            holePath,
            with: .radialGradient(
                Gradient(colors: [
                    BeadWorksTheme.ink.opacity(opacity),
                    BeadWorksTheme.ink.opacity(opacity * 0.72),
                    .white.opacity(0.10),
                ]),
                center: CGPoint(x: hole.minX + hole.width * 0.34, y: hole.minY + hole.height * 0.28),
                startRadius: 0,
                endRadius: hole.width * 0.75
            )
        )
        context.stroke(holePath, with: .color(.white.opacity(0.24)), lineWidth: max(0.5, rect.width * 0.026))
        context.stroke(holePath, with: .color(.black.opacity(opacity * 0.55)), lineWidth: max(0.45, rect.width * 0.018))
    }

    private static func drawSoftCenterDimple(in rect: CGRect, context: GraphicsContext) {
        let dimple = CGRect(
            x: rect.midX - rect.width * 0.07,
            y: rect.midY - rect.height * 0.06,
            width: rect.width * 0.14,
            height: rect.height * 0.12
        )
        context.fill(Path(ellipseIn: dimple), with: .color(.black.opacity(0.045)))
        context.stroke(Path(ellipseIn: dimple), with: .color(.white.opacity(0.08)), lineWidth: max(0.45, rect.width * 0.012))
    }

    private static func drawSpecularGlint(
        in rect: CGRect,
        style: BeadRenderStyle,
        variation: BeadMaterialVariation,
        context: GraphicsContext
    ) {
        guard rect.width > 7 else { return }
        let glint = CGRect(
            x: rect.minX + rect.width * (0.19 + variation.highlightOffset.width),
            y: rect.minY + rect.height * (0.14 + variation.highlightOffset.height),
            width: rect.width * (style == .fullFused ? 0.24 : 0.30),
            height: rect.height * (style == .fullFused ? 0.12 : 0.17)
        )
        context.fill(Path(ellipseIn: glint), with: .color(.white.opacity(style == .fullFused ? 0.18 : 0.34)))
    }

    private static func drawMicroTexture(
        in rect: CGRect,
        shape: Path,
        style: BeadRenderStyle,
        variation: BeadMaterialVariation,
        context: GraphicsContext
    ) {
        guard rect.width > 10 else { return }
        let opacity = style == .fullFused ? 0.055 : 0.075
        let y = rect.minY + rect.height * (0.52 + (variation.texturePhase - 0.5) * 0.08)
        var streak = Path()
        streak.move(to: CGPoint(x: rect.minX + rect.width * 0.20, y: y))
        streak.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.20, y: y + rect.height * 0.02),
            control: CGPoint(x: rect.midX, y: y - rect.height * 0.06)
        )
        context.stroke(streak, with: .color(.white.opacity(opacity)), lineWidth: max(0.45, rect.width * 0.018))

        let speck = CGRect(
            x: rect.minX + rect.width * (0.62 + (variation.texturePhase - 0.5) * 0.08),
            y: rect.minY + rect.height * 0.28,
            width: rect.width * 0.055,
            height: rect.height * 0.035
        )
        context.fill(Path(ellipseIn: speck), with: .color(.white.opacity(opacity * 0.9)))
    }
}
