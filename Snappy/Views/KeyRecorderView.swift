import SwiftUI
import AppKit
import Carbon

struct KeyRecorderView: NSViewRepresentable {
    @Binding var keyCombo: KeyCombo?

    func makeNSView(context: Context) -> KeyRecorderNSView {
        let view = KeyRecorderNSView()
        view.onKeyCombo = { combo in
            keyCombo = combo
        }
        return view
    }

    func updateNSView(_ nsView: KeyRecorderNSView, context: Context) {
        nsView.currentCombo = keyCombo
        nsView.onKeyCombo = { combo in
            keyCombo = combo
        }
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
        // Background
        NSColor.controlBackgroundColor.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4).fill()

        // Border
        let borderColor = isRecording ? NSColor.controlAccentColor : NSColor.separatorColor
        borderColor.setStroke()
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4)
        border.lineWidth = 1
        border.stroke()

        // Recording highlight
        if isRecording {
            NSColor.controlAccentColor.withAlphaComponent(0.1).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4).fill()
        }

        // Label
        let (text, color): (String, NSColor)
        if isRecording {
            text = "Type shortcut\u{2026}"
            color = .secondaryLabelColor
        } else if let combo = currentCombo {
            text = combo.displayString
            color = .labelColor
        } else {
            text = "Click to record"
            color = .placeholderTextColor
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: color
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let sz = str.size()
        str.draw(at: CGPoint(
            x: (bounds.width - sz.width) / 2,
            y: (bounds.height - sz.height) / 2
        ))
    }
}
