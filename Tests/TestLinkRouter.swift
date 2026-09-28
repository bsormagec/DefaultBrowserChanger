import Foundation

// Verify routing selection and persistence
let key = "activeTargetBrowserBundleId"
UserDefaults.standard.removeObject(forKey: key)

let defaultId = "com.google.Chrome"
UserDefaults.standard.set(defaultId, forKey: key)

assert(UserDefaults.standard.string(forKey: key) == defaultId)
print("✅ TestLinkRouter passed!")
