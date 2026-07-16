import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            AppearanceSettingsView()
                .tabItem {
                    Label("外觀", systemImage: "paintbrush")
                }

            ShortcutSettingsView()
                .tabItem {
                    Label("快捷鍵", systemImage: "keyboard")
                }

            ScheduleListView()
                .tabItem {
                    Label("排程", systemImage: "clock")
                }
        }
        .frame(width: 480, height: 440)
    }
}
