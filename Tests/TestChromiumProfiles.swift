// Run: cat Sources/Models/ChromiumProfiles.swift Tests/TestChromiumProfiles.swift | swift -
import Foundation

let json = """
{"profile": {"info_cache": {
  "Profile 10": {"name": "Ten"},
  "Profile 2": {"name": "Work"},
  "Default": {"name": "Personal"},
  "Profile 1": {"name": ""}
}}}
""".data(using: .utf8)!

let p = ChromiumProfiles.parse(localState: json)
assert(p.map(\.directory) == ["Default", "Profile 1", "Profile 2", "Profile 10"], "\(p)")  // numeric order
assert(p.map(\.name) == ["Personal", "Profile 1", "Work", "Ten"])                          // empty name → dir
assert(ChromiumProfiles.parse(localState: Data("{}".utf8)).isEmpty)
assert(ChromiumProfiles.parse(localState: Data("not json".utf8)).isEmpty)
assert(ChromiumProfiles.profiles(forBundleId: "com.apple.Safari").isEmpty)                 // not Chromium

print("✅ TestChromiumProfiles passed!")
