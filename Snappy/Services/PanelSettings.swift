import Foundation
import Combine

final class PanelSettings: ObservableObject {
    @Published var openPanelCombo: KeyCombo? {
        didSet { save() }
    }

    private let key = "openPanelCombo"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let combo = try? JSONDecoder().decode(KeyCombo.self, from: data) {
            openPanelCombo = combo
        }
    }

    private func save() {
        if let combo = openPanelCombo,
           let data = try? JSONEncoder().encode(combo) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
