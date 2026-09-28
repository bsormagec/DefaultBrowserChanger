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
        HotkeyManager.shared.setup()

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(event:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        if !OnboardingController.shared.hasCompletedOnboarding {
            DispatchQueue.main.async {
                OnboardingController.shared.showWindow(force: false)
            }
        }

        NSLog("DefaultBrowserChanger: started successfully with menu bar item")
    }

    // MARK: - URL Interception (Link Router)

    public func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            LinkRouter.shared.route(url: url)
        }
    }

    @objc func handleGetURL(event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }
        LinkRouter.shared.route(url: url)
    }
}
