import AppKit
import Carbon

public class HotkeyManager: NSObject {
    public static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotkeyEnabledKey = "isHotkeyCycleEnabled"

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
            GetApplicationEventTarget(),
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
        let keyCode: UInt32 = 11 // 'B' key
        let modifiers: UInt32 = UInt32(controlKey | optionKey)

        let registerResult = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerResult == noErr {
            NSLog("HotkeyManager: Registered global shortcut Control+Option+B successfully")
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

    private func handleHotkeyTrigger() {
        DispatchQueue.main.async {
            BrowserManager.shared.cycleNextDefaultBrowser { browser in
                guard let browser = browser else { return }

                SystemHelper.shared.postNotification(
                    title: "Default Browser Changed",
                    message: "\(browser.name) is now your default browser. (via ⌃⌥B)"
                )
            }
        }
    }
}
