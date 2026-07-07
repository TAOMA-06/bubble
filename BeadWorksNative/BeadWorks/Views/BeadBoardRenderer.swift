import SwiftUI

/// How a `BeadBoard` should be painted: mid-craft on the pegboard, lightly fused with bead holes
/// still visible, or fully fused into soft plastic pixels.
enum BeadRenderStyle: Hashable {
    case editing
    case lightFused
    case fullFused

    static let fusedStyles: [BeadRenderStyle] = [.fullFused, .lightFused]

    var label: String {
        switch self {
        case .editing: return "摆豆中"
        case .lightFused: return "轻熔"
        case .fullFused: return "全熔"
        }
    }

    var description: String {
        switch self {
        case .editing: return "圆珠和孔洞清晰可见"
        case .lightFused: return "保留圆珠轮廓和小孔"
        case .fullFused: return "压平成光滑像素块"
        }
    }
}

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

/// Shared Canvas drawing code for the pegboard grid, used by both the interactive editor and
/// the static ironed-result renderer so the two views can never visually drift apart.
enum BeadBoardRenderer {
    static func cellSize(for board: BeadBoard, in size: CGSize) -> CGFloat {
        guard board.width > 0, board.height > 0 else { return 0 }
        return min(size.width / CGFloat(board.width), size.height / CGFloat(board.height))
    }

    static func draw(board: BeadBoard, style: BeadRenderStyle, in context: GraphicsContext, cellSize: CGFloat) {
        guard cellSize > 0 else { return }
        let boardSize = CGSize(width: cellSize * CGFloat(board.width), height: cellSize * CGFloat(board.height))
        drawSurface(board: board, style: style, boardSize: boardSize, context: context, cellSize: cellSize)

        for y in 0..<board.height {
            for x in 0..<board.width {
                drawCell(board: board, x: x, y: y, style: style, context: context, cellSize: cellSize)
            }
        }

        drawInterlockingSeams(board: board, context: context, cellSize: cellSize)
    }

    private static func drawSurface(
        board: BeadBoard,
        style: BeadRenderStyle,
        boardSize: CGSize,
        context: GraphicsContext,
        cellSize: CGFloat
    ) {
        let cornerRadius = max(2, cellSize * 0.34)
        let boardRect = CGRect(origin: .zero, size: boardSize)
        let fill = style == .editing ? BeadWorksTheme.pegboardBackground : BeadWorksTheme.paperBackground
        context.fill(Path(roundedRect: boardRect, cornerRadius: cornerRadius), with: .color(fill))
        context.stroke(
            Path(roundedRect: boardRect.insetBy(dx: cellSize * 0.03, dy: cellSize * 0.03), cornerRadius: cornerRadius),
            with: .color(BeadWorksTheme.workbenchWoodDark.opacity(0.22)),
            lineWidth: max(1, cellSize * 0.05)
        )
    }

    private static func drawCell(
        board: BeadBoard, x: Int, y: Int, style: BeadRenderStyle,
        context: GraphicsContext, cellSize: CGFloat
    ) {
        let rect = CGRect(x: CGFloat(x) * cellSize, y: CGFloat(y) * cellSize, width: cellSize, height: cellSize)
        let colorId = board.colorId(atX: x, y: y)

        if style == .editing {
            let holeRect = CGRect(
                x: rect.midX - cellSize * 0.08, y: rect.midY - cellSize * 0.08,
                width: cellSize * 0.16, height: cellSize * 0.16
            )
            context.fill(Path(ellipseIn: holeRect), with: .color(BeadWorksTheme.pegboardHole))
            context.stroke(Path(ellipseIn: holeRect), with: .color(.white.opacity(0.22)), lineWidth: max(0.5, cellSize * 0.025))

            if colorId == nil, let templateId = board.templateColorId(atX: x, y: y),
               let templateColor = BeadColor.byId(templateId) {
                let guideRect = rect.insetBy(dx: cellSize * 0.12, dy: cellSize * 0.12)
                context.stroke(
                    Path(ellipseIn: guideRect),
                    with: .color(templateColor.color.opacity(0.55)),
                    lineWidth: max(1, cellSize * 0.06)
                )
            }
        }

        guard let colorId, let beadColor = BeadColor.byId(colorId) else { return }

        switch style {
        case .editing:
            let beadRect = rect.insetBy(dx: cellSize * 0.08, dy: cellSize * 0.08)
            BeadMaterial.drawBead(
                in: beadRect,
                color: beadColor.color,
                style: style,
                variation: BeadMaterial.variation(x: x, y: y),
                context: context
            )

        case .lightFused:
            let beadRect = rect.insetBy(dx: cellSize * 0.02, dy: cellSize * 0.02)
            BeadMaterial.drawBead(
                in: beadRect,
                color: beadColor.color,
                style: style,
                variation: BeadMaterial.variation(x: x, y: y),
                context: context
            )

        case .fullFused:
            let beadRect = rect.insetBy(dx: -cellSize * 0.045, dy: -cellSize * 0.045)
            BeadMaterial.drawBead(
                in: beadRect,
                color: beadColor.color,
                style: style,
                variation: BeadMaterial.variation(x: x, y: y),
                context: context
            )
        }
    }

    private static func drawInterlockingSeams(board: BeadBoard, context: GraphicsContext, cellSize: CGFloat) {
        guard board.width > 29 || board.height > 29 else { return }

        let seamColor = BeadWorksTheme.workbenchWoodDark.opacity(0.18)
        let lineWidth = max(1, cellSize * 0.05)
        if board.width > 29 {
            var x = 29
            while x < board.width {
                let px = CGFloat(x) * cellSize
                var path = Path()
                path.move(to: CGPoint(x: px, y: 0))
                path.addLine(to: CGPoint(x: px, y: CGFloat(board.height) * cellSize))
                context.stroke(path, with: .color(seamColor), lineWidth: lineWidth)
                x += 29
            }
        }
        if board.height > 29 {
            var y = 29
            while y < board.height {
                let py = CGFloat(y) * cellSize
                var path = Path()
                path.move(to: CGPoint(x: 0, y: py))
                path.addLine(to: CGPoint(x: CGFloat(board.width) * cellSize, y: py))
                context.stroke(path, with: .color(seamColor), lineWidth: lineWidth)
                y += 29
            }
        }
    }
}

/// Read-only board view for static previews (finished-work screen, gallery thumbnails).
struct BeadBoardCanvas: View {
    let board: BeadBoard
    var style: BeadRenderStyle = .editing

    var body: some View {
        Canvas { context, size in
            let cellSize = BeadBoardRenderer.cellSize(for: board, in: size)
            BeadBoardRenderer.draw(board: board, style: style, in: context, cellSize: cellSize)
        }
        .aspectRatio(CGFloat(board.width) / CGFloat(max(board.height, 1)), contentMode: .fit)
    }
}

/// Offscreen-only view used with `ImageRenderer` to rasterize the ironed result into a `UIImage`.
struct IroningRenderView: View {
    let board: BeadBoard
    var style: BeadRenderStyle = .fullFused
    static let renderWidth: CGFloat = 512

    var body: some View {
        BeadBoardCanvas(board: board, style: style)
            .frame(
                width: Self.renderWidth,
                height: Self.renderWidth * CGFloat(board.height) / CGFloat(max(board.width, 1))
            )
    }
}
