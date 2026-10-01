# Changelog

All notable changes to DefaultBrowserChanger will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-10-01

### Added
- **Settings Window (`SettingsView` / `SettingsController`):**
  - Native macOS SwiftUI preferences window accessible from Menu Bar (`Settings...` or <kbd>⌘</kbd>+<kbd>,</kbd>).
  - Clean card-based interface with installed browsers list, quick toggles, and shortcut customization.
- **Browser Switch List Filtering:**
  - Checkbox selection allowing users to choose exactly which browsers participate in the cycle shortcut list.
  - Interactive full-row clicking with real high-resolution app icons.
  - "Select All" button and dynamic counter indicator (`X of Y browsers active`).
  - Safety guard preventing accidental deselect of all browsers (at least one browser remains active).
  - Selection automatically persists across launches in `UserDefaults`.
- **Customizable Global Shortcut (`ShortcutRecorderView`):**
  - Dedicated interactive shortcut recorder capturing any combination of modifier keys (<kbd>⌃</kbd>, <kbd>⌥</kbd>, <kbd>⇧</kbd>, <kbd>⌘</kbd>) and standard or function keys (<kbd>F1</kbd>-<kbd>F12</kbd>, <kbd>Space</kbd>, etc.).
  - Replaces hardcoded shortcut with user-defined hotkeys registered directly via Carbon event dispatcher.
  - Live recording state indicator ("Recording...") with <kbd>Esc</kbd> to cancel and reset button (<kbd>↺</kbd>) to restore default.
  - Menu item and notification messages dynamically update to display the user's custom shortcut.
- **On-Screen Floating HUD Bezel (`HUDController`):**
  - Instant visual feedback HUD pill appearing at the top-center of the screen when switching browsers via shortcut.
  - Displays the active browser's real high-resolution icon and name with smooth animation and automatic 1.2-second dismiss.
  - Solves visual feedback gaps when system notifications are muted or disabled.

### Changed
- Refactored `LinkRouter.cycleNextBrowser` and `BrowserManager.cycleNextDefaultBrowser` to respect enabled cycle browser filters.
- Reduced hotkey debounce interval to 0.35s for snappy consecutive browser cycling.
- Updated Menu Bar menu to display active custom shortcut combination dynamically.

### Fixed
- Fixed keyboard event capture in SwiftUI settings window using `ShortcutRecorderNSView` with direct first-responder handling.
- Fixed key code 0 mapping (letter 'A') and Carbon modifier flag persistence.

---

## [1.1.1] - 2026-09-28

### Added
- Landing page documentation and GitHub Pages deployment.
- High-resolution app icon assets and Retina display support.

### Fixed
- AppleScript automation multi-window dismissal loop and hotkey debounce.

---

## [1.1.0] - 2026-09-28

### Added
- Link routing architecture (0.001s native URL interception).
- Global keyboard shortcut cycling (`⌃⌥B`).
- Onboarding guide and welcome card.

---

## [1.0.0] - 2026-09-28

### Added
- Initial release of DefaultBrowserChanger for macOS.
- Menu bar status item with installed browser detection.
- Launch at Login support via `SMAppService`.
