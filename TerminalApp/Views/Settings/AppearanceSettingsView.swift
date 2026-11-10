import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject private var settings = AppearanceSettings.shared
    @EnvironmentObject var tabManager: TabManager

    var body: some View {
        Form {
            Section("Language") {
                Picker("Language", selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(LocalizedStringKey(language.pickerLocalizationKey))
                            .tag(language)
                    }
                }
                .pickerStyle(.menu)

                Text("Unsupported system languages default to English.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Stepper(value: $settings.fontSize, in: 8...36, step: 1) {
                        Text("\(Int(settings.fontSize)) pt")
                            .monospacedDigit()
                            .frame(width: 48, alignment: .trailing)
                    }
                }
            }

            Section("Terminal") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scrollback Buffer")
                        Text("Applies to new tabs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Stepper(
                        value: $settings.scrollbackLines,
                        in: AppearanceSettings.scrollbackRange,
                        step: 1_000
                    ) {
                        HStack(spacing: 4) {
                            Text(settings.scrollbackLines.formatted())
                            Text("Lines")
                        }
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
