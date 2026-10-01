import AppKit
import SwiftUI

public class HUDController: NSObject {
    public static let shared = HUDController()

    private var window: NSPanel?
    private var dismissTimer: Timer?

    public func show(browser: BrowserApp) {
        dismissTimer?.invalidate()

        if let existing = window {
            existing.close()
            window = nil
        }

        let hudView = HUDView(browser: browser)
        let hosting = NSHostingController(rootView: hudView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 230, height: 54),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.contentViewController = hosting
        panel.hasShadow = true

        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 115
            let y = screenRect.maxY - 85
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.alphaValue = 0.0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            panel.animator().alphaValue = 1.0
        }

        self.window = panel

        dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self, weak panel] _ in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.25
                panel?.animator().alphaValue = 0.0
            }, completionHandler: {
                panel?.close()
                if self?.window === panel {
                    self?.window = nil
                }
            })
        }
    }
}

public struct HUDView: View {
    public let browser: BrowserApp

    public var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: browser.icon)
                .resizable()
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(browser.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)

                Text("Active Browser")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(width: 230, height: 54)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}
