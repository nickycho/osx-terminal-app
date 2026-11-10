import SwiftUI

struct ShortcutSettingsView: View {
    @EnvironmentObject var shortcutSettings: ShortcutSettings
    @State private var recordingAction: ShortcutAction?

    var body: some View {
        Form {
            Section("Keyboard Shortcuts") {
                ForEach(ShortcutAction.allCases, id: \.self) { action in
                    HStack {
                        Text(LocalizedStringKey(action.displayName))
                            .frame(minWidth: 100, alignment: .leading)

                        Spacer()

                        ShortcutRecorderView(
                            shortcut: shortcutSettings.shortcut(for: action),
                            isRecording: recordingAction == action,
                            onStartRecording: { recordingAction = action },
                            onFinishRecording: { newShortcut in
                                shortcutSettings.setShortcut(newShortcut, for: action)
                                recordingAction = nil
                            },
                            onCancelRecording: {
                                recordingAction = nil
                            }
                        )

                        Button("Reset") {
                            shortcutSettings.resetToDefault(for: action)
                            if recordingAction == action { recordingAction = nil }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        .font(.caption)
                        .frame(width: 30)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
