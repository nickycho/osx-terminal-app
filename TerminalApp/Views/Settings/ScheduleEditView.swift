import SwiftUI

struct ScheduleEditView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    @EnvironmentObject var tabManager: TabManager
    @Environment(\.dismiss) private var dismiss

    @State var item: ScheduledInputItem
    @State private var cronError = false

    private var isNew: Bool {
        !scheduleManager.items.contains(where: { $0.id == item.id })
    }

    private var nextExecText: String {
        guard !cronError else { return "─" }
        guard let next = scheduleManager.nextExecution(for: item) else { return "─" }
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: next)
    }

    private var canSave: Bool {
        !item.name.isEmpty && !item.command.isEmpty
            && (item.scheduleType == .oneTime || !cronError)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("基本資訊") {
                    TextField("名稱", text: $item.name)
                    TextField("命令", text: $item.command)
                        .font(.system(.body, design: .monospaced))
                }

                Section("排程類型") {
                    Picker("類型", selection: $item.scheduleType) {
                        ForEach(ScheduleType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    if item.scheduleType == .oneTime {
                        DatePicker("執行時間", selection: $item.executeAt, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    } else {
                        HStack {
                            TextField("Cron 表達式", text: $item.cronExpression)
                                .font(.system(.body, design: .monospaced))
                                .onChange(of: item.cronExpression) { val in
                                    cronError = !scheduleManager.validateCron(val)
                                }
                            if cronError {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        Text("格式：分 時 日 月 週（例：0 9 * * 1-5）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("下次執行").foregroundColor(.secondary)
                        Spacer()
                        Text(nextExecText).foregroundColor(.secondary)
                    }
                }

                Section("執行選項") {
                    Picker("目標分頁", selection: $item.targetTabID) {
                        Text("當前分頁").tag(nil as UUID?)
                        Divider()
                        ForEach(tabManager.tabs) { tab in
                            Text(tab.displayTitle).tag(tab.id as UUID?)
                        }
                    }
                    Toggle("執行後自動按 Enter", isOn: $item.appendNewline)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                if !isNew {
                    Button("刪除", role: .destructive) {
                        scheduleManager.deleteItem(id: item.id)
                        dismiss()
                    }
                }
                Spacer()
                Button("取消") { dismiss() }
                Button("儲存") {
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
