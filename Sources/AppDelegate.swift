import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let serviceProvider = ServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
        HotKeyManager.shared.start()
    }

    /// Keep running for the Service / hotkey even with every window closed.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
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
        guard let text = pboard.string(forType: .string), !text.isEmpty else {
            error?.pointee = "SpeedRead: no text was selected." as NSString
            return
        }
        Task { @MainActor in
            AppRouter.shared.speedRead(text: text)
        }
    }
}
