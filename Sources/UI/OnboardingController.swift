import AppKit
import SwiftUI

public class OnboardingController: NSObject, NSWindowDelegate {
    public static let shared = OnboardingController()

    private var window: NSWindow?
    private let onboardingCompletedKey = "hasCompletedOnboarding"

    public var hasCompletedOnboarding: Bool {
        get {
            return UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: onboardingCompletedKey)
        }
    }

    public override init() {
        super.init()
    }

    public func showWindow(force: Bool = false) {
        if !force && hasCompletedOnboarding {
            return
        }

        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = OnboardingView { [weak self] in
            self?.completeOnboarding()
        }

        let hostingController = NSHostingController(rootView: contentView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 460),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
        newWindow.isMovableByWindowBackground = true
        newWindow.contentViewController = hostingController
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.level = .floating
        newWindow.center()

        self.window = newWindow

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func completeOnboarding() {
        hasCompletedOnboarding = true
        window?.close()
        window = nil
        SystemHelper.shared.playFeedbackSound()
    }

    public func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
