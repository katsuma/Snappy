import Carbon
import AppKit

private func makeFourCharCode(_ s: String) -> FourCharCode {
    var result: FourCharCode = 0
    for byte in s.utf8.prefix(4) {
        result = (result << 8) | FourCharCode(byte)
    }
    return result
}

final class HotkeyManager {
    static let shared = HotkeyManager()

    private var registration: (ref: EventHotKeyRef, handler: () -> Void)?
    private var eventHandlerRef: EventHandlerRef?

    private init() {
        installEventHandler()
    }

    func set(combo: KeyCombo?, handler: @escaping () -> Void) {
        clear()
        guard let combo else { return }
        let hkID = EventHotKeyID(signature: makeFourCharCode("SNPY"), id: 1)
        var ref: EventHotKeyRef?
        let err = RegisterEventHotKey(combo.keyCode, combo.modifiers, hkID, GetApplicationEventTarget(), 0, &ref)
        guard err == noErr, let ref else { return }
        registration = (ref: ref, handler: handler)
    }

    func clear() {
        if let reg = registration {
            UnregisterEventHotKey(reg.ref)
            registration = nil
        }
    }

    private func installEventHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, eventRef, userData) -> OSStatus in
                guard let eventRef, let userData else {
                    return OSStatus(eventNotHandledErr)
                }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                return manager.handleEvent(eventRef)
            },
            1, &spec, selfPtr, &eventHandlerRef
        )
    }

    private func handleEvent(_ event: EventRef) -> OSStatus {
        var hkID = EventHotKeyID()
        let err = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hkID
        )
        guard err == noErr, hkID.id == 1 else { return err }
        DispatchQueue.main.async { self.registration?.handler() }
        return noErr
    }
}
