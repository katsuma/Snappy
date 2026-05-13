import CoreGraphics

struct GridRegion: Codable, Hashable, Equatable {
    static let columns = 6
    static let rows = 4

    var startCol: Int
    var startRow: Int
    var endCol: Int    // inclusive
    var endRow: Int    // inclusive

    func fractionalRect() -> CGRect {
        let x = CGFloat(startCol) / CGFloat(GridRegion.columns)
        let y = CGFloat(startRow) / CGFloat(GridRegion.rows)
        let w = CGFloat(endCol - startCol + 1) / CGFloat(GridRegion.columns)
        let h = CGFloat(endRow - startRow + 1) / CGFloat(GridRegion.rows)
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
