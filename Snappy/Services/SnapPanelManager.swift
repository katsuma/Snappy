import AppKit
import ApplicationServices
import Carbon
import SwiftUI

final class SnapPanelManager {
    private var panelWindow: NSWindow?
    private var localMonitor: Any?
    private let windowMover: WindowMover

    init(windowMover: WindowMover) {
        self.windowMover = windowMover
    }

    func toggle() {
        if panelWindow?.isVisible == true {
            dismiss()
        } else {
            present()
        }
    }

    private func present() {
        // Capture target BEFORE activating Snappy
        guard let targetApp = NSWorkspace.shared.frontmostApplication,
              targetApp.bundleIdentifier != Bundle.main.bundleIdentifier else { return }

        let appElement = AXUIElementCreateApplication(targetApp.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value else { return }
        let targetWindow = value as! AXUIElement

        let view = SnapPanelView(
            targetApp: targetApp,
            onSelect: { [weak self] region in
                self?.windowMover.apply(region: region, to: targetWindow)
                self?.dismiss()
            }
        )

        let hostingView = NSHostingView(rootView: view)
        let glassView = NSGlassEffectView()
        glassView.contentView = hostingView

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView],
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

        panelWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(kVK_Escape) {
                self?.dismiss()
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
