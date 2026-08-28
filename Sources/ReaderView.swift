import SwiftUI

struct ReaderView: View {
    @Bindable private var engine = AppRouter.shared.engine
    @AppStorage(Keys.fontSize) private var fontSize: Double = Defaults.fontSize

    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 20) {
            if engine.isEmpty {
                Spacer()
                Text("Nothing loaded yet.\nPaste text in the main window and press Speed Read.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                Spacer()
                pivotDisplay
                Spacer()
                progressBar
                statusLine
                controls
            }
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 340)
        .background(Color(nsColor: .windowBackgroundColor))
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        .onKeyPress(.space) { engine.toggle(); return .handled }
        .onKeyPress(.leftArrow) { engine.step(-1); return .handled }
        .onKeyPress(.rightArrow) { engine.step(1); return .handled }
        .onKeyPress(keys: ["r"]) { _ in engine.restart(); return .handled }
    }

    // MARK: Pieces

    private var pivotDisplay: some View {
        let parts = ORP.split(engine.currentWord)
        return ZStack {
            VStack {
                Rectangle().frame(width: 2, height: 14)
                Spacer()
                Rectangle().frame(width: 2, height: 14)
            }
            .foregroundStyle(.secondary.opacity(0.35))
            .frame(height: fontSize * 2.2)

            HStack(spacing: 0) {
                Text(parts.0)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(parts.1)
                    .foregroundStyle(.red)
                    .fixedSize()
                Text(parts.2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: fontSize, weight: .regular, design: .monospaced))
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(.tint)
                    .frame(width: max(0, geo.size.width * engine.progress))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        engine.pause()
                        engine.seek(toFraction: value.location.x / geo.size.width)
                    }
            )
        }
        .frame(height: 8)
    }

    private var statusLine: some View {
        HStack {
            Text("\(engine.index + 1) / \(engine.count)")
            Spacer()
            Text("\(engine.wordsRemaining) left · \(mmss(engine.secondsRemaining))")
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
    }

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 22) {
                iconButton("backward.end.fill", "Restart") { engine.restart() }
                iconButton("gobackward", "Rewind") { engine.rewind() }
                iconButton(engine.isPlaying ? "pause.fill" : "play.fill",
                           engine.isPlaying ? "Pause" : "Play") { engine.toggle() }
                    .font(.system(size: 30))
                iconButton("forward.fill", "Step forward") { engine.step(1) }
            }

            HStack(spacing: 10) {
                Image(systemName: "tortoise.fill").foregroundStyle(.secondary)
                Slider(value: $engine.wpm, in: 100...800, step: 10)
                Image(systemName: "hare.fill").foregroundStyle(.secondary)
                Text("\(Int(engine.wpm)) WPM")
                    .font(.callout.monospacedDigit())
                    .frame(width: 80, alignment: .trailing)
            }
        }
    }

    private func iconButton(_ symbol: String, _ help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
        }
        .buttonStyle(.borderless)
        .font(.system(size: 22))
        .help(help)
    }
}
