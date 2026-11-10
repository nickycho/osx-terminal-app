import SwiftUI

struct ScheduleEditView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    @EnvironmentObject var tabManager: TabManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State var item: ScheduledInputItem
    @State private var cronError = false

    private var isNew: Bool {
        !scheduleManager.items.contains(where: { $0.id == item.id })
    }

    private var nextExecText: String {
        guard !cronError else { return "─" }
        guard let next = scheduleManager.nextExecution(for: item) else { return "─" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = locale
        return formatter.string(from: next)
    }

    private var canSave: Bool {
        !item.name.isEmpty && !item.command.isEmpty
            && (item.scheduleType == .oneTime || !cronError)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $item.name)
                    TextField("Command", text: $item.command)
                        .font(.system(.body, design: .monospaced))
                }

                Section("Schedule Type") {
                    Picker("Type", selection: $item.scheduleType) {
                        ForEach(ScheduleType.allCases, id: \.self) { type in
                            Text(LocalizedStringKey(type.localizationKey)).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    if item.scheduleType == .oneTime {
                        DatePicker("Execution Time", selection: $item.executeAt, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    } else {
                        HStack {
                            TextField("Cron expression", text: $item.cronExpression)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: item.cronExpression) { value in
                                    cronError = !scheduleManager.validateCron(value)
                                }
                            if cronError {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        Text("Format: minute hour day month weekday (e.g. 0 9 * * 1-5)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Next Run").foregroundColor(.secondary)
                        Spacer()
                        Text(nextExecText).foregroundColor(.secondary)
                    }
                }

                Section("Execution Options") {
                    Picker("Target Tab", selection: $item.targetTabID) {
                        Text("Current Tab").tag(nil as UUID?)
                        Divider()
                        ForEach(tabManager.tabs) { tab in
                            Text(tab.displayTitle).tag(tab.id as UUID?)
                        }
                    }
                    Toggle("Press Enter automatically after running", isOn: $item.appendNewline)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                if !isNew {
                    Button("Delete", role: .destructive) {
                        scheduleManager.deleteItem(id: item.id)
                        dismiss()
                    }
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    scheduleManager.saveItem(item)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSave)
            }
            .padding(12)
        }
        .frame(width: 420, height: 460)
        .onAppear {
            cronError = !scheduleManager.validateCron(item.cronExpression)
        }
    }
}
