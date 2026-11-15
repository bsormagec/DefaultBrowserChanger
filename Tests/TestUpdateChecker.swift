// Run: cat Sources/Services/UpdateChecker.swift Tests/TestUpdateChecker.swift | swift -
import Foundation

assert(UpdateChecker.isNewer("v1.7.0", than: "1.6.0"))
assert(UpdateChecker.isNewer("v1.10.0", than: "1.9.2"))   // numeric, not string, comparison
assert(UpdateChecker.isNewer("v2.0", than: "1.99.99"))
assert(UpdateChecker.isNewer("v1.6.1", than: "1.6"))
assert(!UpdateChecker.isNewer("v1.6.0", than: "1.6.0"))
assert(!UpdateChecker.isNewer("v1.6", than: "1.6.0"))     // missing parts count as 0
assert(!UpdateChecker.isNewer("v1.5.9", than: "1.6.0"))

print("✅ TestUpdateChecker passed!")
