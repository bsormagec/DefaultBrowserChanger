import Foundation

// Test UserDefaults key behavior
let key = "hasCompletedOnboarding"
let testDefaults = UserDefaults.standard

testDefaults.removeObject(forKey: key)
assert(testDefaults.bool(forKey: key) == false, "Initial onboarding state must be false")

testDefaults.set(true, forKey: key)
assert(testDefaults.bool(forKey: key) == true, "Onboarding state must persist true")

testDefaults.set(false, forKey: key)
assert(testDefaults.bool(forKey: key) == false, "Onboarding state must reset to false")

print("✅ TestOnboardingState passed!")
