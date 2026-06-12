import SwiftUI

struct PegboardBackground: View {
    let rows: Int
    let cols: Int
    let cellSize: CGFloat

    var body: some View {
        Canvas { context, size in
            let spacing = cellSize * 0.08
            let holeRadius = cellSize * 0.08
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * (cellSize + spacing) + cellSize / 2
                    let y = CGFloat(row) * (cellSize + spacing) + cellSize / 2
                    let rect = CGRect(x: x - holeRadius, y: y - holeRadius, width: holeRadius * 2, height: holeRadius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(Color(.systemGray4)))
                }
            }
        }
    }
}
