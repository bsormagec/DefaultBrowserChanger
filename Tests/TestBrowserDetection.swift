import AppKit
import ApplicationServices

// MARK: - BrowserApp Model
public struct BrowserApp: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let bundleURL: URL
    public let icon: NSImage
    public var isDefault: Bool

    public init(id: String, name: String, bundleURL: URL, icon: NSImage, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.bundleURL = bundleURL
        self.icon = icon
        self.isDefault = isDefault
    }

    public static func == (lhs: BrowserApp, rhs: BrowserApp) -> Bool {
        return lhs.id == rhs.id && lhs.isDefault == rhs.isDefault
    }
}

// MARK: - BrowserManager Service
public class BrowserManager {
    public static let shared = BrowserManager()

    public init() {}

    public func getCurrentDefaultBrowserBundleId() -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!) else {
            return nil
        }
        return Bundle(url: url)?.bundleIdentifier
    }

    public func fetchInstalledBrowsers() -> [BrowserApp] {
        var appURLs = NSWorkspace.shared.urlsForApplications(toOpen: URL(string: "https://example.com")!)
        let httpURLs = NSWorkspace.shared.urlsForApplications(toOpen: URL(string: "http://example.com")!)
        for url in httpURLs {
            if !appURLs.contains(url) {
                appURLs.append(url)
            }
        }

        let htmlHandlersArray = LSCopyAllRoleHandlersForContentType("public.html" as CFString, .all)?.takeRetainedValue() as? [String] ?? []
        let htmlHandlers = Set(htmlHandlersArray)

        let knownBrowsers: Set<String> = [
            "com.apple.Safari",
            "com.google.Chrome",
            "com.google.Chrome.canary",
            "company.thebrowser.Browser",
            "com.brave.Browser",
            "org.mozilla.firefox",
            "com.microsoft.edgemac",
            "com.operasoftware.Opera",
            "com.vivaldi.Vivaldi",
            "com.duckduckgo.mobile.ios",
            "ai.perplexity.comet",
            "org.torproject.torbrowser",
            "org.chromium.Chromium",
            "com.browseros.BrowserClaw",
            "org.mozilla.camoufox"
        ]

        let currentDefault = getCurrentDefaultBrowserBundleId()
        var seenBundleIds = Set<String>()
        var browsers: [BrowserApp] = []

        for url in appURLs {
            guard let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier else {
                continue
            }

            let lowerId = bundleId.lowercased()
            let path = url.path

            if lowerId.hasPrefix("com.parallels") ||
               lowerId.contains("winapp") ||
               path.contains("Applications (Parallels)") ||
               lowerId == "com.openai.codex" ||
               lowerId == "com.bsormagec.defaultbrowserchanger" ||
               bundleId == Bundle.main.bundleIdentifier ||
               path.contains("helper") {
                continue
            }

            guard htmlHandlers.contains(bundleId) || knownBrowsers.contains(bundleId) else {
                continue
            }

            if seenBundleIds.contains(bundleId) {
                continue
            }
            seenBundleIds.insert(bundleId)

            let displayName = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")

            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 18, height: 18)

            let isDefault = (bundleId == currentDefault)
            let browser = BrowserApp(
                id: bundleId,
                name: displayName,
                bundleURL: url,
                icon: icon,
                isDefault: isDefault
            )
            browsers.append(browser)
        }

        let popularBrowsers = [
            "com.apple.Safari",
            "com.google.Chrome",
            "company.thebrowser.Browser",
            "com.brave.Browser",
            "org.mozilla.firefox",
            "com.microsoft.edgemac",
            "com.operasoftware.Opera",
            "com.vivaldi.Vivaldi",
            "com.duckduckgo.mobile.ios",
            "ai.perplexity.comet",
            "com.browseros.BrowserClaw",
            "com.google.Chrome.canary"
        ]

        browsers.sort { a, b in
            let idxA = popularBrowsers.firstIndex(of: a.id) ?? Int.max
            let idxB = popularBrowsers.firstIndex(of: b.id) ?? Int.max
            if idxA != idxB {
                return idxA < idxB
            }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }

        return browsers
    }

    public func setDefaultBrowser(bundleId: String, completion: @escaping (Bool) -> Void) {
        LSSetDefaultHandlerForURLScheme("http" as CFString, bundleId as CFString)
        LSSetDefaultHandlerForURLScheme("https" as CFString, bundleId as CFString)
        LSSetDefaultRoleHandlerForContentType("public.html" as CFString, .all, bundleId as CFString)
        LSSetDefaultRoleHandlerForContentType("public.xhtml" as CFString, .all, bundleId as CFString)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let scriptSource = """
            tell application "System Events"
                repeat 25 times
                    if exists (process "CoreServicesUIAgent") then
                        tell process "CoreServicesUIAgent"
                            if (count of windows) > 0 then
                                repeat with w in windows
                                    try
                                        click (first button of w whose name starts with "Use")
                                    end try
                                end repeat
                                exit repeat
                            end if
                        end tell
                    end if
                    delay 0.04
                end repeat
            end tell
            """

            if let script = NSAppleScript(source: scriptSource) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
            }

            Thread.sleep(forTimeInterval: 0.25)

            let isSuccess = (self?.getCurrentDefaultBrowserBundleId() == bundleId)
            DispatchQueue.main.async {
                completion(isSuccess)
            }
        }
    }
}

// MARK: - Verification Script
print("========================================")
print(" Running Browser Detection & Service Tests")
print("========================================")

let manager = BrowserManager.shared

// 1. Current default browser check
guard let currentDefault = manager.getCurrentDefaultBrowserBundleId() else {
    print("❌ Failed: Could not detect current default browser bundle identifier.")
    exit(1)
}

guard let workspaceDefaultUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!),
      let workspaceDefaultId = Bundle(url: workspaceDefaultUrl)?.bundleIdentifier else {
    print("❌ Failed: NSWorkspace could not identify default browser URL.")
    exit(1)
}

assert(currentDefault == workspaceDefaultId, "Detected default browser must match NSWorkspace default")
print("✅ Current Default Browser detected: \(currentDefault)")

// 2. Installed browsers discovery check
let browsers = manager.fetchInstalledBrowsers()
assert(!browsers.isEmpty, "Installed browsers list should not be empty")
print("✅ Found \(browsers.count) installed browser(s):")

var foundDefault = false
for browser in browsers {
    assert(!browser.id.isEmpty, "Browser bundle ID must not be empty")
    assert(!browser.name.isEmpty, "Browser display name must not be empty")
    assert(browser.icon.size.width == 18 && browser.icon.size.height == 18, "Icon size must be 18x18")
    assert(FileManager.default.fileExists(atPath: browser.bundleURL.path), "Bundle path must exist")

    let tag = browser.isDefault ? "[DEFAULT]" : "         "
    if browser.isDefault {
        foundDefault = true
    }
    print("  \(tag) \(browser.name) (\(browser.id)) [Icon: \(Int(browser.icon.size.width))x\(Int(browser.icon.size.height))]")
}

if currentDefault == "com.bsormagec.DefaultBrowserChanger" {
    print("✅ Default browser is DefaultBrowserChanger (Link Interceptor proxy active).")
} else {
    assert(foundDefault, "One of the returned browsers must have isDefault = true")
    print("✅ Default browser is correctly flagged in installed list.")
}

// 3. Equatable verification
let first = browsers[0]
let sameFirst = BrowserApp(id: first.id, name: first.name, bundleURL: first.bundleURL, icon: first.icon, isDefault: first.isDefault)
assert(first == sameFirst, "BrowserApp equality comparison failed")

print("========================================")
print("🎉 All Browser Detection Tests Passed!")
print("========================================")
