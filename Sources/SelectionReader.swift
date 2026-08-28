import AppKit
import Carbon.HIToolbox

/// Copies the current selection out of the frontmost app by synthesizing ⌘C,
/// reading the pasteboard, then restoring the previous pasteboard contents.
/// Requires Accessibility permission to post the keystroke.
enum SelectionReader {

    static func grabSelectedText(completion: @escaping (String?) -> Void) {
        guard PermissionsHelper.ensureAccessibility() else {
            completion(nil)
            return
        }

        let pasteboard = NSPasteboard.general
        let saved = snapshot(of: pasteboard)
        let changeCountBefore = pasteboard.changeCount

        pasteboard.clearContents()
        postCommandC()

        // Give the frontmost app a beat to service the copy.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            let copied = pasteboard.changeCount != changeCountBefore
                ? pasteboard.string(forType: .string)
                : nil

            restore(saved, to: pasteboard)
            completion(copied)
        }
    }

    // MARK: Pasteboard preservation

    private static func snapshot(of pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        (pasteboard.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }
    }

    private static func restore(_ items: [NSPasteboardItem], to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        if !items.isEmpty {
            pasteboard.writeObjects(items)
        }
    }

    // MARK: Keystroke

    private static func postCommandC() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let cKey = CGKeyCode(kVK_ANSI_C)

        let down = CGEvent(keyboardEventSource: source, virtualKey: cKey, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: source, virtualKey: cKey, keyDown: false)
        up?.flags = .maskCommand

        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

enum PermissionsHelper {
    /// Returns true if the process is already trusted. Otherwise triggers the system
    /// prompt (shown only on the first-ever call) and always surfaces a visible
    /// alert, since a silently-failing hotkey is impossible for the user to diagnose.
    @discardableResult
    static func ensureAccessibility() -> Bool {
        if AXIsProcessTrusted() { return true }

        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)

        let alert = NSAlert()
        alert.messageText = "SpeedRead needs Accessibility permission"
        alert.informativeText = """
        To read the text you've selected in another app, SpeedRead has to copy it \
        for you. Turn on SpeedRead under System Settings → Privacy & Security → \
        Accessibility, then try the shortcut again.

        (If SpeedRead is already listed, remove it with “–” and re-add this copy — \
        the permission is tied to a specific build.)
        """
        alert.addButton(withTitle: "Open Accessibility Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
        return false
    }
}
