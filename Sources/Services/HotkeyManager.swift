import AppKit
import Carbon

public class HotkeyManager: NSObject {
    public static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotkeyEnabledKey = "isHotkeyCycleEnabled"
    private let hotkeyKeyCodeKey = "customHotkeyKeyCode"
    private let hotkeyModifiersKey = "customHotkeyModifiers"
    private let hotkeyDisplayKey = "customHotkeyDisplayString"

    public var isHotkeyEnabled: Bool {
        get {
            // Default to true if not explicitly set
            if UserDefaults.standard.object(forKey: hotkeyEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: hotkeyEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hotkeyEnabledKey)
            if newValue {
                registerHotkey()
            } else {
                unregisterHotkey()
            }
        }
    }

    public var keyCode: UInt32 {
        get {
            if UserDefaults.standard.object(forKey: hotkeyKeyCodeKey) == nil {
                return 11 // Default: 'B' key (11)
            }
            return UInt32(UserDefaults.standard.integer(forKey: hotkeyKeyCodeKey))
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: hotkeyKeyCodeKey)
        }
    }

    public var modifiers: UInt32 {
        get {
            if UserDefaults.standard.object(forKey: hotkeyModifiersKey) == nil {
                return UInt32(controlKey | optionKey) // Default: Control + Option
            }
            return UInt32(UserDefaults.standard.integer(forKey: hotkeyModifiersKey))
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: hotkeyModifiersKey)
        }
    }

    public var shortcutDisplayString: String {
        get {
            if let saved = UserDefaults.standard.string(forKey: hotkeyDisplayKey), !saved.isEmpty {
                return saved
            }
            return "⌃⌥B"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hotkeyDisplayKey)
        }
    }

    public func updateShortcut(keyCode: UInt32, modifiers: UInt32, displayString: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.shortcutDisplayString = displayString
        if isHotkeyEnabled {
            registerHotkey()
        }
    }

    public func resetToDefaultShortcut() {
        updateShortcut(keyCode: 11, modifiers: UInt32(controlKey | optionKey), displayString: "⌃⌥B")
    }

    public static func stringForKeyCode(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 36: return "↩"
        case 48: return "⇥"
        case 49: return "Space"
        case 51: return "⌫"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        default: return ""
        }
    }

    public override init() {
        super.init()
    }

    public func setup() {
        if isHotkeyEnabled {
            registerHotkey()
        }
    }

    public func registerHotkey() {
        unregisterHotkey()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handlerResult = InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, event, _) -> OSStatus in
                HotkeyManager.shared.handleHotkeyTrigger()
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard handlerResult == noErr else {
            NSLog("HotkeyManager: Failed to install event handler: %d", handlerResult)
            return
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x44424331), id: 1) // 'DBC1'
        let currentKeyCode = self.keyCode
        let currentModifiers = self.modifiers

        let registerResult = RegisterEventHotKey(
            currentKeyCode,
            currentModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if registerResult == noErr {
            NSLog("HotkeyManager: Registered global shortcut %@ successfully", shortcutDisplayString)
        } else {
            NSLog("HotkeyManager: Failed to register hotkey: %d", registerResult)
        }
    }

    public func unregisterHotkey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    private var lastTriggerTime: TimeInterval = 0

    private func handleHotkeyTrigger() {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastTriggerTime > 0.35 else {
            NSLog("HotkeyManager: Debouncing rapid hotkey press (interval: %.2fs)", now - lastTriggerTime)
            return
        }
        lastTriggerTime = now

        DispatchQueue.main.async { [weak self] in
            LinkRouter.shared.cycleNextBrowser { browser in
                guard let browser = browser else { return }

                HUDController.shared.show(browser: browser)

                let shortcutText = self?.shortcutDisplayString ?? "⌃⌥B"
                SystemHelper.shared.postNotification(
                    title: "Active Browser Changed",
                    message: "\(browser.name) is now your active browser. (via \(shortcutText))",
                    playSound: false
                )
            }
        }
    }
}
