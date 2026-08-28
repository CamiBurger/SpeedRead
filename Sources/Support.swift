import SwiftUI

/// UserDefaults keys shared across the app.
enum Keys {
    static let defaultWPM = "defaultWPM"
    static let rewindWords = "rewindWords"
    static let punctuationPauses = "punctuationPauses"
    static let fontSize = "fontSize"
    static let appearance = "appearance"
    static let hotKeyCode = "hotKeyCode"
    static let hotKeyMods = "hotKeyMods"
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
}
