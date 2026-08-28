import SwiftUI

@main
struct SpeedReadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("SpeedRead", id: "main") {
            InputView()
                .appChrome()
        }
        .defaultSize(width: 560, height: 460)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Speed Read Clipboard Text") {
                    AppRouter.shared.speedReadClipboard()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }

        Window("Reader", id: "reader") {
            ReaderView()
                .appChrome()
        }
        .defaultSize(width: 760, height: 440)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
                .appChrome()
        }

        MenuBarExtra("SpeedRead", systemImage: "forward.fill") {
            Button("Open SpeedRead") { AppRouter.shared.openMainWindow() }
            Button("Speed Read Clipboard") { AppRouter.shared.speedReadClipboard() }
            Divider()
            SettingsLink { Text("Settings…") }
            Button("Quit SpeedRead") { NSApplication.shared.terminate(nil) }
        }
    }
}
