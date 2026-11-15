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
    @State private var rules: [DomainRule] = []
    @State private var isCleanLinks: Bool = true
    @State private var isCheckForUpdates: Bool = true
    @State private var testLink: String = ""
    @State private var sourceApps: [(id: String, name: String)] = []

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
                .frame(height: 170)
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

            // Link Rules
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Link Rules")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("Links matching a site and/or app open in the chosen browser")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: addRule) {
                        Label("Add Rule", systemImage: "plus")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.accentColor)
                }

                ScrollView {
                    VStack(spacing: 4) {
                        if rules.isEmpty {
                            Text("No rules — all links go to the active browser")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 12)
                        }
                        ForEach($rules) { $rule in
                            let index = rules.firstIndex { $0.id == rule.id } ?? 0
                            HStack(spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                                    .foregroundColor(.secondary)
                                    .frame(width: 18, alignment: .trailing)
                                TextField(rule.sourceApp == nil ? "example.com" : "any link", text: $rule.pattern)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12))
                                Picker("", selection: $rule.sourceApp) {
                                    Text("From any app").tag(String?.none)
                                    ForEach(sourceApps, id: \.id) { app in
                                        Text("From \(app.name)").tag(Optional(app.id))
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 130)
                                .help("Only links clicked in this app")
                                Picker("", selection: $rule.browserId) {
                                    ForEach(installedBrowsers) { browser in
                                        Text(browser.name).tag(browser.id)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 240)
                                // First match wins, so order matters.
                                VStack(spacing: 0) {
                                    Button(action: { moveRule(at: index, by: -1) }) {
                                        Image(systemName: "chevron.up").font(.system(size: 9, weight: .semibold))
                                    }
                                    .disabled(index == 0)
                                    .help("Move up")
                                    Button(action: { moveRule(at: index, by: 1) }) {
                                        Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                                    }
                                    .disabled(index == rules.count - 1)
                                    .help("Move down")
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.secondary)
                                Button(action: { rules.removeAll { $0.id == rule.id } }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .help("Remove rule")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(6)
                }
                .frame(height: 110)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.8)
                )
                .onChange(of: rules) { DomainRule.save($0) }

                // Rule tester: shows where a pasted link would go with the rules as they are right now.
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "checkmark.shield")
                        .foregroundColor(.secondary)
                    TextField("Test a link, e.g. https://github.com/work-org/repo", text: $testLink)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                }
                if let result = testResult {
                    Text(result)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
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

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clean Links")
                            .font(.system(size: 13))
                        Text("Strip tracking parameters and unwrap redirect links")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $isCleanLinks)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .onChange(of: isCleanLinks) { LinkCleaner.isEnabled = $0 }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Check for Updates")
                            .font(.system(size: 13))
                        Text("Ask GitHub once a day for a new release — the app's only network request")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $isCheckForUpdates)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .onChange(of: isCheckForUpdates) {
                            UpdateChecker.isEnabled = $0
                            UpdateChecker.shared.check()
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
        .frame(width: 640, height: 840)
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

                    Text(browser.id.replacingOccurrences(of: "#", with: " · "))
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
        BrowserManager.shared.invalidateBrowserCache()
        installedBrowsers = BrowserManager.shared.fetchInstalledBrowsers()
        cycleEnabledIds = BrowserManager.shared.getCycleEnabledBrowserIds()
        activeBrowserId = LinkRouter.shared.activeBrowserId
        isLaunchAtLogin = SystemHelper.shared.isLaunchAtLoginEnabled
        isHotkeyEnabled = HotkeyManager.shared.isHotkeyEnabled
        shortcutDisplayString = HotkeyManager.shared.shortcutDisplayString
        rules = DomainRule.load()
        isCleanLinks = LinkCleaner.isEnabled
        isCheckForUpdates = UpdateChecker.isEnabled
        sourceApps = loadSourceApps()
    }

    /// Apps links can come from: running apps with a Dock icon, plus any app already used in a rule.
    private func loadSourceApps() -> [(id: String, name: String)] {
        let browserIds = Set(installedBrowsers.map { $0.id })
        var apps: [String: String] = [:]
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            guard let id = app.bundleIdentifier, !browserIds.contains(id), id != Bundle.main.bundleIdentifier else { continue }
            apps[id] = app.localizedName ?? id
        }
        for id in rules.compactMap(\.sourceApp) where apps[id] == nil {
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)
            apps[id] = url.map { FileManager.default.displayName(atPath: $0.path).replacingOccurrences(of: ".app", with: "") } ?? id
        }
        return apps.map { (id: $0.key, name: $0.value) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func moveRule(at index: Int, by offset: Int) {
        let target = index + offset
        guard rules.indices.contains(index), rules.indices.contains(target) else { return }
        rules.swapAt(index, target)
    }

    private var testResult: String? {
        let text = testLink.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        guard let url = URL(string: text.contains("://") ? text : "https://" + text), url.host != nil else {
            return "Enter a link like https://example.com/page"
        }
        let result = LinkRouter.shared.resolve(url, rules: rules)
        var lines = ["→ " + (result.browser?.name ?? "no browser found")
                     + (result.ruleIndex.map { " · rule \($0 + 1)" } ?? " · active browser (no rule matches)")]
        if result.url != url { lines.append("Cleaned to: " + result.url.absoluteString) }
        if rules.contains(where: { $0.sourceApp != nil }) { lines.append("Rules limited to an app are skipped in this test.") }
        return lines.joined(separator: "\n")
    }

    private func addRule() {
        rules.append(DomainRule(pattern: "", browserId: activeBrowserId))
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
