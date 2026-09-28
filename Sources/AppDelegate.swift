import AppKit
import UserNotifications

public class AppDelegate: NSObject, NSApplicationDelegate {
    public static let shared = AppDelegate()
    public var menuBarController: MenuBarController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("DefaultBrowserChanger: applicationDidFinishLaunching")
        menuBarController = MenuBarController()
        SystemHelper.shared.requestNotificationPermission()
        UNUserNotificationCenter.current().delegate = SystemHelper.shared

        if !OnboardingController.shared.hasCompletedOnboarding {
            DispatchQueue.main.async {
                OnboardingController.shared.showWindow(force: false)
            }
        }

        NSLog("DefaultBrowserChanger: started successfully with menu bar item")
    }
}
