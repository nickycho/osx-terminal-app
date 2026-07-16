import AppKit
import Foundation

final class KeyboardHandler {
    private var eventMonitor: Any?
    private let tabManager: TabManager
    private let shortcutSettings: ShortcutSettings
    var openSettingsAction: (() -> Void)?

    init(tabManager: TabManager, shortcutSettings: ShortcutSettings) {
        self.tabManager = tabManager
        self.shortcutSettings = shortcutSettings
    }

    func start() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            let key = event.charactersIgnoringModifiers?.lowercased() ?? ""

            for action in ShortcutAction.allCases {
                let s = self.shortcutSettings.shortcut(for: action)
                guard s.key == key && s.modifiers == mods else { continue }
                self.handleAction(action)
                return nil
            }
            return event
        }
    }

    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleAction(_ action: ShortcutAction) {
        switch action {
        case .newTab:
            tabManager.addTab()
        case .closeTab:
            if let id = tabManager.selectedTabID {
                tabManager.closeTab(id: id)
            }
        case .nextTab:
            tabManager.selectNextTab()
        case .previousTab:
            tabManager.selectPreviousTab()
        case .clearBuffer:
            if let id = tabManager.selectedTabID,
               let vm = tabManager.viewModels[id] {
                vm.clearBuffer()
            }
        case .openSettings:
            openSettingsAction?()
        }
    }
}
