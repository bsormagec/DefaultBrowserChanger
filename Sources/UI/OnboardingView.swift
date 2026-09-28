import SwiftUI

public struct OnboardingView: View {
    @State private var isDefaultBrowser: Bool = SystemHelper.shared.isDefaultBrowser
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

                Text("Instant Default Browser Switching for macOS")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            // Features List
            VStack(alignment: .leading, spacing: 18) {
                // Item 1: Set as Default Browser
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: isDefaultBrowser ? "checkmark.seal.fill" : "gearshape.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(isDefaultBrowser ? .green : .blue)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("1. Set as Default Browser")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            if isDefaultBrowser {
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
                                Button("Open Settings") {
                                    SystemHelper.shared.openDesktopAndDockSettings()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }

                        Text("In System Settings → Desktop & Dock, choose DefaultBrowserChanger.app in the 'Default web browser' dropdown.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Item 2: Global Hotkey
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 20))
                        .foregroundColor(.indigo)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("2. Instant Hotkey Switching (⌃⌥B)")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Press Control + Option + B anywhere to cycle through installed browsers instantly, with zero prompts and audio feedback.")
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

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("3. Launch at Login")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Toggle("", isOn: $isLaunchAtLoginEnabled)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .onChange(of: isLaunchAtLoginEnabled) { newValue in
                                    SystemHelper.shared.setLaunchAtLogin(enabled: newValue)
                                }
                        }

                        Text("Start DefaultBrowserChanger quietly in your menu bar when you log in.")
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
        .frame(width: 480, height: 470)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshState()
        }
        .onAppear {
            refreshState()
        }
    }

    private func refreshState() {
        isDefaultBrowser = SystemHelper.shared.isDefaultBrowser
        isLaunchAtLoginEnabled = SystemHelper.shared.isLaunchAtLoginEnabled
    }
}
