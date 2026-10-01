import Foundation

// Verification of cycling math and logic
let bundleIds = ["com.apple.Safari", "com.google.Chrome", "com.brave.Browser"]

func getNextBrowser(currentId: String?, installed: [String]) -> String? {
    guard !installed.isEmpty else { return nil }
    if let currentId = currentId, let index = installed.firstIndex(of: currentId) {
        let nextIndex = (index + 1) % installed.count
        return installed[nextIndex]
    }
    return installed.first
}

assert(getNextBrowser(currentId: "com.apple.Safari", installed: bundleIds) == "com.google.Chrome")
assert(getNextBrowser(currentId: "com.google.Chrome", installed: bundleIds) == "com.brave.Browser")
assert(getNextBrowser(currentId: "com.brave.Browser", installed: bundleIds) == "com.apple.Safari")
assert(getNextBrowser(currentId: "unknown.browser", installed: bundleIds) == "com.apple.Safari")
assert(getNextBrowser(currentId: nil, installed: bundleIds) == "com.apple.Safari")

// Verification with enabled subset (filtering)
let enabledSubset = ["com.apple.Safari", "com.brave.Browser"]
assert(getNextBrowser(currentId: "com.apple.Safari", installed: enabledSubset) == "com.brave.Browser")
assert(getNextBrowser(currentId: "com.brave.Browser", installed: enabledSubset) == "com.apple.Safari")
// If currently active was Chrome (not in enabled subset), fallback to first enabled
assert(getNextBrowser(currentId: "com.google.Chrome", installed: enabledSubset) == "com.apple.Safari")

print("✅ TestBrowserCycle passed!")
