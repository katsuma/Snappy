import Foundation
import Combine

final class PanelSettings: ObservableObject {
    @Published var useGlobalHotkey: Bool = false {
        didSet { save() }
    }
    @Published var openPanelCombo: KeyCombo? {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard

    init() {
        useGlobalHotkey = defaults.bool(forKey: "useGlobalHotkey")
        if let data = defaults.data(forKey: "openPanelCombo"),
           let combo = try? JSONDecoder().decode(KeyCombo.self, from: data) {
            openPanelCombo = combo
        }
    }

    private func save() {
        defaults.set(useGlobalHotkey, forKey: "useGlobalHotkey")
        if let combo = openPanelCombo,
           let data = try? JSONEncoder().encode(combo) {
            defaults.set(data, forKey: "openPanelCombo")
        } else {
            defaults.removeObject(forKey: "openPanelCombo")
        }
    }
}
