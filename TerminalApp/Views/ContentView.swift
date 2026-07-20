import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var tabManager: TabManager
    @EnvironmentObject var shortcutSettings: ShortcutSettings
    @Environment(\.openSettings) private var openSettings

    @State private var keyboardHandler: KeyboardHandler?

    var body: some View {
        VStack(spacing: 0) {
            TabBarView()

            Divider()

            ZStack {
                if tabManager.attachedTabs.isEmpty {
                    emptyStateView
                } else {
                    ForEach(tabManager.attachedTabs) { tab in
                        let isSelected = tab.id == tabManager.selectedTabID
                        TerminalContainerView(viewModel: tabManager.viewModel(for: tab), isSelected: isSelected)
                            .opacity(isSelected ? 1 : 0)
                            .allowsHitTesting(isSelected)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            if tabManager.tabs.isEmpty {
                tabManager.addTab()
            }
            if keyboardHandler == nil {
                let handler = KeyboardHandler(tabManager: tabManager, shortcutSettings: shortcutSettings)
                handler.openSettingsAction = { openSettings() }
                handler.start()
                keyboardHandler = handler
            }
            ScheduleManager.shared.openSettingsAction = { openSettings() }
        }
        .onDisappear {
            keyboardHandler?.stop()
            keyboardHandler = nil
        }
    }

    private var emptyStateView: some View {
        Text("按 ⌘T 開啟新分頁")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}
