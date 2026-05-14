import Foundation
import Combine

final class ShortcutStore: ObservableObject {
    @Published var shortcuts: [Shortcut] = []
    @Published var selectedID: UUID?

    private let saveURL: URL
    private var cancellables = Set<AnyCancellable>()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Snappy")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        saveURL = dir.appendingPathComponent("shortcuts.json")
        load()

        $shortcuts
            .dropFirst()
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    func addShortcut() {
        let s = Shortcut()
        shortcuts.append(s)
        selectedID = s.id
    }

    func deleteShortcut(id: UUID) {
        shortcuts.removeAll { $0.id == id }
        if selectedID == id { selectedID = nil }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Shortcut].self, from: data) else { return }
        shortcuts = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(shortcuts) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }
}
