import AppKit
import SwiftUI

final class TerminalWindowManager: NSObject, ObservableObject {
    private(set) weak var tabManager: TabManager?
    private var controllers: [UUID: DetachedTerminalWindowController] = [:]

    func attach(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    func detach(tabID: UUID) {
        guard let tabManager,
              let tab = tabManager.tabs.first(where: { $0.id == tabID }),
              !tab.isDetached,
              controllers[tabID] == nil else { return }

        let viewModel = tabManager.viewModel(for: tab)
        let controller = DetachedTerminalWindowController(
            tabID: tabID,
            owner: self,
            viewModel: viewModel
        )

        tabManager.detachTab(id: tabID)
        controllers[tabID] = controller

        controller.window?.title = tab.displayTitle
        controller.window?.center()
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    func closeDetached(tabID: UUID) {
        guard controllers.removeValue(forKey: tabID) != nil else { return }
        tabManager?.closeTab(id: tabID)
    }
}

final class DetachedTerminalWindowController: NSWindowController, NSWindowDelegate {
    let tabID: UUID
    weak var windowManager: TerminalWindowManager?

    init(tabID: UUID, owner: TerminalWindowManager, viewModel: TerminalViewModel) {
        self.tabID = tabID
        self.windowManager = owner

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = NSHostingController(
            rootView: DetachedTerminalWindowView(viewModel: viewModel)
        )
        super.init(window: window)
        window.delegate = self
        window.isReleasedWhenClosed = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        windowManager?.closeDetached(tabID: tabID)
    }
}

struct DetachedTerminalWindowView: View {
    let viewModel: TerminalViewModel

    var body: some View {
        TerminalContainerView(viewModel: viewModel, isSelected: true)
            .frame(minWidth: 600, minHeight: 400)
    }
}
