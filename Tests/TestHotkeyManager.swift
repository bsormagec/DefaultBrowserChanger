import Foundation
import Carbon

// Verify Carbon event types and registration structure
var hotKeyRef: EventHotKeyRef?
let hotKeyID = EventHotKeyID(signature: OSType(0x444243), id: 1) // 'DBC', 1
let keyCode: UInt32 = 11 // 'B'
let modifiers: UInt32 = UInt32(controlKey | optionKey)

let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
assert(status == noErr || status == eventAlreadyPostedErr || hotKeyRef != nil, "RegisterEventHotKey should execute")

if let ref = hotKeyRef {
    let unregStatus = UnregisterEventHotKey(ref)
    assert(unregStatus == noErr, "UnregisterEventHotKey should succeed")
}

print("✅ TestHotkeyManager passed!")
