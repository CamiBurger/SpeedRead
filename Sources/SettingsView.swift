import SwiftUI
import AppKit
import Carbon.HIToolbox

struct SettingsView: View {
    @AppStorage(Keys.defaultWPM) private var defaultWPM: Double = Defaults.wpm
    @AppStorage(Keys.rewindWords) private var rewindWords: Int = Defaults.rewindWords
    @AppStorage(Keys.punctuationPauses) private var punctuationPauses: Bool = Defaults.punctuationPauses
    @AppStorage(Keys.fontSize) private var fontSize: Double = Defaults.fontSize
    @AppStorage(Keys.appearance) private var appearance: Appearance = .system
    @AppStorage(Keys.accent) private var accent: AccentChoice = .system
    @AppStorage(Keys.hotKeyEnabled) private var hotKeyEnabled = true
    @AppStorage(Keys.serviceEnabled) private var serviceEnabled = true
    @AppStorage(Keys.menuBarEnabled) private var menuBarEnabled = true
    @AppStorage(Keys.backgroundServiceEnabled) private var backgroundServiceEnabled = true

    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Section("Reading") {
                VStack(alignment: .leading) {
                    Text("Default speed: \(Int(defaultWPM)) WPM")
                    Slider(value: $defaultWPM, in: 100...800, step: 10)
                }
                Stepper("Rewind distance: \(rewindWords) words", value: $rewindWords, in: 1...50)
                Toggle("Pause longer on punctuation", isOn: $punctuationPauses)
                VStack(alignment: .leading) {
                    Text("Word size: \(Int(fontSize)) pt")
                    Slider(value: $fontSize, in: 24...120, step: 2)
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: $appearance) {
                    ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("Accent color", selection: $accent) {
                    ForEach(AccentChoice.allCases) { choice in
                        HStack {
                            Circle()
                                .fill(choice.swatch)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().strokeBorder(.primary.opacity(0.15)))
                            Text(choice.label)
                        }
                        .tag(choice)
                    }
                }

                Text("“System” follows the macOS appearance and accent color; the other accents override it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Background Service") {
                Toggle("Keep SpeedRead running in the background", isOn: $backgroundServiceEnabled)
                    .onChange(of: backgroundServiceEnabled) { _, _ in PresentationController.update() }
                Text("When on, SpeedRead keeps running after you close its window (⌘Q) so the options below stay active in the background. When off, ⌘Q quits SpeedRead completely and those options only work while a SpeedRead window is open.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Global keyboard shortcut", isOn: $hotKeyEnabled)
                        .onChange(of: hotKeyEnabled) { _, on in
                            HotKeyManager.shared.setEnabled(on)
                            PresentationController.update()
                        }
                    HotKeyRecorder()
                        .disabled(!hotKeyEnabled)
                    Text("Select text in any app, then press this shortcut. The first use asks for Accessibility permission so SpeedRead can copy the selection.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("Menu bar icon", isOn: $menuBarEnabled)
                        .onChange(of: menuBarEnabled) { _, _ in PresentationController.update() }

                    Toggle("Add “speedRead” to the right‑click menu", isOn: $serviceEnabled)
                        .onChange(of: serviceEnabled) { _, on in
                            ServiceGate.apply(enabled: on)
                            PresentationController.update()
                        }
                    if !serviceEnabled {
                        Button("Open Services settings…") { ServiceGate.openSystemSettings() }
                            .font(.caption)
                    }
                }
                .padding(.leading, 12)
            }

            Section("Startup") {
                Toggle("Launch SpeedRead at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in
                        if !LoginItem.setEnabled(on) { launchAtLogin = LoginItem.isEnabled }
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Minimal shortcut recorder: click, then press a key combo. Captures the AppKit
/// key code + modifier flags and hands them to `HotKeyManager`.
struct HotKeyRecorder: View {
    @AppStorage(Keys.hotKeyCode) private var keyCode: Int = Int(HotKeyManager.defaultKeyCode)
    @AppStorage(Keys.hotKeyMods) private var modifiers: Int = Int(HotKeyManager.defaultModifiers)

    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack {
            Text("Shortcut")
            Spacer()
            Button(recording ? "Press keys…" : label) {
                recording ? stop() : start()
            }
            .frame(minWidth: 150)
        }
        .onDisappear(perform: stop)
    }

    private var label: String {
        modifierSymbols(carbonMods: UInt32(modifiers)) + keyName(forVirtualKey: UInt16(keyCode))
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let carbonMods = carbonModifiers(from: event.modifierFlags)
            guard carbonMods != 0 else { return event }   // require at least one modifier
            keyCode = Int(event.keyCode)
            modifiers = Int(carbonMods)
            HotKeyManager.shared.setHotKey(keyCode: UInt32(event.keyCode), modifiers: carbonMods)
            stop()
            return nil
        }
    }

    private func stop() {
        recording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var result: UInt32 = 0
    if flags.contains(.command) { result |= UInt32(cmdKey) }
    if flags.contains(.option) { result |= UInt32(optionKey) }
    if flags.contains(.control) { result |= UInt32(controlKey) }
    if flags.contains(.shift) { result |= UInt32(shiftKey) }
    return result
}

private func modifierSymbols(carbonMods: UInt32) -> String {
    var s = ""
    if carbonMods & UInt32(controlKey) != 0 { s += "⌃" }
    if carbonMods & UInt32(optionKey) != 0 { s += "⌥" }
    if carbonMods & UInt32(shiftKey) != 0 { s += "⇧" }
    if carbonMods & UInt32(cmdKey) != 0 { s += "⌘" }
    return s
}

private func keyName(forVirtualKey keyCode: UInt16) -> String {
    let specials: [UInt16: String] = [
        UInt16(kVK_Space): "Space", UInt16(kVK_Return): "↩", UInt16(kVK_Tab): "⇥",
        UInt16(kVK_Escape): "⎋", UInt16(kVK_Delete): "⌫",
        UInt16(kVK_LeftArrow): "←", UInt16(kVK_RightArrow): "→",
        UInt16(kVK_UpArrow): "↑", UInt16(kVK_DownArrow): "↓",
    ]
    if let name = specials[keyCode] { return name }

    guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
          let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
    else { return "?" }

    let data = Unmanaged<CFData>.fromOpaque(layoutData).takeUnretainedValue() as Data
    var deadKeyState: UInt32 = 0
    var chars = [UniChar](repeating: 0, count: 4)
    var length = 0

    let status = data.withUnsafeBytes { raw -> OSStatus in
        guard let ptr = raw.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return -1 }
        return UCKeyTranslate(
            ptr, keyCode, UInt16(kUCKeyActionDisplay), 0,
            UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState, chars.count, &length, &chars
        )
    }
    guard status == noErr, length > 0 else { return "?" }
    return String(utf16CodeUnits: chars, count: length).uppercased()
}
