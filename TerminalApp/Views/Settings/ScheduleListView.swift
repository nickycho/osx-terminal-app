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
                                Button("Edit") { editingItem = item }
                                Button("Delete", role: .destructive) {
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
            Text("No schedules yet")
                .foregroundColor(.secondary)
            Button("Add Schedule") { isAdding = true }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ScheduleRowView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    @Environment(\.locale) private var locale
    let item: ScheduledInputItem

    var nextExecText: String {
        guard item.isEnabled else { return String(localized: "Disabled", locale: locale) }
        guard let next = scheduleManager.nextExecution(for: item) else { return "─" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = locale
        let prefix = String(localized: "Next:", locale: locale)
        return "\(prefix) \(formatter.localizedString(for: next, relativeTo: Date()))"
    }

    var scheduleLabel: String {
        switch item.scheduleType {
        case .oneTime:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            formatter.locale = locale
            let typeName = String(localized: "One-time", locale: locale)
            return "\(typeName)  \(formatter.string(from: item.executeAt))"
        case .periodic:
            return item.cronExpression
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name).font(.system(size: 13, weight: .medium))
                    Text(LocalizedStringKey(item.scheduleType.localizationKey))
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
