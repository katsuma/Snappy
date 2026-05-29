import SwiftUI

struct GridPickerView: View {
    @Binding var region: GridRegion?
    var cellSize: CGFloat = 22
    var onCommit: ((GridRegion) -> Void)? = nil

    private let gap: CGFloat = 4
    private let cols = GridRegion.columns
    private let rows = GridRegion.rows

    private var totalWidth: CGFloat  { CGFloat(cols) * cellSize + CGFloat(cols - 1) * gap }
    private var totalHeight: CGFloat { CGFloat(rows) * cellSize + CGFloat(rows - 1) * gap }

    var body: some View {
        Canvas { ctx, _ in
            for col in 0..<cols {
                for row in 0..<rows {
                    let rect = cellRect(col: col, row: row)
                    let selected = isCellSelected(col: col, row: row)
                    ctx.fill(
                        Path(roundedRect: rect, cornerRadius: cellSize > 30 ? 6 : 2),
                        with: .color(selected ? Color.primary.opacity(0.85) : Color.primary.opacity(0.12))
                    )
                }
            }
        }
        .frame(width: totalWidth, height: totalHeight)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard let start = cellAt(value.startLocation),
                          let current = cellAt(value.location) else { return }
                    region = GridRegion(
                        startCol: min(start.col, current.col),
                        startRow: min(start.row, current.row),
                        endCol:   max(start.col, current.col),
                        endRow:   max(start.row, current.row)
                    )
                }
                .onEnded { _ in
                    if let region, let onCommit {
                        onCommit(region)
                    }
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func cellAt(_ point: CGPoint) -> (col: Int, row: Int)? {
        let col = Int(point.x / (cellSize + gap))
        let row = Int(point.y / (cellSize + gap))
        guard (0..<cols).contains(col), (0..<rows).contains(row) else { return nil }
        return (col, row)
    }

    private func cellRect(col: Int, row: Int) -> CGRect {
        CGRect(
            x: CGFloat(col) * (cellSize + gap),
            y: CGFloat(row) * (cellSize + gap),
            width: cellSize,
            height: cellSize
        )
    }

    private func isCellSelected(col: Int, row: Int) -> Bool {
        guard let r = region else { return false }
        return col >= r.startCol && col <= r.endCol && row >= r.startRow && row <= r.endRow
    }
}
