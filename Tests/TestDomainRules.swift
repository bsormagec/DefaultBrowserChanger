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

print("✅ TestDomainRules passed!")
