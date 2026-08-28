import AppKit
import ServiceManagement

/// Wraps "Launch at login" via the modern `SMAppService` API (no helper bundle).
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    /// Returns false if the change could not be applied (e.g. running unsigned
    /// from a build folder); the caller should re-sync the toggle to `isEnabled`.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            switch (enabled, SMAppService.mainApp.status) {
            case (true, let s) where s != .enabled:  try SMAppService.mainApp.register()
            case (false, .enabled):                  try SMAppService.mainApp.unregister()
            default:                                 break
            }
            return true
        } catch {
            NSLog("SpeedRead: login item change failed — \(error.localizedDescription)")
            return false
        }
    }
}

/// Enables/disables the "speedRead" entry in the Services / right-click menu.
///
/// The entry is declared in Info.plist, so it can't be removed at runtime, but
/// `pbs` keeps a per-service enabled flag that both the Services menu and the
/// contextual menu honor. We write that flag and ask Launch Services to reload.
/// `ServiceProvider` also checks `Keys.serviceEnabled` as a backstop.
enum ServiceGate {
    private static var statusKey: String {
        let bid = Bundle.main.bundleIdentifier ?? "com.cami.SpeedRead"
        return "\(bid) - speedRead - speedReadService"
    }

    static func apply(enabled: Bool) {
        if let pbs = UserDefaults(suiteName: "pbs") {
            var status = pbs.dictionary(forKey: "NSServicesStatus") ?? [:]
            status[statusKey] = [
                "enabled_services_menu": enabled,
                "enabled_context_menu": enabled,
                "presentation_modes": [
                    "ServicesMenu": enabled,
                    "ContextMenu": enabled,
                ],
            ]
            pbs.set(status, forKey: "NSServicesStatus")
        }
        NSUpdateDynamicServices()
    }

    /// Opens System Settings where the user can also toggle app Services.
    static func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts") {
            NSWorkspace.shared.open(url)
        }
    }
}
