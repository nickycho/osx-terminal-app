import SwiftUI

struct ScheduleMenuCommands: Commands {
    @ObservedObject var scheduleManager: ScheduleManager

    var body: some Commands {
        CommandMenu("排程") {
            Button("管理排程...") {
                scheduleManager.openSettingsAction?()
            }

            Divider()

            let enabled = scheduleManager.items.filter(\.isEnabled)
            if enabled.isEmpty {
                Text("尚無啟用的排程").foregroundColor(.secondary)
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
