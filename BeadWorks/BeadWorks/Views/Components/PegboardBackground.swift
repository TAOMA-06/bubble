import SwiftUI

struct PegboardBackground: View {
    let rows: Int
    let cols: Int
    let cellSize: CGFloat
    let visibleMinRow: Int
    let visibleMaxRow: Int
    let visibleMinCol: Int
    let visibleMaxCol: Int

    init(rows: Int, cols: Int, cellSize: CGFloat,
         visibleMinRow: Int = 0, visibleMaxRow: Int? = nil,
         visibleMinCol: Int = 0, visibleMaxCol: Int? = nil) {
        self.rows = rows
        self.cols = cols
        self.cellSize = cellSize
        self.visibleMinRow = visibleMinRow
        self.visibleMaxRow = visibleMaxRow ?? rows
        self.visibleMinCol = visibleMinCol
        self.visibleMaxCol = visibleMaxCol ?? cols
    }

    var body: some View {
        Canvas { context, size in
            guard cellSize >= 4 else { return }
            let spacing = cellSize * 0.08
            let holeRadius = cellSize * 0.08
            for row in visibleMinRow..<visibleMaxRow {
                for col in visibleMinCol..<visibleMaxCol {
                    let x = CGFloat(col) * (cellSize + spacing) + cellSize / 2
                    let y = CGFloat(row) * (cellSize + spacing) + cellSize / 2
                    let rect = CGRect(x: x - holeRadius, y: y - holeRadius, width: holeRadius * 2, height: holeRadius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(Color(.systemGray4)))
                }
            }
        }
    }
}
