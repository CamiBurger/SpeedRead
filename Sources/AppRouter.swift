import SwiftUI
import AppKit
import Observation

/// Central coordinator: owns the shared `ReaderEngine`, receives text from the
/// input screen / Service / global hotkey, and raises the Reader window.
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    let engine = ReaderEngine()

    /// Set by the main window's root view once it can open sibling windows.
    @ObservationIgnored private var openWindowAction: ((String) -> Void)?

    /// Text captured before a window existed to display it.
    @ObservationIgnored private var pendingText: String?

    private init() {}

    func registerOpenWindow(_ action: @escaping (String) -> Void) {
        openWindowAction = action
        flushPending()
    }

    /// Start reading `text`, creating/raising the Reader window.
    func speedRead(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        engine.load(text: text)

        guard let open = openWindowAction else {
            // App just launched from the Service; the main window's onAppear
            // will call registerOpenWindow -> flushPending().
            pendingText = text
            return
        }

        PresentationController.willShowWindow()
        open("reader")
        engine.play()
    }

    func speedReadClipboard() {
        if let s = NSPasteboard.general.string(forType: .string) {
            speedRead(text: s)
        }
    }

    func openMainWindow() {
        PresentationController.willShowWindow()
        openWindowAction?("main")
    }

    private func flushPending() {
        guard let text = pendingText, let open = openWindowAction else { return }
        pendingText = nil
        engine.load(text: text)
        PresentationController.willShowWindow()
        open("reader")
        engine.play()
    }
}
