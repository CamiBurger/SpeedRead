import SwiftUI
import Observation

/// Drives RSVP playback: holds the word list, the cursor, and an async timing loop.
@MainActor
@Observable
final class ReaderEngine {

    private(set) var words: [String] = []
    private(set) var index: Int = 0
    private(set) var isPlaying = false

    /// Live reading speed. The playback loop re-reads this every tick, so dragging
    /// the slider mid-playback takes effect immediately without a restart.
    var wpm: Double = UserDefaults.standard.effectiveDefaultWPM

    private var loop: Task<Void, Never>?

    // MARK: Derived state

    var currentWord: String { words.indices.contains(index) ? words[index] : "" }
    var count: Int { words.count }
    var isEmpty: Bool { words.isEmpty }

    var progress: Double {
        guard words.count > 1 else { return words.isEmpty ? 0 : 1 }
        return Double(index) / Double(words.count - 1)
    }

    var wordsRemaining: Int { max(words.count - index - 1, 0) }

    var secondsRemaining: Int {
        guard wpm > 0 else { return 0 }
        return Int((Double(wordsRemaining) / wpm) * 60)
    }

    var isFinished: Bool { !words.isEmpty && index >= words.count - 1 }

    // MARK: Loading

    func load(text: String) {
        pause()
        words = Tokenizer.tokenize(text)
        index = 0
        wpm = UserDefaults.standard.effectiveDefaultWPM
    }

    // MARK: Transport

    func play() {
        guard !words.isEmpty, !isPlaying else { return }
        if isFinished { index = 0 }
        isPlaying = true
        loop = Task { [weak self] in await self?.run() }
    }

    func pause() {
        isPlaying = false
        loop?.cancel()
        loop = nil
    }

    func toggle() { isPlaying ? pause() : play() }

    func restart() {
        pause()
        index = 0
    }

    func rewind() {
        index = max(index - UserDefaults.standard.effectiveRewindWords, 0)
    }

    func step(_ delta: Int) {
        pause()
        guard !words.isEmpty else { return }
        index = min(max(index + delta, 0), words.count - 1)
    }

    func seek(toFraction fraction: Double) {
        guard !words.isEmpty else { return }
        let f = min(max(fraction, 0), 1)
        index = Int((Double(words.count - 1) * f).rounded())
    }

    // MARK: Loop

    private func run() async {
        while isPlaying, index < words.count {
            let delay = delayForCurrentWord()
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }
            guard isPlaying else { return }
            if index >= words.count - 1 {
                isPlaying = false
                return
            }
            index += 1
        }
        isPlaying = false
    }

    private func delayForCurrentWord() -> Double {
        let base = 60.0 / max(wpm, 1)
        guard UserDefaults.standard.punctuationPausesEnabled else { return base }

        var factor = 1.0
        if let last = currentWord.unicodeScalars.last {
            if CharacterSet(charactersIn: ",;:").contains(last) {
                factor = 1.5
            } else if CharacterSet(charactersIn: ".!?\u{2026}").contains(last) {
                factor = 2.0
            }
        }
        // Give longer words a little more time on screen.
        let n = currentWord.count
        if n > 8 { factor *= 1.0 + Double(n - 8) * 0.04 }

        return base * factor
    }
}
