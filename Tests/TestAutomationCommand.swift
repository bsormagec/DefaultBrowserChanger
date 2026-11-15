// Run: cat Sources/Models/AutomationCommand.swift Tests/TestAutomationCommand.swift | swift -
import Foundation

func p(_ s: String) -> AutomationCommand? { AutomationCommand.parse(URL(string: s)!) }

assert(p("dbc://select?browser=com.google.Chrome") == .select(browser: "com.google.Chrome"))
assert(p("dbc://select?browser=com.google.Chrome.canary%23Profile%201") == .select(browser: "com.google.Chrome.canary#Profile 1"))
assert(p("DefaultBrowserChanger://select?browser=Safari") == .select(browser: "Safari"))   // long scheme, any case
assert(p("dbc://select") == nil)                                                          // missing browser
assert(p("dbc://cycle") == .cycle)

let enc = "https://example.com/a?b=1".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
assert(p("dbc://open?url=\(enc)") == .open(url: URL(string: "https://example.com/a?b=1")!, browser: nil, privateWindow: false))
assert(p("dbc://open?url=\(enc)&browser=org.mozilla.firefox&private=1")
       == .open(url: URL(string: "https://example.com/a?b=1")!, browser: "org.mozilla.firefox", privateWindow: true))
let file = "file:///etc/passwd".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
assert(p("dbc://open?url=\(file)") == nil)                                                // web links only
assert(p("dbc://open") == nil)
assert(p("dbc://unknown") == nil)
assert(p("https://example.com/select?browser=x") == nil)                                  // not our scheme

print("✅ TestAutomationCommand passed!")
