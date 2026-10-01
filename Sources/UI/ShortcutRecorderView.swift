import AppKit
import SwiftUI
import Carbon

public struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var displayString: String
    var onShortcutRecorded: ((UInt32, UInt32, String) -> Void)?

    public init(
        isRecording: Binding<Bool>,
        displayString: Binding<String>,
        onShortcutRecorded: ((UInt32, UInt32, String) -> Void)? = nil
    ) {
        self._isRecording = isRecording
        self._displayString = displayString
        self.onShortcutRecorded = onShortcutRecorded
    }

    public func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.coordinator = context.coordinator
        view.displayString = displayString
        return view
    }

    public func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.coordinator = context.coordinator
        nsView.displayString = displayString
        if nsView.isRecording != isRecording {
            nsView.isRecording = isRecording
        }
        nsView.needsDisplay = true
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator {
        var parent: ShortcutRecorderView

        init(_ parent: ShortcutRecorderView) {
            self.parent = parent
        }

        func record(keyCode: UInt32, modifiers: UInt32, display: String) {
            parent.displayString = display
            parent.isRecording = false
            parent.onShortcutRecorded?(keyCode, modifiers, display)
        }

        func cancel() {
            parent.isRecording = false
        }
    }
}

public class ShortcutRecorderNSView: NSView {
    var coordinator: ShortcutRecorderView.Coordinator?
    var displayString: String = "⌃⌥B"
    var isRecording: Bool = false {
        didSet {
            if isRecording {
                window?.makeFirstResponder(self)
            }
            needsDisplay = true
        }
    }

    override public var acceptsFirstResponder: Bool { true }

    override public func becomeFirstResponder() -> Bool {
        needsDisplay = true
        return true
    }

    override public func resignFirstResponder() -> Bool {
        if isRecording {
            isRecording = false
            coordinator?.cancel()
        }
        needsDisplay = true
        return true
    }

    override public func mouseDown(with event: NSEvent) {
        isRecording.toggle()
        if isRecording {
            window?.makeFirstResponder(self)
        } else {
            coordinator?.cancel()
        }
    }

    override public func keyDown(with event: NSEvent) {
        if !isRecording {
            super.keyDown(with: event)
            return
        }

        // Escape cancels recording
        if event.keyCode == 53 {
            isRecording = false
            coordinator?.cancel()
            return
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var carbonMods: UInt32 = 0
        var symbols = ""

        if flags.contains(.control) {
            carbonMods |= UInt32(controlKey)
            symbols += "⌃"
        }
        if flags.contains(.option) {
            carbonMods |= UInt32(optionKey)
            symbols += "⌥"
        }
        if flags.contains(.shift) {
            carbonMods |= UInt32(shiftKey)
            symbols += "⇧"
        }
        if flags.contains(.command) {
            carbonMods |= UInt32(cmdKey)
            symbols += "⌘"
        }

        let specialKey = HotkeyManager.stringForKeyCode(event.keyCode)
        let keyChar = specialKey.isEmpty ? (event.charactersIgnoringModifiers?.uppercased() ?? "") : specialKey

        let isFunctionKey = (event.keyCode >= 122 && event.keyCode <= 126) ||
                            (event.keyCode >= 96 && event.keyCode <= 101) ||
                            (event.keyCode >= 109 && event.keyCode <= 111) ||
                            event.keyCode == 103 || event.keyCode == 99 || event.keyCode == 118

        // Require at least one modifier key or function key
        guard !symbols.isEmpty || isFunctionKey else {
            NSSound.beep()
            return
        }

        guard !keyChar.isEmpty else { return }

        let fullDisplay = symbols + keyChar
        isRecording = false
        coordinator?.record(keyCode: UInt32(event.keyCode), modifiers: carbonMods, display: fullDisplay)
    }

    override public func performKeyEquivalent(with event: NSEvent) -> Bool {
        if isRecording {
            keyDown(with: event)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bounds = self.bounds
        let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6)

        if isRecording {
            NSColor.systemRed.withAlphaComponent(0.12).setFill()
            bgPath.fill()
            NSColor.systemRed.setStroke()
            bgPath.lineWidth = 1.2
            bgPath.stroke()

            let text = "Press keys..."
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: NSColor.systemRed
            ]
            let str = NSAttributedString(string: text, attributes: attrs)
            let strSize = str.size()
            let point = NSPoint(x: (bounds.width - strSize.width) / 2, y: (bounds.height - strSize.height) / 2)
            str.draw(at: point)
        } else {
            NSColor.controlColor.setFill()
            bgPath.fill()
            NSColor.separatorColor.setStroke()
            bgPath.lineWidth = 1.0
            bgPath.stroke()

            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
            let str = NSAttributedString(string: displayString, attributes: attrs)
            let strSize = str.size()
            let point = NSPoint(x: (bounds.width - strSize.width) / 2, y: (bounds.height - strSize.height) / 2)
            str.draw(at: point)
        }
    }
}
