import Foundation
import Combine

final class PanelSettings: ObservableObject {
    @Published var useGlobalHotkey: Bool = false {
        didSet {
            if !isLoading {
                save()
            }
        }
    }
    @Published var openPanelCombo: KeyCombo? {
        didSet {
            if !isLoading {
                save()
            }
        }
    }

    private let defaults = UserDefaults.standard
    private var isLoading = true

    init() {
        useGlobalHotkey = defaults.bool(forKey: "useGlobalHotkey")
        if let data = defaults.data(forKey: "openPanelCombo"),
           let combo = try? JSONDecoder().decode(KeyCombo.self, from: data) {
            openPanelCombo = combo
        }
        isLoading = false
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
