import AppKit
import ApplicationServices

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

            // Filter out Parallels windows bridges, winapp helpers, OpenAI codex helper, etc.
            if lowerId.hasPrefix("com.parallels") ||
               lowerId.contains("winapp") ||
               path.contains("Applications (Parallels)") ||
               lowerId == "com.openai.codex" ||
               path.contains("helper") {
                continue
            }

            // Keep handlers that handle http and html (or are known browsers)
            guard htmlHandlers.contains(bundleId) || knownBrowsers.contains(bundleId) else {
                continue
            }

            // Deduplicate by bundle identifier
            if seenBundleIds.contains(bundleId) {
                continue
            }
            seenBundleIds.insert(bundleId)

            // Extract display name
            let displayName = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")

            // Extract icon and resize to 18x18
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

        // Sort: popular browsers first, then alphabetical by name
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
