import Foundation

/// Sends links matching `pattern` to a specific browser, overriding the active one.
/// Pattern forms: `github.com` (domain + all subdomains), `*.atlassian.net`, `github.com/work-org` (path prefix).
public struct DomainRule: Codable, Equatable, Identifiable {
    public var id = UUID()
    public var pattern: String
    public var browserId: String

    public init(pattern: String, browserId: String) {
        self.pattern = pattern
        self.browserId = browserId
    }

    public func matches(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        var p = pattern.trimmingCharacters(in: .whitespaces).lowercased()
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
    public static func browserId(for url: URL, in rules: [DomainRule]) -> String? {
        rules.first { $0.matches(url) }?.browserId
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
