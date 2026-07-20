import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject private var settings = AppearanceSettings.shared
    @EnvironmentObject var tabManager: TabManager

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("字體大小")
                    Spacer()
                    Stepper(value: $settings.fontSize, in: 8...36, step: 1) {
                        Text("\(Int(settings.fontSize)) pt")
                            .monospacedDigit()
                            .frame(width: 48, alignment: .trailing)
                    }
                }
            }
            Section("終端機") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scrollback Buffer")
                        Text("套用於新分頁")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Stepper(
                        value: $settings.scrollbackLines,
                        in: AppearanceSettings.scrollbackRange,
                        step: 1_000
                    ) {
                        Text("\\(settings.scrollbackLines.formatted()) 行")
                            .monospacedDigit()
                            .frame(width: 88, alignment: .trailing)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: settings.fontSize) {
            for vm in tabManager.viewModels.values {
                vm.session.updateFont(size: settings.fontSize)
            }
        }
    }
}
