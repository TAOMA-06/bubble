import SwiftUI

/// Shared Canvas drawing code for the pegboard grid, used by both the interactive editor and
/// the static ironed-result renderer so the two views can never visually drift apart.
enum BeadBoardRenderer {
    static func cellSize(for board: BeadBoard, in size: CGSize) -> CGFloat {
        guard board.width > 0, board.height > 0 else { return 0 }
        return min(size.width / CGFloat(board.width), size.height / CGFloat(board.height))
    }

    static func draw(
        board: BeadBoard,
        style: BeadRenderStyle,
        in context: GraphicsContext,
        cellSize: CGFloat,
        showGuide: Bool = true,
        showMismatches: Bool = false
    ) {
        guard cellSize > 0 else { return }
        let boardSize = CGSize(width: cellSize * CGFloat(board.width), height: cellSize * CGFloat(board.height))
        drawSurface(board: board, style: style, boardSize: boardSize, context: context, cellSize: cellSize)

        for y in 0..<board.height {
            for x in 0..<board.width {
                drawCell(
                    board: board, x: x, y: y, style: style,
                    showGuide: showGuide, showMismatches: showMismatches,
                    context: context, cellSize: cellSize
                )
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
        showGuide: Bool, showMismatches: Bool,
        context: GraphicsContext, cellSize: CGFloat
    ) {
        let rect = CGRect(x: CGFloat(x) * cellSize, y: CGFloat(y) * cellSize, width: cellSize, height: cellSize)
        let colorId = board.colorId(atX: x, y: y)
        let status = showMismatches ? PatternMatcher.status(board: board, x: x, y: y) : .none

        if style == .editing {
            let holeRect = CGRect(
                x: rect.midX - cellSize * 0.08, y: rect.midY - cellSize * 0.08,
                width: cellSize * 0.16, height: cellSize * 0.16
            )
            context.fill(Path(ellipseIn: holeRect), with: .color(BeadWorksTheme.pegboardHole))
            context.stroke(Path(ellipseIn: holeRect), with: .color(.white.opacity(0.22)), lineWidth: max(0.5, cellSize * 0.025))

            if colorId == nil, showGuide, let templateId = board.templateColorId(atX: x, y: y),
               let templateColor = BeadColor.byId(templateId) {
                let guideRect = rect.insetBy(dx: cellSize * 0.12, dy: cellSize * 0.12)
                let guideOpacity = status == .missing ? 0.85 : 0.55
                context.stroke(
                    Path(ellipseIn: guideRect),
                    with: .color(templateColor.color.opacity(guideOpacity)),
                    lineWidth: max(1, cellSize * 0.06)
                )
                if status == .missing {
                    drawMismatchMark(in: rect, color: Color(hex: "#E53935").opacity(0.7), cellSize: cellSize, context: context)
                }
            }
        }

        if let colorId, let beadColor = BeadColor.byId(colorId) {
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

            if style == .editing, status == .wrong {
                context.stroke(
                    Path(ellipseIn: rect.insetBy(dx: cellSize * 0.04, dy: cellSize * 0.04)),
                    with: .color(Color(hex: "#E53935")),
                    lineWidth: max(1.5, cellSize * 0.08)
                )
            }
        }
    }

    private static func drawMismatchMark(in rect: CGRect, color: Color, cellSize: CGFloat, context: GraphicsContext) {
        var mark = Path()
        let inset = cellSize * 0.32
        mark.move(to: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        mark.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
        mark.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY + inset))
        mark.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
        context.stroke(mark, with: .color(color), lineWidth: max(1, cellSize * 0.06))
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
    var showGuide: Bool = true
    var showMismatches: Bool = false

    var body: some View {
        Canvas { context, size in
            let cellSize = BeadBoardRenderer.cellSize(for: board, in: size)
            BeadBoardRenderer.draw(
                board: board,
                style: style,
                in: context,
                cellSize: cellSize,
                showGuide: showGuide,
                showMismatches: showMismatches
            )
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
        BeadBoardCanvas(board: board, style: style, showGuide: false, showMismatches: false)
            .frame(
                width: Self.renderWidth,
                height: Self.renderWidth * CGFloat(board.height) / CGFloat(max(board.width, 1))
            )
    }
}
