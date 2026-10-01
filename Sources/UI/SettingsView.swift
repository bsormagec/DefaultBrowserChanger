import SwiftUI
import AppKit
import Carbon

public struct SettingsView: View {
    @State private var installedBrowsers: [BrowserApp] = []
    @State private var cycleEnabledIds: Set<String> = []
    @State private var activeBrowserId: String = ""
    @State private var isLaunchAtLogin: Bool = false
    @State private var isHotkeyEnabled: Bool = true
    @State private var showSingleBrowserAlert: Bool = false
    @State private var shortcutDisplayString: String = "⌃⌥B"
    @State private var isRecordingShortcut: Bool = false

    public var onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 18) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Browser Switch Settings")
                        .font(.system(size: 16, weight: .bold))
                    Text("Select which browsers will be included when cycling with \(shortcutDisplayString)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.top, 4)

            // Browsers Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Installed Browsers")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: selectAllBrowsers) {
                        Text("Select All")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.accentColor)
                }

                // Scrollable Browser List
                ScrollView {
                    LazyVStack(spacing: 4) {
                        if installedBrowsers.isEmpty {
                            Text("No browsers found")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(installedBrowsers) { browser in
                                browserRow(browser)
                            }
                        }
                    }
                    .padding(6)
                }
                .frame(height: 210)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.8)
                )

                // Counter / Hint
                HStack {
                    let enabledCount = installedBrowsers.filter { cycleEnabledIds.contains($0.id) }.count
                    let totalCount = installedBrowsers.count
                    Text("\(enabledCount) of \(totalCount) browsers active in cycle shortcut")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Spacer()

                    if showSingleBrowserAlert {
                        Text("At least 1 browser must be active")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }

            Divider()

            // General Preferences
            VStack(alignment: .leading, spacing: 10) {
                Text("General")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at Login")
                            .font(.system(size: 13))
                        Text("Automatically start DefaultBrowserChanger when logging in")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $isLaunchAtLogin)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .onChange(of: isLaunchAtLogin) { newValue in
                            SystemHelper.shared.setLaunchAtLogin(enabled: newValue)
                        }
                }

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cycle Shortcut")
                            .font(.system(size: 13))
                        if isRecordingShortcut {
                            Text("Press shortcut keys now (Esc to cancel)...")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.accentColor)
                        } else {
                            Text("Click badge to customize keyboard shortcut")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Reset button if customized
                    if shortcutDisplayString != "⌃⌥B" && !isRecordingShortcut {
                        Button(action: resetShortcut) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("Reset to ⌃⌥B")
                    }

                    // Native Shortcut Recorder View
                    ShortcutRecorderView(
                        isRecording: $isRecordingShortcut,
                        displayString: $shortcutDisplayString
                    ) { keyCode, modifiers, display in
                        HotkeyManager.shared.updateShortcut(
                            keyCode: keyCode,
                            modifiers: modifiers,
                            displayString: display
                        )
                        SystemHelper.shared.playFeedbackSound()
                    }
                    .frame(width: isRecordingShortcut ? 105 : 74, height: 26)

                    Toggle("", isOn: $isHotkeyEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .onChange(of: isHotkeyEnabled) { newValue in
                            HotkeyManager.shared.isHotkeyEnabled = newValue
                        }
                }
            }

            Spacer()

            // Footer
            HStack {
                Button("Welcome Guide...") {
                    OnboardingController.shared.showWindow(force: true)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12))

                Spacer()

                Button("Done", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 480, height: 540)
        .onAppear {
            loadState()
        }
        .onDisappear {
            isRecordingShortcut = false
        }
    }

    @ViewBuilder
    private func browserRow(_ browser: BrowserApp) -> some View {
        let isEnabled = cycleEnabledIds.contains(browser.id)
        let isActive = (browser.id == activeBrowserId)

        Button(action: {
            toggleBrowser(bundleId: browser.id, isEnabled: !isEnabled)
        }) {
            HStack(spacing: 10) {
                // Checkbox icon
                Image(systemName: isEnabled ? "checkmark.square.fill" : "square")
                    .font(.system(size: 15))
                    .foregroundColor(isEnabled ? .accentColor : .secondary)
                    .frame(width: 20)

                // App Icon
                Image(nsImage: browser.icon)
                    .resizable()
                    .frame(width: 22, height: 22)

                // App Name & Bundle ID
                VStack(alignment: .leading, spacing: 1) {
                    Text(browser.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isEnabled ? .primary : .secondary)

                    Text(browser.id)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Active Badge
                if isActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("Active")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func loadState() {
        installedBrowsers = BrowserManager.shared.fetchInstalledBrowsers()
        cycleEnabledIds = BrowserManager.shared.getCycleEnabledBrowserIds()
        activeBrowserId = LinkRouter.shared.activeBrowserId
        isLaunchAtLogin = SystemHelper.shared.isLaunchAtLoginEnabled
        isHotkeyEnabled = HotkeyManager.shared.isHotkeyEnabled
        shortcutDisplayString = HotkeyManager.shared.shortcutDisplayString
    }

    private func toggleBrowser(bundleId: String, isEnabled: Bool) {
        showSingleBrowserAlert = false
        if isEnabled {
            cycleEnabledIds.insert(bundleId)
            BrowserManager.shared.setCycleEnabledBrowserIds(cycleEnabledIds)
        } else {
            if cycleEnabledIds.count > 1 {
                cycleEnabledIds.remove(bundleId)
                BrowserManager.shared.setCycleEnabledBrowserIds(cycleEnabledIds)
            } else {
                showSingleBrowserAlert = true
                SystemHelper.shared.playFeedbackSound()
            }
        }
    }

    private func selectAllBrowsers() {
        showSingleBrowserAlert = false
        cycleEnabledIds = Set(installedBrowsers.map { $0.id })
        BrowserManager.shared.setCycleEnabledBrowserIds(cycleEnabledIds)
    }

    private func resetShortcut() {
        isRecordingShortcut = false
        HotkeyManager.shared.resetToDefaultShortcut()
        shortcutDisplayString = HotkeyManager.shared.shortcutDisplayString
        SystemHelper.shared.playFeedbackSound()
    }
}
