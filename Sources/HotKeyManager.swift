import AppKit
import Carbon.HIToolbox

/// Registers a system-wide hotkey via the Carbon `RegisterEventHotKey` API,
/// which — unlike an `NSEvent` global monitor — needs no Input Monitoring grant.
final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var handlerInstalled = false

    static let defaultKeyCode = UInt32(kVK_ANSI_R)
    static let defaultModifiers = UInt32(cmdKey | optionKey)

    private init() {}

    func start() {
        installHandlerIfNeeded()
        reregister()
    }

    var currentKeyCode: UInt32 {
        let v = UserDefaults.standard.object(forKey: Keys.hotKeyCode) as? Int
        return v.map(UInt32.init) ?? Self.defaultKeyCode
    }

    var currentModifiers: UInt32 {
        let v = UserDefaults.standard.object(forKey: Keys.hotKeyMods) as? Int
        return v.map(UInt32.init) ?? Self.defaultModifiers
    }

    func setHotKey(keyCode: UInt32, modifiers: UInt32) {
        UserDefaults.standard.set(Int(keyCode), forKey: Keys.hotKeyCode)
        UserDefaults.standard.set(Int(modifiers), forKey: Keys.hotKeyMods)
        reregister()
    }

    private func reregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        let hotKeyID = EventHotKeyID(signature: fourCharCode("SPRD"), id: 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            currentKeyCode,
            currentModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr { hotKeyRef = ref }
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ -> OSStatus in
                DispatchQueue.main.async { HotKeyManager.shared.fired() }
                return noErr
            },
            1,
            &spec,
            nil,
            &handlerRef
        )
    }

    @MainActor
    private func fired() {
        SelectionReader.grabSelectedText { text in
            guard let text, !text.isEmpty else { return }
            AppRouter.shared.speedRead(text: text)
        }
    }
}

private func fourCharCode(_ string: String) -> FourCharCode {
    var code: FourCharCode = 0
    for scalar in string.unicodeScalars.prefix(4) {
        code = (code << 8) + FourCharCode(scalar.value & 0xFF)
    }
    return code
}
