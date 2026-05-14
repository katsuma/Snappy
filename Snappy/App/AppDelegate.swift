import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var preferencesWindow: NSWindow?

    let settings = PanelSettings()
    let windowMover = WindowMover()
    private lazy var panelManager = SnapPanelManager(windowMover: windowMover)
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        reloadHotkey()
        observeSettings()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Preferences\u{2026}", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Snappy", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    private func reloadHotkey() {
        HotkeyManager.shared.set(combo: settings.openPanelCombo) { [weak self] in
            self?.panelManager.toggle()
        }
    }

    private func observeSettings() {
        settings.$openPanelCombo
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.reloadHotkey() }
            .store(in: &cancellables)
    }

    @objc func openPreferences() {
        if preferencesWindow == nil {
            let view = PreferencesView()
                .environmentObject(settings)
                .background(.clear)

            let hostingView = NSHostingView(rootView: view)
            let glassView = NSGlassEffectView()
            glassView.contentView = hostingView

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 440),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Snappy"
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.contentView = glassView
            window.center()
            window.isReleasedWhenClosed = false
            preferencesWindow = window
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
