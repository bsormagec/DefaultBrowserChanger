import AppKit
import ApplicationServices

// Test Accessibility detection and URL
class AccessibilityTester {
    static func isAccessibilityGranted() -> Bool {
        return AXIsProcessTrusted()
    }

    static func accessibilitySettingsURL() -> URL? {
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }
}

print("Testing Accessibility detection and URL...")
let granted = AccessibilityTester.isAccessibilityGranted()
print("Current accessibility status: \(granted)")
assert(AccessibilityTester.accessibilitySettingsURL() != nil, "Accessibility URL must not be nil")
print("✅ TestSystemHelperAccessibility passed!")
