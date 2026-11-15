import Foundation

/// Sends links matching `pattern` (and, if set, coming from `sourceApp`) to a specific browser, overriding the active one.
/// Pattern forms: `github.com` (domain + all subdomains), `*.atlassian.net`, `github.com/work-org` (path prefix).
/// An empty pattern with a `sourceApp` matches every link from that app.
public struct DomainRule: Codable, Equatable, Identifiable {
    public var id = UUID()
    public var pattern: String
    public var browserId: String
    /// Bundle id of the app the link was clicked in (e.g. "com.tinyspeck.slackmacgap"); nil = any app.
    public var sourceApp: String?

    public init(pattern: String, browserId: String, sourceApp: String? = nil) {
        self.pattern = pattern
        self.browserId = browserId
        self.sourceApp = sourceApp
    }

    public func matches(_ url: URL, source: String? = nil) -> Bool {
        if let sourceApp = sourceApp, sourceApp != source { return false }
        var p = pattern.trimmingCharacters(in: .whitespaces).lowercased()
        if p.isEmpty { return sourceApp != nil }
        guard let host = url.host?.lowercased() else { return false }
        for prefix in ["https://", "http://", "*."] where p.hasPrefix(prefix) {
            p.removeFirst(prefix.count)
        }
        let parts = p.split(separator: "/", maxSplits: 1)
        guard let domain = parts.first.map(String.init), !domain.isEmpty else { return false }
        guard host == domain || host.hasSuffix("." + domain) else { return false }
        guard parts.count > 1 else { return true }
        let path = "/" + parts[1]
        let urlPath = url.path.lowercased()
        return urlPath == path || urlPath.hasPrefix(path.hasSuffix("/") ? path : path + "/")
    }

    /// First matching rule wins.
    public static func browserId(for url: URL, source: String? = nil, in rules: [DomainRule]) -> String? {
        firstMatchIndex(for: url, source: source, in: rules).map { rules[$0].browserId }
    }

    public static func firstMatchIndex(for url: URL, source: String? = nil, in rules: [DomainRule]) -> Int? {
        rules.firstIndex { $0.matches(url, source: source) }
    }

    private static let storageKey = "domainRules"

    public static func load() -> [DomainRule] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([DomainRule].self, from: data)) ?? []
    }

    public static func save(_ rules: [DomainRule]) {
        UserDefaults.standard.set(try? JSONEncoder().encode(rules), forKey: storageKey)
    }
}
