import AppKit

/// Single source of truth for how SpeedRead presents itself (Dock + ⌘-Tab vs.
/// hidden background agent) and for what ⌘Q does.
///
/// Rules:
/// - `.regular` (Dock icon, ⌘-Tab entry, standard menu bar) whenever a real
///   window is visible.
/// - `.accessory` (no Dock icon, no ⌘-Tab) only when the app is running headless
///   because "Background Service" is on and at least one entry point (global
///   hotkey / menu-bar icon / right-click menu) is enabled.
/// - With Background Service off, ⌘Q and closing the last window terminate.
@MainActor
enum PresentationController {

    /// The app may stay alive after its last window closes only when the master
    /// toggle is on AND at least one entry point is enabled — otherwise there is
    /// nothing to stay resident for.
    static var shouldStayResident: Bool {
        let d = UserDefaults.standard
        return d.flag(Keys.backgroundServiceEnabled)
            && (d.flag(Keys.hotKeyEnabled)
                || d.flag(Keys.menuBarEnabled)
                || d.flag(Keys.serviceEnabled))
    }

    private static var isTerminating = false

    /// A "real" window is one the user could ⌘-Tab to — the Input, Reader, or
    /// Settings window. The `.titled` style-mask test keeps `MenuBarExtra`'s
    /// status-bar / popover windows from counting. `ignoring` excludes a window
    /// that is mid-close: `willClose` fires before `isVisible` flips to `false`.
    static func hasVisibleWindows(ignoring: NSWindow? = nil) -> Bool {
        NSApp.windows.contains { window in
            window !== ignoring
                && window.isVisible
                && window.styleMask.contains(.titled)
        }
    }

    /// Re-derive the activation policy from current state. No-ops once the app
    /// is on its way out so a late notification can't flash the Dock icon back.
    static func update(ignoring: NSWindow? = nil) {
        guard !isTerminating else { return }

        let target: NSApplication.ActivationPolicy =
            hasVisibleWindows(ignoring: ignoring)
                ? .regular
                : (shouldStayResident ? .accessory : .regular)

        guard NSApp.activationPolicy() != target else { return }
        NSApp.setActivationPolicy(target)
        if target == .regular {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// Call right before opening a window from a background / hotkey / Service
    /// path so the app is a normal foreground app by the time the window shows,
    /// without waiting on `didBecomeKeyNotification`.
    static func willShowWindow() {
        isTerminating = false
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    /// ⌘Q. Either quit for real, or (Background Service on) pause, close every
    /// window, and sink to a background agent.
    static func handleCloseRequest() {
        guard shouldStayResident else {
            terminate()
            return
        }
        AppRouter.shared.engine.pause()
        for window in NSApp.windows where window.canBecomeMain {
            window.close()
        }
        // One runloop tick so `isVisible` flips before we re-derive the policy;
        // also smooths the .regular → .accessory menu-bar handoff.
        DispatchQueue.main.async { update() }
    }

    /// The always-hard-quit path (menu-bar item, or ⌘Q with no reason to stay).
    static func terminate() {
        isTerminating = true
        NSApp.terminate(nil)
    }
}
