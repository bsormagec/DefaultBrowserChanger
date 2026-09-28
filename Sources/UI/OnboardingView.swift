import SwiftUI

public struct OnboardingView: View {
    @State private var isAccessibilityGranted: Bool = SystemHelper.shared.isAccessibilityGranted
    @State private var isLaunchAtLoginEnabled: Bool = SystemHelper.shared.isLaunchAtLoginEnabled
    public var onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "globe")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .foregroundColor(.accentColor)

                Text("Welcome to DefaultBrowserChanger")
                    .font(.system(size: 20, weight: .bold))

                Text("1-Click Default Browser Switching for macOS")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            // Features List
            VStack(alignment: .leading, spacing: 16) {
                // Item 1: Menu Bar Location
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "menubar.rectangle")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Always in Your Menu Bar")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Click the globe icon in your menu bar at any time to switch your default browser instantly.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Item 2: Accessibility Permission
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: isAccessibilityGranted ? "checkmark.shield.fill" : "hand.tap.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isAccessibilityGranted ? .green : .orange)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("1-Click Auto-Confirmation")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            if isAccessibilityGranted {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Active")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(12)
                            } else {
                                Button("Grant Permission") {
                                    SystemHelper.shared.requestAccessibilityPermission()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }

                        Text("macOS prompts to confirm browser changes. Accessibility permission lets the app auto-confirm in 0.05s for a true 1-click experience.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Item 3: Launch at Login
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Launch at Login")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Toggle("", isOn: $isLaunchAtLoginEnabled)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .onChange(of: isLaunchAtLoginEnabled) { newValue in
                                    SystemHelper.shared.setLaunchAtLogin(enabled: newValue)
                                }
                        }

                        Text("Automatically start DefaultBrowserChanger in your menu bar when you log in.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Footer / Action Button
            Button(action: onDismiss) {
                Text("Get Started")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 480, height: 460)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshState()
        }
        .onAppear {
            refreshState()
        }
    }

    private func refreshState() {
        isAccessibilityGranted = SystemHelper.shared.isAccessibilityGranted
        isLaunchAtLoginEnabled = SystemHelper.shared.isLaunchAtLoginEnabled
    }
}
