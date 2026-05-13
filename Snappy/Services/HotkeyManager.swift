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

    private var registrations: [UUID: (ref: EventHotKeyRef, handler: () -> Void)] = [:]
    private var eventHandlerRef: EventHandlerRef?
    private var nextID: UInt32 = 1
    private var idMap: [UInt32: UUID] = [:]

    private init() {
        installEventHandler()
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
        guard err == noErr else { return err }
        if let uuid = idMap[hkID.id], let reg = registrations[uuid] {
            DispatchQueue.main.async { reg.handler() }
        }
        return noErr
    }

    func register(shortcut: Shortcut, handler: @escaping () -> Void) {
        guard let combo = shortcut.keyCombo else { return }
        unregister(id: shortcut.id)

        let localID = nextID
        nextID += 1

        let hkID = EventHotKeyID(signature: makeFourCharCode("SNPY"), id: localID)
        var ref: EventHotKeyRef?
        let err = RegisterEventHotKey(
            combo.keyCode, combo.modifiers, hkID,
            GetApplicationEventTarget(), 0, &ref
        )
        guard err == noErr, let ref else { return }
        registrations[shortcut.id] = (ref: ref, handler: handler)
        idMap[localID] = shortcut.id
    }

    func unregister(id: UUID) {
        guard let reg = registrations.removeValue(forKey: id) else { return }
        UnregisterEventHotKey(reg.ref)
        idMap = idMap.filter { $0.value != id }
    }

    func reloadAll(shortcuts: [Shortcut], windowMover: WindowMover) {
        for id in Array(registrations.keys) { unregister(id: id) }
        for shortcut in shortcuts where shortcut.isEnabled
            && shortcut.keyCombo != nil
            && shortcut.gridRegion != nil
        {
            register(shortcut: shortcut) {
                windowMover.applyShortcut(shortcut)
            }
        }
    }
}
