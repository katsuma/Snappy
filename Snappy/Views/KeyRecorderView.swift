import SwiftUI
import AppKit
import Carbon

struct KeyRecorderView: NSViewRepresentable {
    @Binding var keyCombo: KeyCombo?

    func makeNSView(context: Context) -> KeyRecorderNSView {
        let view = KeyRecorderNSView()
        view.onKeyCombo = { combo in keyCombo = combo }
        return view
    }

    func updateNSView(_ nsView: KeyRecorderNSView, context: Context) {
        nsView.currentCombo = keyCombo
        nsView.onKeyCombo = { combo in keyCombo = combo }
        nsView.needsDisplay = true
    }
}

final class KeyRecorderNSView: NSView {
    var onKeyCombo: ((KeyCombo?) -> Void)?
    var currentCombo: KeyCombo?
    var isRecording = false

    private static let modifierOnlyCodes: Set<UInt16> = [
        UInt16(kVK_Command), UInt16(kVK_Shift), UInt16(kVK_Option), UInt16(kVK_Control),
        UInt16(kVK_RightCommand), UInt16(kVK_RightShift), UInt16(kVK_RightOption), UInt16(kVK_RightControl),
        UInt16(kVK_CapsLock), UInt16(kVK_Function)
    ]

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 120, height: 26) }
    override var wantsUpdateLayer: Bool { false }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }
        if event.keyCode == UInt16(kVK_Escape) {
            isRecording = false
            needsDisplay = true
            return
        }
        if Self.modifierOnlyCodes.contains(event.keyCode) { return }
        let combo = KeyCombo(
            keyCode: UInt32(event.keyCode),
            modifiers: KeyCombo.carbonModifiers(from: event.modifierFlags)
        )
        currentCombo = combo
        isRecording = false
        onKeyCombo?(combo)
        needsDisplay = true
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        needsDisplay = true
        return super.resignFirstResponder()
    }

    override func draw(_ dirtyRect: NSRect) {
        // Glass-style background: very subtle fill
        let bg = isRecording
            ? NSColor.controlAccentColor.withAlphaComponent(0.12)
            : NSColor.white.withAlphaComponent(0.08)
        bg.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).fill()

        // Border
        let borderAlpha: CGFloat = isRecording ? 0.6 : 0.2
        NSColor.white.withAlphaComponent(borderAlpha).setStroke()
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
        border.lineWidth = 1
        border.stroke()

        // Label text
        let (text, alpha): (String, CGFloat)
        if isRecording {
            text = "Type shortcut\u{2026}"
            alpha = 0.5
        } else if let combo = currentCombo {
            text = combo.displayString
            alpha = 0.9
        } else {
            text = "Click to record"
            alpha = 0.4
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.labelColor.withAlphaComponent(alpha)
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let sz = str.size()
        str.draw(at: CGPoint(
            x: (bounds.width - sz.width) / 2,
            y: (bounds.height - sz.height) / 2
        ))
    }
}
