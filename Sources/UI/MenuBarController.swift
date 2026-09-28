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
        let currentBundleId = BrowserManager.shared.getCurrentDefaultBrowserBundleId()
        let browsers = BrowserManager.shared.fetchInstalledBrowsers()
        let currentName = browsers.first(where: { $0.id == currentBundleId })?.name ?? "Web Browser"
        statusItem.button?.toolTip = "Default Browser: \(currentName)"
    }

    // MARK: - NSMenuDelegate

    public func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        updateTooltip()

        let browsers = BrowserManager.shared.fetchInstalledBrowsers()
        let currentDefaultBundleId = BrowserManager.shared.getCurrentDefaultBrowserBundleId()

        let currentBrowser = browsers.first(where: { $0.id == currentDefaultBundleId })
        let currentName = currentBrowser?.name ?? (currentDefaultBundleId != nil ? "Detected" : "None")

        // Header item showing active default browser
        let headerItem = NSMenuItem(title: "Default: \(currentName)", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        headerItem.attributedTitle = NSAttributedString(string: "Default: \(currentName)", attributes: headerAttributes)
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
                item.state = browser.isDefault ? .on : .off
                if #available(macOS 27.0, *) {
                    item.preferredImageVisibility = .visible
                } else if item.responds(to: Selector(("setPreferredImageVisibility:"))) {
                    item.setValue(1, forKey: "preferredImageVisibility")
                }
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Quick Actions & Settings
        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = SystemHelper.shared.isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(launchItem)

        let settingsItem = NSMenuItem(title: "Open in System Settings...", action: #selector(openSystemSettings(_:)), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

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

    @objc func browserSelected(_ sender: NSMenuItem) {
        guard let bundleId = sender.representedObject as? String else {
            NSLog("MenuBarController: Invalid representedObject on browser item")
            return
        }

        let browserName = sender.title
        NSLog("MenuBarController: Selected browser %@ (%@)", browserName, bundleId)

        let currentDefault = BrowserManager.shared.getCurrentDefaultBrowserBundleId()
        if bundleId == currentDefault {
            SystemHelper.shared.playFeedbackSound()
            return
        }

        BrowserManager.shared.setDefaultBrowser(bundleId: bundleId) { [weak self] success in
            NSLog("MenuBarController: Set default browser result = %d", success ? 1 : 0)
            self?.updateTooltip()
            SystemHelper.shared.postNotification(
                title: "Default Browser Changed",
                message: "\(browserName) is now your default web browser."
            )
        }
    }

    @objc func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newState = !SystemHelper.shared.isLaunchAtLoginEnabled
        SystemHelper.shared.setLaunchAtLogin(enabled: newState)
        sender.state = SystemHelper.shared.isLaunchAtLoginEnabled ? .on : .off
    }

    @objc func openSystemSettings(_ sender: NSMenuItem) {
        SystemHelper.shared.openDesktopAndDockSettings()
    }

    @objc func refreshBrowsers(_ sender: NSMenuItem) {
        SystemHelper.shared.playFeedbackSound()
        _ = BrowserManager.shared.fetchInstalledBrowsers()
    }
}
