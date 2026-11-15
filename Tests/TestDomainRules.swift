// Run: cat Sources/Models/DomainRule.swift Tests/TestDomainRules.swift | swift -
import Foundation

let rules = [
    DomainRule(pattern: "github.com/work-org", browserId: "work"),
    DomainRule(pattern: "*.atlassian.net", browserId: "work"),
    DomainRule(pattern: "https://GitHub.com", browserId: "personal"),
]
func target(_ s: String) -> String? { DomainRule.browserId(for: URL(string: s)!, in: rules) }

assert(target("https://github.com/work-org/repo/pulls") == "work")       // path prefix
assert(target("https://github.com/work-org") == "work")
assert(target("https://github.com/work-organic") == "personal")          // not a path-segment match
assert(target("https://github.com/someone") == "personal")               // first match wins, falls through
assert(target("https://www.github.com/") == "personal")                  // subdomain
assert(target("https://acme.atlassian.net/browse/X-1") == "work")
assert(target("https://notgithub.com") == nil)                           // no partial host match
assert(target("mailto:a@b.com") == nil)                                  // no host
assert(DomainRule.browserId(for: URL(string: "https://x.com")!, in: [DomainRule(pattern: "", browserId: "b")]) == nil)

// Source-app rules
let slack = "com.tinyspeck.slackmacgap"
let sourceRules = [
    DomainRule(pattern: "github.com", browserId: "slack-github", sourceApp: slack),
    DomainRule(pattern: "", browserId: "slack-any", sourceApp: slack),
    DomainRule(pattern: "github.com", browserId: "github-any"),
]
func src(_ s: String, _ from: String?) -> String? { DomainRule.browserId(for: URL(string: s)!, source: from, in: sourceRules) }
assert(src("https://github.com/x", slack) == "slack-github")      // domain + source
assert(src("https://example.com", slack) == "slack-any")          // empty pattern = any link from that app
assert(src("https://github.com/x", "com.apple.mail") == "github-any")  // other app skips source rules
assert(src("https://github.com/x", nil) == "github-any")          // unknown source skips source rules
assert(src("https://example.com", nil) == nil)

// Rules saved before sourceApp existed still decode
let old = #"[{"id":"6F1B0C2E-1111-4A6B-9C3D-000000000001","pattern":"a.com","browserId":"b"}]"#
let decoded = try! JSONDecoder().decode([DomainRule].self, from: Data(old.utf8))
assert(decoded.first?.sourceApp == nil && decoded.first?.pattern == "a.com")

print("✅ TestDomainRules passed!")
