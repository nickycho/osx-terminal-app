import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            ShortcutSettingsView()
                .tabItem {
                    Label("Keyboard Shortcuts", systemImage: "keyboard")
                }

            ScheduleListView()
                .tabItem {
                    Label("Schedules", systemImage: "clock")
                }
        }
        .frame(width: 480, height: 480)
    }
}
