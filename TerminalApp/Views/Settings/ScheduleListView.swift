import SwiftUI

struct ScheduleListView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    @EnvironmentObject var tabManager: TabManager
    @State private var editingItem: ScheduledInputItem?
    @State private var isAdding = false

    var body: some View {
        VStack(spacing: 0) {
            if scheduleManager.items.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(scheduleManager.items) { item in
                        ScheduleRowView(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture { editingItem = item }
                            .contextMenu {
                                Button("編輯") { editingItem = item }
                                Button("刪除", role: .destructive) {
                                    scheduleManager.deleteItem(id: item.id)
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            HStack {
                Button(action: { isAdding = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .padding(8)
                Spacer()
            }
        }
        .sheet(isPresented: $isAdding) {
            ScheduleEditView(item: ScheduledInputItem(name: "", command: ""))
                .environmentObject(scheduleManager)
                .environmentObject(tabManager)
        }
        .sheet(item: $editingItem) { item in
            ScheduleEditView(item: item)
                .environmentObject(scheduleManager)
                .environmentObject(tabManager)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("尚無排程")
                .foregroundColor(.secondary)
            Button("新增排程") { isAdding = true }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ScheduleRowView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    let item: ScheduledInputItem

    var nextExecText: String {
        guard item.isEnabled else { return "已停用" }
        guard let next = scheduleManager.nextExecution(for: item) else { return "─" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return "下次：" + f.localizedString(for: next, relativeTo: Date())
    }

    var scheduleLabel: String {
        switch item.scheduleType {
        case .oneTime:
            let f = DateFormatter()
            f.dateStyle = .short
            f.timeStyle = .short
            return "一次性  \(f.string(from: item.executeAt))"
        case .periodic:
            return item.cronExpression
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name).font(.system(size: 13, weight: .medium))
                    Text(item.scheduleType.rawValue)
                        .font(.system(size: 10))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(item.scheduleType == .oneTime ? Color.orange.opacity(0.2) : Color.blue.opacity(0.15))
                        .foregroundColor(item.scheduleType == .oneTime ? .orange : .blue)
                        .clipShape(Capsule())
                }
                HStack(spacing: 8) {
                    Text(scheduleLabel)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(nextExecText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in scheduleManager.toggleEnabled(id: item.id) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
