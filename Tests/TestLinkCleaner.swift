// Run: cat Sources/Models/LinkCleaner.swift Tests/TestLinkCleaner.swift | swift -
import Foundation

func c(_ s: String) -> String { LinkCleaner.clean(URL(string: s)!).absoluteString }

// Tracking parameters
assert(c("https://a.com/p?utm_source=x&utm_medium=y&id=5") == "https://a.com/p?id=5")
assert(c("https://a.com/p?fbclid=abc") == "https://a.com/p")
assert(c("https://a.com/p?UTM_Campaign=x&q=a%20b#frag") == "https://a.com/p?q=a%20b#frag")  // case, encoding, fragment kept
assert(c("https://a.com/p?q=1&q=2") == "https://a.com/p?q=1&q=2")                           // untouched
assert(c("https://a.com/p?sid=1") == "https://a.com/p?sid=1")                               // similar name kept

// Redirect wrappers
let target = "https://github.com/org/repo?utm_source=mail"
let enc = target.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
assert(c("https://eur01.safelinks.protection.outlook.com/?url=\(enc)&data=xyz") == "https://github.com/org/repo")
assert(c("https://www.google.com/url?q=\(enc)&sa=D") == "https://github.com/org/repo")
assert(c("https://l.facebook.com/l.php?u=\(enc)&h=AT0") == "https://github.com/org/repo")
assert(c("https://slack-redir.net/link?url=\(enc)") == "https://github.com/org/repo")

// Nested: SafeLinks around a Google redirect
let google = "https://www.google.com/url?q=\(enc)".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
assert(c("https://x.safelinks.protection.outlook.com/?url=\(google)") == "https://github.com/org/repo")

// Never unwrap to non-web schemes; non-redirect paths stay
let js = "javascript:alert(1)".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
assert(c("https://www.google.com/url?q=\(js)") == "https://www.google.com/url?q=\(js)")
assert(c("https://www.google.com/search?q=\(enc)") == "https://www.google.com/search?q=\(enc)")

print("✅ TestLinkCleaner passed!")
