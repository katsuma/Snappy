import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?

    let settings = PanelSettings()
    let store = ShortcutStore()
    let windowMover = WindowMover()
    private lazy var panelManager = SnapPanelManager(
        windowMover: windowMover,
        store: store,
        onOpenSettings: { [weak self] in self?.openSettings() }
    )
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        reloadHotkey()
        observeSettings()
        if !windowMover.isAccessibilityGranted {
            windowMover.requestAccessibilityPermission()
        }
        // LSUIElement app: doesn't steal focus on launch, so frontmostApplication
        // still points to the previous app — show panel immediately.
        panelManager.present()
        UpdateChecker.checkIfNeeded()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Panel", action: #selector(showPanel), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings\u{2026}", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Snappy", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelManager.present()
        return true
    }

    @objc func showPanel() {
        panelManager.present()
    }

    private func reloadHotkey() {
        if settings.useGlobalHotkey {
            HotkeyManager.shared.set(combo: settings.openPanelCombo) { [weak self] in
                self?.panelManager.toggle()
            }
        } else {
            HotkeyManager.shared.clear()
        }
    }

    private func observeSettings() {
        settings.$useGlobalHotkey
            .combineLatest(settings.$openPanelCombo)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.reloadHotkey() }
            .store(in: &cancellables)
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let view = PreferencesView()
                .environmentObject(settings)
                .environmentObject(store)
                .background(.clear)

            let hostingView = NSHostingView(rootView: view)
            let glassView = NSGlassEffectView()
            glassView.contentView = hostingView

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 480),
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
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
