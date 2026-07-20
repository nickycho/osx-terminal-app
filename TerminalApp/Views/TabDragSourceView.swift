import AppKit
import SwiftUI

struct TabDragSourceView: NSViewRepresentable {
    let tabID: UUID
    let onDragStarted: () -> Void
    let onDragEnded: () -> Void
    let onClick: () -> Void
    let onDetach: (UUID) -> Void

    func makeNSView(context: Context) -> TabDragSourceNSView {
        let view = TabDragSourceNSView()
        update(view)
        return view
    }

    func updateNSView(_ view: TabDragSourceNSView, context: Context) {
        update(view)
    }

    private func update(_ view: TabDragSourceNSView) {
        view.tabID = tabID
        view.onDragStarted = onDragStarted
        view.onDragEnded = onDragEnded
        view.onClick = onClick
        view.onDetach = onDetach
    }
}

final class TabDragSourceNSView: NSView, NSDraggingSource {
    var tabID = UUID()
    var onDragStarted: (() -> Void)?
    var onDragEnded: (() -> Void)?
    var onClick: (() -> Void)?
    var onDetach: ((UUID) -> Void)?

    private var draggingSession: NSDraggingSession?

    override var acceptsFirstResponder: Bool {
        false
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        focusRingType = .none
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        focusRingType = .none
    }

    override func mouseDown(with event: NSEvent) {
        // Keep the handle out of the key-view chain; it only owns drag/click events.
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard draggingSession == nil else { return }

        let item = NSPasteboardItem()
        item.setString(tabID.uuidString, forType: .string)

        let draggingItem = NSDraggingItem(pasteboardWriter: item)
        draggingItem.setDraggingFrame(bounds, contents: nil)
        draggingSession = beginDraggingSession(with: [draggingItem], event: event, source: self)
        onDragStarted?()
    }

    override func mouseUp(with event: NSEvent) {
        guard draggingSession == nil else { return }
        onClick?()
        onDragEnded?()
    }

    func draggingSession(_ session: NSDraggingSession,
                         sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .move
    }

    func draggingSession(_ session: NSDraggingSession,
                         endedAt screenPoint: NSPoint,
                         operation: NSDragOperation) {
        // `operation` describes the drop result; the screen point determines whether
        // the tab was released outside the main window.
        let endedOutsideSourceWindow = !(window?.frame.contains(screenPoint) ?? true)
        if endedOutsideSourceWindow {
            onDetach?(tabID)
        }
        draggingSession = nil
        onDragEnded?()
    }
}
