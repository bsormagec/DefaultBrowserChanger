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

    public func route(url: URL) {
        let now = Date()
        if let lastUrl = lastRoutedURL, lastUrl == url.absoluteString,
           let lastTime = lastRoutedTime, now.timeIntervalSince(lastTime) < 0.5 {
            NSLog("LinkRouter: Duplicate URL event ignored for %@", url.absoluteString)
            return
        }
        lastRoutedURL = url.absoluteString
        lastRoutedTime = now

        NSLog("LinkRouter: Routing URL: %@", url.absoluteString)
        let browsers = BrowserManager.shared.fetchInstalledBrowsers()
        // Domain rule wins if its browser is still installed; otherwise fall back to the active browser.
        let ruleTarget = DomainRule.browserId(for: url, in: DomainRule.load())
            .flatMap { id in browsers.first(where: { $0.id == id }) }
        let activeId = activeBrowserId

        guard let targetBrowser = ruleTarget ?? browsers.first(where: { $0.id == activeId }) ?? browsers.first else {
            NSLog("LinkRouter: No target browser found, opening with default workspace")
            NSWorkspace.shared.open(url)
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

    private func open(_ url: URL, in browser: BrowserApp) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        NSWorkspace.shared.open([url], withApplicationAt: browser.bundleURL, configuration: config) { _, error in
            if let error = error {
                NSLog("LinkRouter: Failed to open URL in %@: %@", browser.name, error.localizedDescription)
                NSWorkspace.shared.open(url)
            } else {
                NSLog("LinkRouter: Successfully opened URL in %@", browser.name)
            }
        }
    }

    private var pickedBrowserId: String?

    private func showPicker(for url: URL, browsers: [BrowserApp], suggested: BrowserApp) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let header = NSMenuItem(title: "Open \(url.host ?? url.absoluteString) in…", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        var suggestedItem: NSMenuItem?
        for browser in browsers {
            let item = NSMenuItem(title: browser.name, action: #selector(pickerItemSelected(_:)), keyEquivalent: "")
            item.target = self
            item.image = browser.icon
            // macOS 27+ hides menu item images unless asked (same approach as MenuBarController).
            if item.responds(to: Selector(("setPreferredImageVisibility:"))) {
                item.setValue(1, forKey: "preferredImageVisibility")
            }
            item.representedObject = browser.id
            if browser.id == suggested.id {
                item.state = .on
                suggestedItem = item
            }
            menu.addItem(item)
        }

        pickedBrowserId = nil
        NSApp.activate(ignoringOtherApps: true)
        // popUp blocks until the menu closes; the selected item's action fires before it returns.
        menu.popUp(positioning: suggestedItem, at: NSEvent.mouseLocation, in: nil)

        if let browser = browsers.first(where: { $0.id == pickedBrowserId }) {
            open(url, in: browser)
        } else {
            NSLog("LinkRouter: Picker dismissed, link not opened")
            NSApp.hide(nil) // hand focus back to the app the link came from
        }
    }

    @objc private func pickerItemSelected(_ sender: NSMenuItem) {
        pickedBrowserId = sender.representedObject as? String
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
