# Changelog

## [Unreleased]

### Changed
- SpeedRead runs as a normal windowed app again: it appears in the Dock and the
  ⌘-Tab switcher whenever it has a window open, and drops out of both only while
  running headless as a background agent.
- ⌘Q now quits SpeedRead completely, unless **Background Service** is on — then it
  closes the windows and keeps the app resident in the background.

### Added
- **Background Service** setting: the master toggle for whether SpeedRead keeps
  running after its window is closed. The global shortcut, menu bar icon, and
  right-click entry are grouped under it — they work while a window is open
  regardless, and persist in the background only when Background Service is on.
  If Background Service is on but none of the three are enabled, ⌘Q just quits.
- First launch opens Settings once so you can choose how SpeedRead runs.
- Settings button (gear) in the main window's toolbar.
- Startup & Integration toggles in Settings: launch at login (`SMAppService`),
  show in menu bar, add the right-click Services entry, enable the global shortcut.
  Each takes effect immediately.
- RSVP reader: one word at a time with a pinned Optimal Recognition Point pivot.
- Speed slider (100–800 WPM), adjustable live during playback.
- Transport: play/pause, rewind, restart, step, drag-to-seek progress bar.
- Reader keyboard shortcuts: Space, ←/→, R.
- macOS Service: "speedRead" on selected text in any app.
- Configurable global hotkey (default ⇧⌥⌘T) with pasteboard-safe selection capture.
- Settings: default speed, rewind distance, punctuation pauses, word size, theme,
  accent color, hotkey.
- System appearance matching, plus an accent-color menu (System or any of the
  macOS accent colors: blue, purple, pink, red, orange, yellow, green, graphite).
- Menu bar item; app keeps running for the Service/hotkey after windows close.
- Universal (Apple Silicon + Intel) build and DMG packaging.
