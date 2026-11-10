import SwiftUI
import AppKit

struct ShortcutRecorderView: NSViewRepresentable {
    @Environment(\.locale) private var locale
    let shortcut: KeyboardShortcutData
    let isRecording: Bool
    let onStartRecording: () -> Void
    let onFinishRecording: (KeyboardShortcutData) -> Void
    let onCancelRecording: () -> Void

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.coordinator = context.coordinator
        view.displayShortcut = shortcut
        view.isRecording = isRecording
        view.recordingText = String(localized: "Press a shortcut…", locale: locale)
        view.unassignedText = String(localized: "Not Set", locale: locale)
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.coordinator = context.coordinator
        nsView.displayShortcut = shortcut
        nsView.isRecording = isRecording
        nsView.recordingText = String(localized: "Press a shortcut…", locale: locale)
        nsView.unassignedText = String(localized: "Not Set", locale: locale)
        nsView.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onStartRecording: onStartRecording,
            onFinishRecording: onFinishRecording,
            onCancelRecording: onCancelRecording
        )
    }

    class Coordinator {
        let onStartRecording: () -> Void
        let onFinishRecording: (KeyboardShortcutData) -> Void
        let onCancelRecording: () -> Void

        init(
            onStartRecording: @escaping () -> Void,
            onFinishRecording: @escaping (KeyboardShortcutData) -> Void,
            onCancelRecording: @escaping () -> Void
        ) {
            self.onStartRecording = onStartRecording
            self.onFinishRecording = onFinishRecording
            self.onCancelRecording = onCancelRecording
        }
    }
}

final class ShortcutRecorderNSView: NSControl {
    var isRecording = false { didSet { needsDisplay = true } }
    var displayShortcut: KeyboardShortcutData? { didSet { needsDisplay = true } }
    var recordingText = "Press a shortcut…"
    var unassignedText = "Not Set"
    var coordinator: ShortcutRecorderView.Coordinator?

    override var intrinsicContentSize: NSSize {
        NSSize(width: 120, height: 24)
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let bgColor: NSColor = isRecording
            ? NSColor.selectedControlColor
            : NSColor.controlBackgroundColor
        bgColor.setFill()

        let path = NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4)
        path.fill()

        NSColor.separatorColor.setStroke()
        path.lineWidth = 0.5
        path.stroke()

        let text = isRecording ? recordingText : (displayShortcut?.displayString ?? unassignedText)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: isRecording ? NSColor.secondaryLabelColor : NSColor.labelColor
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let strSize = str.size()
        let x = (bounds.width - strSize.width) / 2
        let y = (bounds.height - strSize.height) / 2
        str.draw(at: NSPoint(x: x, y: y))
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        coordinator?.onStartRecording()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        // Escape 取消錄製
        if event.keyCode == 53 {
            coordinator?.onCancelRecording()
            return
        }

        guard let chars = event.charactersIgnoringModifiers, !chars.isEmpty else { return }

        let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
        // 至少要有一個修飾鍵（避免誤觸一般字元）
        guard !mods.isEmpty else { return }

        let data = KeyboardShortcutData(key: chars.lowercased(), modifiers: mods)
        coordinator?.onFinishRecording(data)
    }

    override func flagsChanged(with event: NSEvent) {
        // 讓純修飾鍵按下不觸發錄製
    }
}
