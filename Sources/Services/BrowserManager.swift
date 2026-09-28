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

            // Extract icon and render crisp 18x18 bitmap (36x36 @2x Retina)
            let icon = self.createMenuIcon(for: url.path, size: 18)

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
        NSLog("BrowserManager: Setting default browser to %@", bundleId)
        let res1 = LSSetDefaultHandlerForURLScheme("http" as CFString, bundleId as CFString)
        let res2 = LSSetDefaultHandlerForURLScheme("https" as CFString, bundleId as CFString)
        let res3 = LSSetDefaultRoleHandlerForContentType("public.html" as CFString, .all, bundleId as CFString)
        let res4 = LSSetDefaultRoleHandlerForContentType("public.xhtml" as CFString, .all, bundleId as CFString)
        NSLog("BrowserManager: LS calls returned: %d, %d, %d, %d", res1, res2, res3, res4)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let scriptSource = """
            tell application "System Events"
                repeat 30 times
                    if exists (process "CoreServicesUIAgent") then
                        tell process "CoreServicesUIAgent"
                            if (count of windows) > 0 then
                                repeat with w in windows
                                    repeat with b in (buttons of w)
                                        set bName to (name of b) as text
                                        if bName starts with "Use" or bName contains "Kullan" or (bName does not start with "Keep" and bName does not start with "Vazgeç" and bName does not start with "Cancel" and bName does not start with "Sürdür") then
                                            try
                                                click b
                                                exit repeat
                                            end try
                                        end if
                                    end repeat
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
                if let error = error {
                    NSLog("BrowserManager: AppleScript error: %@", error)
                }
            }

            Thread.sleep(forTimeInterval: 0.3)

            let isSuccess = (self?.getCurrentDefaultBrowserBundleId() == bundleId)
            NSLog("BrowserManager: Verification success = %d", isSuccess ? 1 : 0)
            DispatchQueue.main.async {
                completion(isSuccess)
            }
        }
    }

    private func createMenuIcon(for filePath: String, size: CGFloat = 18) -> NSImage {
        let source = NSWorkspace.shared.icon(forFile: filePath)
        let targetSize = NSSize(width: size, height: size)
        let scale: CGFloat = 2.0
        let pixelWidth = Int(size * scale)
        let pixelHeight = Int(size * scale)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            let fallback = NSImage(size: targetSize)
            fallback.lockFocus()
            source.draw(in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .sourceOver, fraction: 1.0)
            fallback.unlockFocus()
            return fallback
        }

        rep.size = targetSize

        NSGraphicsContext.saveGraphicsState()
        if let context = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.current = context
            context.imageInterpolation = .high
            source.draw(in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        NSGraphicsContext.restoreGraphicsState()

        let result = NSImage(size: targetSize)
        result.addRepresentation(rep)
        return result
    }
}
