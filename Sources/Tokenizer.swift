import Foundation

/// Text preparation ported from the rapid-reader-extension `cleanText` helper,
/// plus whitespace tokenization.
enum Tokenizer {

    /// Normalizes dashes and strips footnote digits that trail a word.
    static func clean(_ text: String) -> String {
        var s = text

        // Surround en/em dashes with spaces so they become their own tokens.
        s = s.replacingOccurrences(
            of: "[\u{2013}\u{2014}]",
            with: " $0 ",
            options: .regularExpression
        )

        // Remove footnote/superscript digits directly after a letter (optionally
        // after a single punctuation mark): "word.12" -> "word.", "cases3" -> "cases".
        if let re = try? NSRegularExpression(pattern: "(?<=\\p{L}[.,;:!?]?)\\d+") {
            let range = NSRange(s.startIndex..., in: s)
            s = re.stringByReplacingMatches(in: s, range: range, withTemplate: "")
        }

        return s
    }

    /// Splits cleaned text into display words on any run of whitespace.
    static func tokenize(_ text: String) -> [String] {
        clean(text)
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}

/// Optimal Recognition Point: which character of a word to pin and tint.
enum ORP {
    static func pivotIndex(of word: String) -> Int {
        switch word.count {
        case 0, 1: return 0
        case 2...5: return 1
        case 6...9: return 2
        case 10...13: return 3
        default: return 4
        }
    }

    /// Splits a word into (before, pivot, after) around the ORP character.
    static func split(_ word: String) -> (String, String, String) {
        let chars = Array(word)
        guard !chars.isEmpty else { return ("", "", "") }
        let p = min(pivotIndex(of: word), chars.count - 1)
        return (
            String(chars[0..<p]),
            String(chars[p]),
            String(chars[(p + 1)...])
        )
    }
}
