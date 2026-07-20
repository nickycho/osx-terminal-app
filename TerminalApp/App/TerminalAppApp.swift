import SwiftUI

@main
struct TerminalAppApp: App {
    @StateObject private var tabManager = TabManager()
    @StateObject private var shortcutSettings = ShortcutSettings.shared
    @StateObject private var scheduleManager = ScheduleManager.shared
    @StateObject private var windowManager = TerminalWindowManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tabManager)
                .environmentObject(shortcutSettings)
                .environmentObject(scheduleManager)
                .environmentObject(windowManager)
                .onAppear {
                    ScheduleManager.shared.tabManager = tabManager
                    ScheduleManager.shared.startTimer()
                    ScheduleManager.shared.requestNotificationPermission()
                    windowManager.attach(tabManager: tabManager)
                }
        }
        .commands {
            TerminalMenuCommands(tabManager: tabManager)
            ScheduleMenuCommands(scheduleManager: scheduleManager)
        }

        Settings {
            SettingsView()
                .environmentObject(shortcutSettings)
                .environmentObject(scheduleManager)
                .environmentObject(tabManager)
        }
    }
}

struct TerminalMenuCommands: Commands {
    let tabManager: TabManager

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("新增分頁") {
                tabManager.addTab()
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("關閉分頁") {
                if let id = tabManager.selectedTabID {
                    tabManager.closeTab(id: id)
                }
            }
            .keyboardShortcut("w", modifiers: .command)

            Divider()

            Button("下一個分頁") {
                tabManager.selectNextTab()
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])

            Button("上一個分頁") {
                tabManager.selectPreviousTab()
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])
        }
    }
}
