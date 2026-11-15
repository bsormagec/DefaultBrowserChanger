import AppKit

public class MenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    public override init() {
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Default Browser Changer") {
                let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
                let configuredImage = image.withSymbolConfiguration(config) ?? image
                configuredImage.isTemplate = true
                button.image = configuredImage
            }
        }
        updateTooltip()
        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    private func updateTooltip() {
        let activeBundleId = LinkRouter.shared.activeBrowserId
        let browsers = BrowserManager.shared.fetchInstalledBrowsers()
        let currentName = browsers.first(where: { $0.id == activeBundleId })?.name ?? "Web Browser"
        statusItem.button?.toolTip = "Active Browser: \(currentName)"
    }

    // MARK: - NSMenuDelegate

    public func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        BrowserManager.shared.invalidateBrowserCache()  // pick up newly installed browsers/profiles
        updateTooltip()

        if let update = UpdateChecker.shared.available {
            let updateItem = NSMenuItem(title: "Update Available: \(update.version)…", action: #selector(openUpdatePage(_:)), keyEquivalent: "")
            updateItem.target = self
            updateItem.representedObject = update.page
            updateItem.image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: nil)
            if updateItem.responds(to: Selector(("setPreferredImageVisibility:"))) {
                updateItem.setValue(1, forKey: "preferredImageVisibility")
            }
            menu.addItem(updateItem)
            menu.addItem(NSMenuItem.separator())
        }

        let browsers = BrowserManager.shared.fetchInstalledBrowsers()
        let activeBundleId = LinkRouter.shared.activeBrowserId

        let currentBrowser = browsers.first(where: { $0.id == activeBundleId })
        let currentName = currentBrowser?.name ?? "Detected"

        // Header item showing active browser
        let headerItem = NSMenuItem(title: "Active: \(currentName)", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        headerItem.attributedTitle = NSAttributedString(string: "Active: \(currentName)", attributes: headerAttributes)
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Browser list
        if browsers.isEmpty {
            let emptyItem = NSMenuItem(title: "No Browsers Found", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for browser in browsers {
                let item = NSMenuItem(title: browser.name, action: #selector(browserSelected(_:)), keyEquivalent: "")
                item.target = self
                item.image = browser.icon
                item.representedObject = browser.id
                item.state = (browser.id == activeBundleId) ? .on : .off
                if item.responds(to: Selector(("setPreferredImageVisibility:"))) {
                    item.setValue(1, forKey: "preferredImageVisibility")
                }
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Recent links: re-open one in another browser
        let recent = LinkRouter.shared.recentLinks
        if !recent.isEmpty {
            let recentMenu = NSMenu()
            for url in recent {
                let linkItem = NSMenuItem(title: Self.shortTitle(for: url), action: nil, keyEquivalent: "")
                linkItem.toolTip = url.absoluteString
                let linkMenu = NSMenu()
                for browser in browsers {
                    let item = NSMenuItem(title: "Open in \(browser.name)", action: #selector(reopenRecent(_:)), keyEquivalent: "")
                    item.target = self
                    item.image = browser.icon
                    if item.responds(to: Selector(("setPreferredImageVisibility:"))) {
                        item.setValue(1, forKey: "preferredImageVisibility")
                    }
                    item.representedObject = [url, browser.id] as [Any]
                    linkMenu.addItem(item)
                }
                linkMenu.addItem(NSMenuItem.separator())
                let copyItem = NSMenuItem(title: "Copy Link", action: #selector(copyRecent(_:)), keyEquivalent: "")
                copyItem.target = self
                copyItem.representedObject = url
                linkMenu.addItem(copyItem)
                linkItem.submenu = linkMenu
                recentMenu.addItem(linkItem)
            }
            recentMenu.addItem(NSMenuItem.separator())
            let clearItem = NSMenuItem(title: "Clear Recent Links", action: #selector(clearRecent(_:)), keyEquivalent: "")
            clearItem.target = self
            recentMenu.addItem(clearItem)

            let recentItem = NSMenuItem(title: "Recent Links", action: nil, keyEquivalent: "")
            recentItem.submenu = recentMenu
            menu.addItem(recentItem)
            menu.addItem(NSMenuItem.separator())
        }

        // Quick Actions & Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings(_:)), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = SystemHelper.shared.isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(launchItem)

        let shortcutTitle = "Cycle Shortcut (\(HotkeyManager.shared.shortcutDisplayString))"
        let hotkeyItem = NSMenuItem(title: shortcutTitle, action: #selector(toggleHotkeyEnabled(_:)), keyEquivalent: "")
        hotkeyItem.target = self
        hotkeyItem.state = HotkeyManager.shared.isHotkeyEnabled ? .on : .off
        menu.addItem(hotkeyItem)

        let systemSettingsItem = NSMenuItem(title: "Open in System Settings...", action: #selector(openSystemSettings(_:)), keyEquivalent: "")
        systemSettingsItem.target = self
        menu.addItem(systemSettingsItem)

        let welcomeItem = NSMenuItem(title: "Welcome Guide...", action: #selector(openWelcomeGuide(_:)), keyEquivalent: "")
        welcomeItem.target = self
        menu.addItem(welcomeItem)

        let refreshItem = NSMenuItem(title: "Refresh Browsers", action: #selector(refreshBrowsers(_:)), keyEquivalent: "")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // Quit item
        let quitItem = NSMenuItem(title: "Quit DefaultBrowserChanger", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc func openSettings(_ sender: NSMenuItem) {
        SettingsController.shared.showWindow()
    }

    @objc func browserSelected(_ sender: NSMenuItem) {
        guard let bundleId = sender.representedObject as? String else {
            NSLog("MenuBarController: Invalid representedObject on browser item")
            return
        }

        let browserName = sender.title
        NSLog("MenuBarController: Selected browser %@ (%@)", browserName, bundleId)

        LinkRouter.shared.selectBrowser(bundleId: bundleId)
        updateTooltip()
        SystemHelper.shared.postNotification(
            title: "Active Browser Changed",
            message: "\(browserName) is now your active browser."
        )
    }

    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newState = !SystemHelper.shared.isLaunchAtLoginEnabled
        SystemHelper.shared.setLaunchAtLogin(enabled: newState)
        sender.state = SystemHelper.shared.isLaunchAtLoginEnabled ? .on : .off
    }

    @objc func toggleHotkeyEnabled(_ sender: NSMenuItem) {
        let newState = !HotkeyManager.shared.isHotkeyEnabled
        HotkeyManager.shared.isHotkeyEnabled = newState
        sender.state = newState ? .on : .off
    }

    @objc func openSystemSettings(_ sender: NSMenuItem) {
        SystemHelper.shared.openDesktopAndDockSettings()
    }

    @objc func openWelcomeGuide(_ sender: NSMenuItem) {
        OnboardingController.shared.showWindow(force: true)
    }

    /// "github.com/org/repo/pulls…" — host and path, without scheme or query, at most 50 characters.
    static func shortTitle(for url: URL) -> String {
        let text = (url.host ?? url.absoluteString) + (url.path == "/" ? "" : url.path)
        return text.count > 50 ? String(text.prefix(49)) + "…" : text
    }

    @objc func reopenRecent(_ sender: NSMenuItem) {
        guard let pair = sender.representedObject as? [Any],
              let url = pair.first as? URL, let browserId = pair.last as? String else { return }
        LinkRouter.shared.reopen(url, inBrowserId: browserId)
    }

    @objc func copyRecent(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
    }

    @objc func clearRecent(_ sender: NSMenuItem) {
        LinkRouter.shared.clearRecentLinks()
    }

    @objc func openUpdatePage(_ sender: NSMenuItem) {
        guard let page = sender.representedObject as? URL else { return }
        // Open in the active browser directly; NSWorkspace.open(url) would route back through this app anyway.
        LinkRouter.shared.route(url: page)
    }

    @objc func refreshBrowsers(_ sender: NSMenuItem) {
        SystemHelper.shared.playFeedbackSound()
        BrowserManager.shared.invalidateBrowserCache()
        _ = BrowserManager.shared.fetchInstalledBrowsers()
    }
}
