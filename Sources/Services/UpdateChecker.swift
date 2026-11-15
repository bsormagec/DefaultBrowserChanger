import Foundation

/// Checks GitHub once a day for a newer release. This is the app's only network request; it can be turned off in Settings.
public final class UpdateChecker {
    public static let shared = UpdateChecker()

    static let latestReleaseURL = URL(string: "https://api.github.com/repos/bsormagec/DefaultBrowserChanger/releases/latest")!
    private static let enabledKey = "checkForUpdates"

    /// On by default.
    public static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// Set when GitHub has a newer release than the running app.
    public private(set) var available: (version: String, page: URL)?
    private var timer: Timer?

    public func start() {
        check()
        timer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in self?.check() }
    }

    public func check() {
        guard Self.isEnabled else {
            available = nil
            return
        }
        var request = URLRequest(url: Self.latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String,
                  let page = (json["html_url"] as? String).flatMap(URL.init(string:)) else {
                NSLog("UpdateChecker: check failed: %@", error?.localizedDescription ?? "unexpected response")
                return
            }
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            DispatchQueue.main.async {
                self?.available = Self.isNewer(tag, than: current) ? (tag, page) : nil
            }
        }.resume()
    }

    /// Numeric comparison of "v1.10.0"-style versions: 1.10.0 > 1.9.2.
    static func isNewer(_ remote: String, than local: String) -> Bool {
        func parts(_ v: String) -> [Int] {
            v.trimmingCharacters(in: CharacterSet(charactersIn: "vV")).split(separator: ".").map { Int($0) ?? 0 }
        }
        let r = parts(remote), l = parts(local)
        for i in 0..<max(r.count, l.count) {
            let a = i < r.count ? r[i] : 0, b = i < l.count ? l[i] : 0
            if a != b { return a > b }
        }
        return false
    }
}
