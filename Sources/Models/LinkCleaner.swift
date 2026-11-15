import Foundation

/// Unwraps redirect links (Outlook SafeLinks, Google, Facebook, Slack…) and strips tracking parameters.
public enum LinkCleaner {
    private static let enabledKey = "cleanLinks"

    /// On by default.
    public static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static let trackingParams: Set<String> = [
        "fbclid", "gclid", "gclsrc", "dclid", "gbraid", "wbraid", "msclkid", "yclid", "twclid", "ttclid",
        "igshid", "igsh", "mc_cid", "mc_eid", "_hsenc", "_hsmi", "mkt_tok", "li_fat_id", "srsltid",
        "oly_anon_id", "oly_enc_id", "vero_id", "_ga", "_gl",
    ]

    /// Redirect wrappers: (host matcher, required path or nil, query parameter holding the real URL).
    static let wrappers: [(host: (String) -> Bool, path: String?, param: String)] = [
        ({ $0.hasSuffix(".safelinks.protection.outlook.com") }, nil, "url"),
        ({ $0.hasPrefix("www.google.") || $0.hasPrefix("google.") }, "/url", "q"),
        ({ $0 == "l.facebook.com" || $0 == "lm.facebook.com" || $0 == "l.messenger.com" }, "/l.php", "u"),
        ({ $0 == "l.instagram.com" }, nil, "u"),
        ({ $0 == "slack-redir.net" }, "/link", "url"),
        ({ $0 == "www.youtube.com" || $0 == "youtube.com" }, "/redirect", "q"),
    ]

    public static func clean(_ url: URL) -> URL {
        var current = url
        for _ in 0..<3 {  // wrappers can be nested (e.g. SafeLinks around a Google redirect)
            guard let inner = unwrap(current) else { break }
            current = inner
        }
        return stripTracking(current)
    }

    /// The wrapped destination, only if it is a plain http(s) URL.
    static func unwrap(_ url: URL) -> URL? {
        guard let host = url.host?.lowercased(),
              let wrapper = wrappers.first(where: { $0.host(host) && ($0.path == nil || $0.path == url.path) }),
              let value = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                  .queryItems?.first(where: { $0.name == wrapper.param })?.value,
              let inner = URL(string: value),
              let scheme = inner.scheme?.lowercased(), scheme == "http" || scheme == "https",
              inner.host != nil else { return nil }
        return inner
    }

    static func stripTracking(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.percentEncodedQueryItems else { return url }
        let kept = items.filter { item in
            let name = item.name.lowercased()
            return !name.hasPrefix("utm_") && !trackingParams.contains(name)
        }
        guard kept.count != items.count else { return url }  // untouched links keep their exact original form
        components.percentEncodedQueryItems = kept.isEmpty ? nil : kept
        return components.url ?? url
    }
}
