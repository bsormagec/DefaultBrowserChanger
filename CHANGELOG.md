# Changelog

All notable changes to DefaultBrowserChanger will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Faster link routing:** The installed browser list is now cached instead of being rebuilt for every link. A full scan took about 60–200 ms (LaunchServices plus reading Chromium profile files). The list refreshes whenever the menu or Settings opens, or from **Refresh Browsers**.

### Fixed
- **Possible link loop:** If the chosen browser failed to open a link, the link was handed to the system default browser — which is DefaultBrowserChanger itself — so it could bounce back and retry endlessly. Failed links now fall back to Safari, and if Safari fails too, the app beeps instead of retrying.

---

## [1.6.0] - 2026-11-15

### Added
- **Clean Links (`LinkCleaner`):** On by default; toggle under **Settings → General**.
  - Removes tracking parameters such as `utm_*`, `fbclid`, `gclid`, `msclkid`, `mc_eid` and `_hsenc`. Links without tracking keep their exact original form.
  - Unwraps redirect links from Outlook SafeLinks, Google (`/url`), Facebook and Messenger (`l.php`), Instagram, Slack (`slack-redir.net`) and YouTube (`/redirect`), including nested ones. Only `http`/`https` destinations are unwrapped.
  - Cleaning runs before Link Rules and the ⌥ picker, so rules match the real destination instead of the redirect host.
- `Tests/TestLinkCleaner.swift`, run in CI and release workflows.

### Changed
- Settings window is slightly taller to fit the new toggle.

---

## [1.5.0] - 2026-11-14

### Added
- **Chromium Profile Support (`ChromiumProfiles`):**
  - Chrome (stable, Beta, Dev, Canary), Brave, Edge, Vivaldi, Chromium and Comet browsers with two or more profiles get one extra entry per profile, e.g. "Google Chrome — Work".
  - Profile entries work everywhere a browser does: the menu bar list, the cycle shortcut, Link Rules, and the ⌥ picker.
  - Links open in the chosen profile via `--profile-directory`, even when the browser is already running.
  - The plain browser entry stays and still opens the browser's last-used profile, so existing settings keep working.
- `Tests/TestChromiumProfiles.swift` covering profile parsing and ordering, run in CI and release workflows.

### Fixed
- The empty Link Rules list in Settings now spans the full width.

---

## [1.4.0] - 2026-11-14

### Added
- **⌥ Browser Picker:** Hold <kbd>⌥ Option</kbd> while clicking a link to choose a browser for that link only. A menu with every installed browser appears at the mouse pointer, with the browser the link would have gone to checked. The choice overrides Link Rules and doesn't change the active browser. Press <kbd>Esc</kbd> to cancel without opening the link.

---

## [1.3.0] - 2026-11-14

### Added
- **Link Rules (`DomainRule`):**
  - Send links for specific sites to a specific browser, overriding the active browser.
  - Pattern forms: `github.com` (domain and all subdomains), `*.atlassian.net`, and `github.com/work-org` (path prefix).
  - First matching rule wins; if a rule's browser is no longer installed, links fall back to the active browser.
  - New **Link Rules** section in the Settings window to add, edit, and remove rules. Rules persist in `UserDefaults`.
- `Tests/TestDomainRules.swift` covering rule matching, run in CI and release workflows.

### Changed
- Settings window is taller to fit the Link Rules section.
- `Info.plist` now declares `LSMinimumSystemVersion` 13.0 to match the build target.

### Fixed
- Landing page listed macOS 12 as the minimum; the app requires macOS 13 Ventura or newer.

---

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
