import AppKit
import Foundation

public class LinkRouter: NSObject {
    public static let shared = LinkRouter()

    private let activeBrowserKey = "activeTargetBrowserBundleId"

    public var activeBrowserId: String {
        get {
            if let saved = UserDefaults.standard.string(forKey: activeBrowserKey), !saved.isEmpty {
                return saved
            }
            // Fallback: pick current system default browser or Chrome
            if let detected = BrowserManager.shared.getCurrentDefaultBrowserBundleId(),
               detected != "com.bsormagec.DefaultBrowserChanger" {
                return detected
            }
            return "com.google.Chrome"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: activeBrowserKey)
        }
    }

    public override init() {
        super.init()
    }

    public func selectBrowser(bundleId: String) {
        activeBrowserId = bundleId
        SystemHelper.shared.playFeedbackSound()
    }

    private var lastRoutedURL: String?
    private var lastRoutedTime: Date?

    public struct Resolution {
        public let url: URL            // after link cleaning
        public let browser: BrowserApp?
        public let ruleIndex: Int?     // index into DomainRule.load(); nil = active browser
    }

    /// Where a link goes (without the ⌥ picker): cleaned first so rules see the real destination, then the
    /// first matching rule if its browser is still installed, otherwise the active browser.
    /// `rules` defaults to the saved rules; Settings passes its unsaved, in-progress list to the tester.
    public func resolve(_ url: URL, source: String? = nil, rules: [DomainRule]? = nil) -> Resolution {
        let cleaned = LinkCleaner.isEnabled ? LinkCleaner.clean(url) : url
        let browsers = BrowserManager.shared.fetchInstalledBrowsers()
        let rules = rules ?? DomainRule.load()
        if let index = DomainRule.firstMatchIndex(for: cleaned, source: source, in: rules),
           let browser = browsers.first(where: { $0.id == rules[index].browserId }) {
            return Resolution(url: cleaned, browser: browser, ruleIndex: index)
        }
        let activeId = activeBrowserId
        return Resolution(url: cleaned, browser: browsers.first { $0.id == activeId } ?? browsers.first, ruleIndex: nil)
    }

    // MARK: - Automation (dbc:// URLs)

    public func perform(_ command: AutomationCommand) {
        let browsers = BrowserManager.shared.fetchInstalledBrowsers()
        // Accept a bundle/profile id, or a display name for convenience ("Safari", "Google Chrome — Work").
        func find(_ key: String) -> BrowserApp? {
            browsers.first { $0.id == key } ?? browsers.first { $0.name.caseInsensitiveCompare(key) == .orderedSame }
        }

        switch command {
        case .select(let key):
            guard let browser = find(key) else {
                NSLog("LinkRouter: automation select: no browser matches %@", key)
                NSSound.beep()
                return
            }
            activeBrowserId = browser.id
            HUDController.shared.show(browser: browser)
        case .cycle:
            cycleNextBrowser { browser in
                if let browser = browser { HUDController.shared.show(browser: browser) }
            }
        case .open(let url, let key, let privateWindow):
            guard let key = key else {
                route(url: url)  // no browser given: rules and active browser apply as usual
                return
            }
            guard let browser = find(key) else {
                NSLog("LinkRouter: automation open: no browser matches %@", key)
                NSSound.beep()
                return
            }
            open(LinkCleaner.isEnabled ? LinkCleaner.clean(url) : url, in: browser, privateWindow: privateWindow)
        }
    }

    public func route(url: URL, source: String? = nil) {
        let now = Date()
        if let lastUrl = lastRoutedURL, lastUrl == url.absoluteString,
           let lastTime = lastRoutedTime, now.timeIntervalSince(lastTime) < 0.5 {
            NSLog("LinkRouter: Duplicate URL event ignored for %@", url.absoluteString)
            return
        }
        lastRoutedURL = url.absoluteString
        lastRoutedTime = now

        let resolution = resolve(url, source: source)
        let url = resolution.url
        NSLog("LinkRouter: Routing URL: %@ (from %@)", url.absoluteString, source ?? "unknown app")
        let browsers = BrowserManager.shared.fetchInstalledBrowsers()

        guard let targetBrowser = resolution.browser else {
            NSLog("LinkRouter: No target browser found, falling back to Safari")
            openInSafari(url)
            return
        }

        // Holding ⌥ while clicking a link: pick a browser for this one link (overrides rules).
        // Live WindowServer state: NSEvent.modifierFlags can be stale right after launch.
        if CGEventSource.flagsState(.combinedSessionState).contains(.maskAlternate) {
            showPicker(for: url, browsers: browsers, suggested: targetBrowser)
            return
        }

        open(url, in: targetBrowser)
    }

    // MARK: - Recent links

    /// Last 10 opened links, newest first. Memory only: never written to disk, gone when the app quits.
    public private(set) var recentLinks: [URL] = []

    private func remember(_ url: URL) {
        recentLinks.removeAll { $0 == url }
        recentLinks.insert(url, at: 0)
        if recentLinks.count > 10 { recentLinks.removeLast() }
    }

    public func clearRecentLinks() {
        recentLinks.removeAll()
    }

    /// Re-open a link in a specific browser, skipping rules (used by Recent Links).
    public func reopen(_ url: URL, inBrowserId id: String, privateWindow: Bool = false) {
        guard let browser = BrowserManager.shared.fetchInstalledBrowsers().first(where: { $0.id == id }) else { return }
        open(url, in: browser, privateWindow: privateWindow)
    }

    private func open(_ url: URL, in browser: BrowserApp, privateWindow: Bool = false) {
        if !privateWindow { remember(url) }  // private-window links stay out of the history
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        let completion: (NSRunningApplication?, Error?) -> Void = { _, error in
            if let error = error {
                NSLog("LinkRouter: Failed to open URL in %@: %@", browser.name, error.localizedDescription)
                if browser.id != Self.safariId {
                    self.openInSafari(url)
                } else {
                    DispatchQueue.main.async { NSSound.beep() }
                }
            } else {
                NSLog("LinkRouter: Successfully opened URL in %@", browser.name)
            }
        }

        var flags: [String] = []
        if let profile = browser.profileDirectory { flags.append("--profile-directory=\(profile)") }
        if privateWindow, let flag = browser.privateWindowFlag { flags.append(flag) }

        if !flags.isEmpty {
            // Same as `open -na <App> --args <flags> <url>`: a running Chromium/Firefox hands the
            // second launch's arguments to its existing process, which opens the profile/private window.
            config.createsNewApplicationInstance = true
            config.arguments = flags + [url.absoluteString]
            NSWorkspace.shared.openApplication(at: browser.bundleURL, configuration: config, completionHandler: completion)
        } else {
            NSWorkspace.shared.open([url], withApplicationAt: browser.bundleURL, configuration: config, completionHandler: completion)
        }
    }

    private static let safariId = "com.apple.Safari"

    /// Last resort when the chosen browser can't open a link. Never use `NSWorkspace.shared.open(url)`
    /// here: the system default browser is this app, so the link would come straight back in a loop.
    private func openInSafari(_ url: URL) {
        guard let safari = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.safariId) else {
            NSLog("LinkRouter: Safari not found, link not opened")
            NSSound.beep()
            return
        }
        NSWorkspace.shared.open([url], withApplicationAt: safari, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error = error {
                NSLog("LinkRouter: Safari fallback failed: %@", error.localizedDescription)
                DispatchQueue.main.async { NSSound.beep() }
            }
        }
    }

    private var pickedBrowserId: String?
    private var pickedPrivate = false

    private func showPicker(for url: URL, browsers: [BrowserApp], suggested: BrowserApp) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let header = NSMenuItem(title: "Open \(url.host ?? url.absoluteString) in…", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        var suggestedItem: NSMenuItem?
        for browser in browsers {
            let item = pickerItem(for: browser, privateWindow: false)
            if browser.id == suggested.id {
                item.state = .on
                suggestedItem = item
            }
            menu.addItem(item)
        }

        // Private windows: one entry per browser app (not per profile) that has a private-window flag.
        let privateCapable = browsers.filter { $0.profileDirectory == nil && $0.privateWindowFlag != nil }
        if !privateCapable.isEmpty {
            menu.addItem(.separator())
            let privateMenu = NSMenu()
            privateMenu.autoenablesItems = false
            privateCapable.forEach { privateMenu.addItem(pickerItem(for: $0, privateWindow: true)) }
            let privateItem = NSMenuItem(title: "Private Window", action: nil, keyEquivalent: "")
            privateItem.image = NSImage(systemSymbolName: "eyeglasses", accessibilityDescription: nil)
            showImage(of: privateItem)
            privateItem.submenu = privateMenu
            menu.addItem(privateItem)
        }

        pickedBrowserId = nil
        pickedPrivate = false
        NSApp.activate(ignoringOtherApps: true)
        // popUp blocks until the menu closes; the selected item's action fires before it returns.
        menu.popUp(positioning: suggestedItem, at: NSEvent.mouseLocation, in: nil)

        if let browser = browsers.first(where: { $0.id == pickedBrowserId }) {
            open(url, in: browser, privateWindow: pickedPrivate)
        } else {
            NSLog("LinkRouter: Picker dismissed, link not opened")
            NSApp.hide(nil) // hand focus back to the app the link came from
        }
    }

    private func pickerItem(for browser: BrowserApp, privateWindow: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: browser.name, action: #selector(pickerItemSelected(_:)), keyEquivalent: "")
        item.target = self
        item.image = browser.icon
        showImage(of: item)
        item.representedObject = browser.id
        item.tag = privateWindow ? 1 : 0
        return item
    }

    /// macOS 27+ hides menu item images unless asked (same approach as MenuBarController).
    private func showImage(of item: NSMenuItem) {
        if item.responds(to: Selector(("setPreferredImageVisibility:"))) {
            item.setValue(1, forKey: "preferredImageVisibility")
        }
    }

    @objc private func pickerItemSelected(_ sender: NSMenuItem) {
        pickedBrowserId = sender.representedObject as? String
        pickedPrivate = sender.tag == 1
    }

    public func cycleNextBrowser(completion: ((BrowserApp?) -> Void)? = nil) {
        let browsers = BrowserManager.shared.fetchCycleBrowsers()
        guard !browsers.isEmpty else {
            completion?(nil)
            return
        }

        let currentId = activeBrowserId
        let nextBrowser: BrowserApp

        if let currentIndex = browsers.firstIndex(where: { $0.id == currentId }) {
            let nextIndex = (currentIndex + 1) % browsers.count
            nextBrowser = browsers[nextIndex]
        } else {
            nextBrowser = browsers[0]
        }

        activeBrowserId = nextBrowser.id
        SystemHelper.shared.playFeedbackSound()
        completion?(nextBrowser)
    }
}
