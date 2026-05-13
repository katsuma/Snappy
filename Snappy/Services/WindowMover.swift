import AppKit
import ApplicationServices

final class WindowMover {

    func applyShortcut(_ shortcut: Shortcut) {
        guard let region = shortcut.gridRegion else { return }
        guard let app = NSWorkspace.shared.frontmostApplication else { return }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value else { return }
        let window = value as! AXUIElement

        let screen = screenForWindow(window) ?? NSScreen.screens[0]
        let target = targetRect(for: region, on: screen)

        var origin = target.origin
        if let posVal = AXValueCreate(.cgPoint, &origin) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posVal)
        }
        var size = target.size
        if let sizeVal = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeVal)
        }
    }

    private func targetRect(for region: GridRegion, on screen: NSScreen) -> CGRect {
        let visible = screen.visibleFrame
        let frac = region.fractionalRect()

        // NSScreen uses bottom-left origin; AX uses top-left of the primary screen
        let primaryH = NSScreen.screens[0].frame.height

        let nsX = visible.minX + frac.minX * visible.width
        let nsH = frac.height * visible.height
        // Flip Y: grid row 0 = top, but NSScreen origin is at bottom
        let nsY = visible.minY + (1.0 - frac.minY - frac.height) * visible.height
        let nsW = frac.width * visible.width

        let axY = primaryH - (nsY + nsH)
        return CGRect(x: nsX, y: axY, width: nsW, height: nsH)
    }

    private func screenForWindow(_ window: AXUIElement) -> NSScreen? {
        var posRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              let posRef else { return nil }
        var point = CGPoint.zero
        AXValueGetValue(posRef as! AXValue, .cgPoint, &point)

        // AX point is top-left; convert to NSScreen bottom-left for hit-test
        let primaryH = NSScreen.screens[0].frame.height
        let nsPoint = CGPoint(x: point.x, y: primaryH - point.y)
        return NSScreen.screens.first { $0.frame.contains(nsPoint) }
    }

    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }
}
