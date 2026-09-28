import AppKit
import ApplicationServices
import ServiceManagement
import UserNotifications

public class SystemHelper: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = SystemHelper()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Launch at Login

    public var isLaunchAtLoginEnabled: Bool {
        return SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    public func setLaunchAtLogin(enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            print("Failed to set launch at login to \(enabled): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - System Settings Navigation

    public var isDefaultBrowser: Bool {
        return BrowserManager.shared.getCurrentDefaultBrowserBundleId() == "com.bsormagec.DefaultBrowserChanger"
    }

    public func openDesktopAndDockSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") {
            if NSWorkspace.shared.open(url) {
                return
            }
        }
        if let fallbackUrl = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(fallbackUrl)
        }
    }

    // MARK: - Accessibility Permissions

    public var isAccessibilityGranted: Bool {
        return AXIsProcessTrusted()
    }

    public func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            openAccessibilitySettings()
        }
    }

    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            if NSWorkspace.shared.open(url) {
                return
            }
        }
        if let fallbackUrl = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(fallbackUrl)
        }
    }

    // MARK: - Audio & Feedback

    public func playFeedbackSound() {
        if let sound = NSSound(named: "Tink") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    // MARK: - User Notifications

    public func requestNotificationPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            completion?(granted)
        }
    }

    public func postNotification(title: String, message: String, playSound: Bool = true) {
        if playSound {
            playFeedbackSound()
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to post notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
