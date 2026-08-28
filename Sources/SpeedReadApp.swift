import SwiftUI
import AppKit

@main
struct SpeedReadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(Keys.menuBarEnabled) private var menuBarEnabled = true

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

            // ⌘Q quits for real — unless "Background Service" is on, in which
            // case it closes every window and sinks to a background agent so
            // the hotkey / menu bar / right-click entry keep working.
            CommandGroup(replacing: .appTermination) {
                Button("Quit SpeedRead") {
                    PresentationController.handleCloseRequest()
                }
                .keyboardShortcut("q", modifiers: .command)
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

        MenuBarExtra("SpeedRead", systemImage: "forward.fill", isInserted: $menuBarEnabled) {
            Button("Open SpeedRead") { AppRouter.shared.openMainWindow() }
            Button("Speed Read Clipboard") { AppRouter.shared.speedReadClipboard() }
            Divider()
            SettingsLink { Text("Settings…") }
            Button("Quit SpeedRead") { PresentationController.terminate() }
                .keyboardShortcut("q", modifiers: [.command, .shift])
        }
    }
}
