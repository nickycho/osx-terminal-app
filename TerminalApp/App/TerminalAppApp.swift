import SwiftUI

@main
struct TerminalAppApp: App {
    @StateObject private var tabManager = TabManager()
    @StateObject private var shortcutSettings = ShortcutSettings.shared
    @StateObject private var scheduleManager = ScheduleManager.shared
    @StateObject private var windowManager = TerminalWindowManager()
    @StateObject private var appearanceSettings = AppearanceSettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tabManager)
                .environmentObject(shortcutSettings)
                .environmentObject(scheduleManager)
                .environmentObject(windowManager)
                .environmentObject(appearanceSettings)
                .environment(\.locale, appearanceSettings.locale)
                .onAppear {
                    ScheduleManager.shared.tabManager = tabManager
                    ScheduleManager.shared.startTimer()
                    ScheduleManager.shared.requestNotificationPermission()
                    windowManager.attach(tabManager: tabManager)
                }
        }
        .commands {
            TerminalMenuCommands(tabManager: tabManager, appearanceSettings: appearanceSettings)
            ScheduleMenuCommands(scheduleManager: scheduleManager, appearanceSettings: appearanceSettings)
        }

        Settings {
            SettingsView()
                .environmentObject(shortcutSettings)
                .environmentObject(scheduleManager)
                .environmentObject(tabManager)
                .environmentObject(appearanceSettings)
                .environment(\.locale, appearanceSettings.locale)
        }
    }
}

struct TerminalMenuCommands: Commands {
    let tabManager: TabManager
    @ObservedObject var appearanceSettings: AppearanceSettings

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(appearanceSettings.localized("New Tab")) {
                tabManager.addTab()
            }
            .keyboardShortcut("t", modifiers: .command)

            Button(appearanceSettings.localized("Close Tab")) {
                if let id = tabManager.selectedTabID {
                    tabManager.closeTab(id: id)
                }
            }
            .keyboardShortcut("w", modifiers: .command)

            Divider()

            Button(appearanceSettings.localized("Next Tab")) {
                tabManager.selectNextTab()
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])

            Button(appearanceSettings.localized("Previous Tab")) {
                tabManager.selectPreviousTab()
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])
        }
    }
}
