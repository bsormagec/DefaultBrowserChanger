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
        let targetId = activeBrowserId
        let browsers = BrowserManager.shared.fetchInstalledBrowsers()

        guard let targetBrowser = browsers.first(where: { $0.id == targetId }) ?? browsers.first else {
            NSLog("LinkRouter: No target browser found, opening with default workspace")
            NSWorkspace.shared.open(url)
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        NSWorkspace.shared.open([url], withApplicationAt: targetBrowser.bundleURL, configuration: config) { _, error in
            if let error = error {
                NSLog("LinkRouter: Failed to open URL in %@: %@", targetBrowser.name, error.localizedDescription)
                NSWorkspace.shared.open(url)
            } else {
                NSLog("LinkRouter: Successfully opened URL in %@", targetBrowser.name)
            }
        }
    }

    public func cycleNextBrowser(completion: ((BrowserApp?) -> Void)? = nil) {
        let browsers = BrowserManager.shared.fetchInstalledBrowsers()
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
