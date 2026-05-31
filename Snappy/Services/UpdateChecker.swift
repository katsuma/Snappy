import AppKit
import Foundation

final class UpdateChecker {
    private static let lastCheckKey = "lastUpdateCheckDate"
    private static let checkInterval: TimeInterval = 86400

    static func checkIfNeeded() {
        let defaults = UserDefaults.standard
        if let last = defaults.object(forKey: lastCheckKey) as? Date,
           Date().timeIntervalSince(last) < checkInterval {
            return
        }
        defaults.set(Date(), forKey: lastCheckKey)
        check()
    }

    private static func check() {
        guard let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        let url = URL(string: "https://api.github.com/repos/katsuma/Snappy/releases/latest")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String,
                  let releaseURL = json["html_url"] as? String else { return }
            let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            guard isNewer(latest, than: current) else { return }
            DispatchQueue.main.async {
                showAlert(current: current, latest: latest, releaseURL: releaseURL)
            }
        }.resume()
    }

    private static func isNewer(_ latest: String, than current: String) -> Bool {
        latest.compare(current, options: .numeric) == .orderedDescending
    }

    private static func showAlert(current: String, latest: String, releaseURL: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Snappy \(latest) is available. You have \(current)."
        alert.addButton(withTitle: "View Release")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: releaseURL) {
            NSWorkspace.shared.open(url)
        }
    }
}
