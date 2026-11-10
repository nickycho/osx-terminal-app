import SwiftUI

struct ScheduleMenuCommands: Commands {
    @ObservedObject var scheduleManager: ScheduleManager
    @ObservedObject var appearanceSettings: AppearanceSettings

    var body: some Commands {
        CommandMenu(appearanceSettings.localized("Schedules")) {
            Button(appearanceSettings.localized("Manage Schedules...")) {
                scheduleManager.openSettingsAction?()
            }

            Divider()

            let enabled = scheduleManager.items.filter(\.isEnabled)
            if enabled.isEmpty {
                Text(appearanceSettings.localized("No active schedules")).foregroundColor(.secondary)
            } else {
                ForEach(enabled) { item in
                    Button(item.name) {
                        scheduleManager.executeItem(item)
                    }
                }
            }
        }
    }
}
