import Foundation

final class TabManager: ObservableObject {
    @Published var tabs: [TerminalTab] = []
    @Published var selectedTabID: UUID?

    // TerminalViewModel 存在 class 裡，KeyboardHandler 可安全 reference
    var viewModels: [UUID: TerminalViewModel] = [:]

    var selectedTab: TerminalTab? {
        tabs.first { $0.id == selectedTabID }
    }

    func addTab(workingDirectory: String = NSHomeDirectory()) {
        let tab = TerminalTab(workingDirectory: workingDirectory)
        tabs.append(tab)
        selectedTabID = tab.id
    }

    func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        viewModels[id]?.terminateSession()
        viewModels.removeValue(forKey: id)
        tabs.remove(at: index)
        if selectedTabID == id {
            selectedTabID = tabs.isEmpty ? nil : tabs[max(0, index - 1)].id
        }
    }

    func selectTab(id: UUID) {
        selectedTabID = id
    }

    func selectTab(at index: Int) {
        guard index < tabs.count else { return }
        selectedTabID = tabs[index].id
    }

    func selectNextTab() {
        guard !tabs.isEmpty,
              let current = selectedTabID,
              let index = tabs.firstIndex(where: { $0.id == current }) else { return }
        selectedTabID = tabs[(index + 1) % tabs.count].id
    }

    func selectPreviousTab() {
        guard !tabs.isEmpty,
              let current = selectedTabID,
              let index = tabs.firstIndex(where: { $0.id == current }) else { return }
        selectedTabID = tabs[(index - 1 + tabs.count) % tabs.count].id
    }
}
