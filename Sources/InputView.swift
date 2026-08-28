import SwiftUI
import AppKit

struct InputView: View {
    @Environment(\.openWindow) private var openWindow
    @AppStorage(Keys.defaultWPM) private var defaultWPM: Double = Defaults.wpm

    @State private var text: String = ""

    private var wordCount: Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paste or type text, then speed read it one word at a time.")
                .font(.headline)

            TextEditor(text: $text)
                .font(.system(size: 13))
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor))
                )
                .frame(minHeight: 220)

            HStack(spacing: 12) {
                Text("Default speed \(Int(defaultWPM)) WPM")
                    .foregroundStyle(.secondary)
                Slider(value: $defaultWPM, in: 100...800, step: 10)
                    .frame(maxWidth: 220)
            }

            HStack {
                Text("\(wordCount) word\(wordCount == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                Spacer()
                Button("Paste Clipboard") {
                    if let s = NSPasteboard.general.string(forType: .string) { text = s }
                }
                Button("Speed Read") {
                    AppRouter.shared.speedRead(text: text)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(minWidth: 460, minHeight: 380)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
        .onAppear {
            AppRouter.shared.registerOpenWindow { openWindow(id: $0) }
        }
    }
}
