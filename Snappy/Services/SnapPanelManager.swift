import AppKit
import ApplicationServices
import Carbon
import SwiftUI

final class SnapPanelManager {
    private var panelWindow: NSWindow?
    private var localMonitor: Any?
    private var workspaceObserver: Any?
    private var lastFrontmostApp: NSRunningApplication?
    private let windowMover: WindowMover
    private let store: ShortcutStore
    private let onOpenSettings: () -> Void

    init(windowMover: WindowMover, store: ShortcutStore, onOpenSettings: @escaping () -> Void) {
        self.windowMover = windowMover
        self.store = store
        self.onOpenSettings = onOpenSettings
        observeFrontmostApp()
    }

    private func observeFrontmostApp() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
            self?.lastFrontmostApp = app
        }
    }

    func toggle() {
        if panelWindow?.isVisible == true {
            dismiss()
        } else {
            present()
        }
    }

    func present() {
        // Use current frontmost app if it's not Snappy, otherwise fall back to last known
        let candidate = NSWorkspace.shared.frontmostApplication
        let targetApp: NSRunningApplication
        if let app = candidate, app.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetApp = app
        } else if let last = lastFrontmostApp {
            targetApp = last
        } else {
            return
        }

        let appElement = AXUIElementCreateApplication(targetApp.processIdentifier)
        var value: CFTypeRef?
        // Try focused window first, fall back to main window
        let focusedOK = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value) == .success
        if !focusedOK {
            AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &value)
        }
        guard let value else { return }
        let targetWindow = value as! AXUIElement

        let view = SnapPanelView(
            targetApp: targetApp,
            onSelect: { [weak self] region in
                self?.windowMover.apply(region: region, to: targetWindow)
                self?.dismiss()
            },
            onDismiss: { [weak self] in self?.dismiss() },
            onOpenSettings: onOpenSettings
        )

        let hostingView = NSHostingView(rootView: view)
        let glassView = NSGlassEffectView()
        glassView.contentView = hostingView

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 320),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.contentView = glassView
        window.center()
        window.isReleasedWhenClosed = false
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        panelWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            if event.keyCode == UInt16(kVK_Escape) {
                self.dismiss()
                return nil
            }

            let pressed = KeyCombo(
                keyCode: UInt32(event.keyCode),
                modifiers: KeyCombo.carbonModifiers(from: event.modifierFlags)
            )
            if let match = self.store.shortcuts.first(where: {
                $0.isEnabled && $0.keyCombo == pressed && $0.gridRegion != nil
            }) {
                self.windowMover.apply(region: match.gridRegion!, to: targetWindow)
                self.dismiss()
                return nil
            }

            return event
        }
    }

    func dismiss() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        panelWindow?.orderOut(nil)
    }
}
