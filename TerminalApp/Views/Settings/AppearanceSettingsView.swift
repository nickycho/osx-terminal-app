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
        }
        .formStyle(.grouped)
        .onChange(of: settings.fontSize) {
            for vm in tabManager.viewModels.values {
                vm.session.updateFont(size: settings.fontSize)
            }
        }
    }
}
