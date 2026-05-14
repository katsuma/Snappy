import Foundation

struct Shortcut: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var keyCombo: KeyCombo?
    var gridRegion: GridRegion?
    var isEnabled: Bool

    init(name: String = "New Shortcut") {
        self.id = UUID()
        self.name = name
        self.keyCombo = nil
        self.gridRegion = nil
        self.isEnabled = true
    }
}
