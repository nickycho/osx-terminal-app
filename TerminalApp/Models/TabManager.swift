import Foundation

final class TabManager: ObservableObject {
    @Published var tabs: [TerminalTab] = []
    @Published var selectedTabID: UUID?

    // TerminalViewModel 存在 class 裡，KeyboardHandler 可安全 reference
    var viewModels: [UUID: TerminalViewModel] = [:]

    var selectedTab: TerminalTab? {
        attachedTabs.first { $0.id == selectedTabID }
    }

    var attachedTabs: [TerminalTab] {
        tabs.filter { !$0.isDetached }
    }

    func viewModel(for tab: TerminalTab) -> TerminalViewModel {
        if let existing = viewModels[tab.id] { return existing }
        let viewModel = TerminalViewModel(tab: tab)
        viewModels[tab.id] = viewModel
        return viewModel
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
            selectedTabID = attachedTabs.first?.id
        }
    }

    func selectTab(id: UUID) {
        guard attachedTabs.contains(where: { $0.id == id }) else { return }
        selectedTabID = id
    }

    func selectTab(at index: Int) {
        guard index < attachedTabs.count else { return }
        selectedTabID = attachedTabs[index].id
    }

    func detachTab(id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }), !tab.isDetached else { return }
        objectWillChange.send()
        tab.isDetached = true
        if selectedTabID == id {
            selectedTabID = attachedTabs.first?.id
        }
    }

    func selectNextTab() {
        let visibleTabs = attachedTabs
        guard !visibleTabs.isEmpty,
              let current = selectedTabID,
              let index = visibleTabs.firstIndex(where: { $0.id == current }) else { return }
        selectedTabID = visibleTabs[(index + 1) % visibleTabs.count].id
    }

    func selectPreviousTab() {
        let visibleTabs = attachedTabs
        guard !visibleTabs.isEmpty,
              let current = selectedTabID,
              let index = visibleTabs.firstIndex(where: { $0.id == current }) else { return }
        selectedTabID = visibleTabs[(index - 1 + visibleTabs.count) % visibleTabs.count].id
    }
}
