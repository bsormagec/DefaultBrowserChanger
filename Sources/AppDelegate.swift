import AppKit
import UserNotifications

public class AppDelegate: NSObject, NSApplicationDelegate {
    public var menuBarController: MenuBarController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        SystemHelper.shared.requestNotificationPermission()
        UNUserNotificationCenter.current().delegate = SystemHelper.shared
        print("DefaultBrowserChanger started successfully")
    }
}
