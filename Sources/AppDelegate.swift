import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let serviceProvider = ServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = serviceProvider
        UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows": false])
        ServiceGate.apply(enabled: UserDefaults.standard.flag(Keys.serviceEnabled))
        HotKeyManager.shared.start()

        let center = NotificationCenter.default
        center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { PresentationController.update() }
        }
        // Must run synchronously and exclude the closing window: `willClose`
        // fires before `isVisible` flips, so a deferred check would still see
        // the window and re-assert `.regular`.
        center.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: .main) { note in
            let closing = note.object as? NSWindow
            MainActor.assumeIsolated { PresentationController.update(ignoring: closing) }
        }

        PresentationController.update()
    }

    /// Terminate on last-window-close unless the app is meant to stay resident
    /// as a background agent.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        MainActor.assumeIsolated { !PresentationController.shouldStayResident }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            MainActor.assumeIsolated { AppRouter.shared.openMainWindow() }
        }
        return true
    }
}

/// Target of the `NSServices` entry in Info.plist. `NSMessage` == `speedReadService`.
final class ServiceProvider: NSObject {
    @objc func speedReadService(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) {
        guard UserDefaults.standard.flag(Keys.serviceEnabled) else {
            error?.pointee = "SpeedRead's right-click entry is turned off in its settings." as NSString
            return
        }
        guard let text = pboard.string(forType: .string), !text.isEmpty else {
            error?.pointee = "SpeedRead: no text was selected." as NSString
            return
        }
        Task { @MainActor in
            AppRouter.shared.speedRead(text: text)
        }
    }
}
