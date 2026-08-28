import SwiftUI

/// UserDefaults keys shared across the app.
enum Keys {
    static let defaultWPM = "defaultWPM"
    static let rewindWords = "rewindWords"
    static let punctuationPauses = "punctuationPauses"
    static let fontSize = "fontSize"
    static let appearance = "appearance"
    static let accent = "accent"
    static let hotKeyCode = "hotKeyCode"
    static let hotKeyMods = "hotKeyMods"
    static let hotKeyEnabled = "hotKeyEnabled"
    static let serviceEnabled = "serviceEnabled"
    static let menuBarEnabled = "menuBarEnabled"
}

/// Default values used when a key has never been written.
enum Defaults {
    static let wpm: Double = 300
    static let rewindWords: Int = 5
    static let punctuationPauses = true
    static let fontSize: Double = 64
}

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "Match System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Accent (tint) choice: "System" follows the macOS accent color; the rest are
/// the standard macOS accent palette.
enum AccentChoice: String, CaseIterable, Identifiable {
    case system, blue, purple, pink, red, orange, yellow, green, graphite
    var id: String { rawValue }

    var label: String {
        self == .system ? "System" : rawValue.capitalized
    }

    /// nil = let SwiftUI follow `NSColor.controlAccentColor`.
    var color: Color? {
        switch self {
        case .system:   return nil
        case .blue:     return Color(nsColor: .systemBlue)
        case .purple:   return Color(nsColor: .systemPurple)
        case .pink:     return Color(nsColor: .systemPink)
        case .red:      return Color(nsColor: .systemRed)
        case .orange:   return Color(nsColor: .systemOrange)
        case .yellow:   return Color(nsColor: .systemYellow)
        case .green:    return Color(nsColor: .systemGreen)
        case .graphite: return Color(nsColor: .systemGray)
        }
    }

    /// A concrete color for the settings swatch (resolves "System" to the live accent).
    var swatch: Color { color ?? Color(nsColor: .controlAccentColor) }
}

/// Applies the user's theme + accent choices to a scene's root view.
struct AppChrome: ViewModifier {
    @AppStorage(Keys.appearance) private var appearance: Appearance = .system
    @AppStorage(Keys.accent) private var accent: AccentChoice = .system

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(appearance.colorScheme)
            .tint(accent.color)
    }
}

extension View {
    func appChrome() -> some View { modifier(AppChrome()) }
}

func mmss(_ seconds: Int) -> String {
    let s = max(seconds, 0)
    return String(format: "%d:%02d", s / 60, s % 60)
}

extension UserDefaults {
    var effectiveDefaultWPM: Double {
        let v = double(forKey: Keys.defaultWPM)
        return v > 0 ? v : Defaults.wpm
    }
    var effectiveRewindWords: Int {
        let v = integer(forKey: Keys.rewindWords)
        return v > 0 ? v : Defaults.rewindWords
    }
    var punctuationPausesEnabled: Bool {
        object(forKey: Keys.punctuationPauses) == nil ? Defaults.punctuationPauses : bool(forKey: Keys.punctuationPauses)
    }

    /// Bool that defaults to `true` when the key has never been written.
    func flag(_ key: String) -> Bool {
        object(forKey: key) == nil ? true : bool(forKey: key)
    }
}
