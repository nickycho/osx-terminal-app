import SwiftUI
import UniformTypeIdentifiers

struct TabBarView: View {
    @EnvironmentObject var tabManager: TabManager
    @EnvironmentObject var windowManager: TerminalWindowManager
    @State private var draggingTabID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabManager.attachedTabs) { tab in
                        TabItemView(
                            tab: tab,
                            isSelected: tab.id == tabManager.selectedTabID,
                            isDragging: draggingTabID == tab.id,
                            onDragStarted: { draggingTabID = tab.id },
                            onDragEnded: {
                                if draggingTabID == tab.id { draggingTabID = nil }
                            },
                            onDetach: { id in windowManager.detach(tabID: id) }
                        )
                        .onDrop(
                            of: [.plainText],
                            delegate: TabDropDelegate(
                                targetTab: tab,
                                tabManager: tabManager,
                                draggingTabID: $draggingTabID
                            )
                        )
                    }
                }
                .padding(.horizontal, 4)
            }

            Divider()
                .frame(height: 20)

            Button {
                tabManager.addTab()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 6)
        }
        .frame(height: 36)
        .background(.bar)
    }
}

struct TabDropDelegate: DropDelegate {
    let targetTab: TerminalTab
    let tabManager: TabManager
    @Binding var draggingTabID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggingID = draggingTabID,
              draggingID != targetTab.id,
              let from = tabManager.tabs.firstIndex(where: { $0.id == draggingID }),
              let to = tabManager.tabs.firstIndex(where: { $0.id == targetTab.id })
        else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            tabManager.tabs.move(
                fromOffsets: IndexSet(integer: from),
                toOffset: to > from ? to + 1 : to
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingTabID = nil
        return true
    }
}

struct TabItemView: View {
    @ObservedObject var tab: TerminalTab
    let isSelected: Bool
    var isDragging: Bool = false
    var onDragStarted: () -> Void = {}
    var onDragEnded: () -> Void = {}
    var onDetach: (UUID) -> Void = { _ in }

    @EnvironmentObject var tabManager: TabManager
    @Environment(\.locale) private var locale
    @State private var isHovered = false

    var accentColor: Color {
        tab.tabColor.color ?? Color(nsColor: .selectedContentBackgroundColor)
    }

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                TabDragSourceView(
                    tabID: tab.id,
                    onDragStarted: onDragStarted,
                    onDragEnded: onDragEnded,
                    onClick: { tabManager.selectTab(id: tab.id) },
                    onDetach: onDetach
                )
            }
            .frame(width: 16, height: 24)

            Circle()
                .fill(tab.tabColor.color ?? (tab.isRunning ? Color.green : Color.gray))
                .frame(width: 6, height: 6)

            Text(tab.displayTitle)
                .lineLimit(1)
                .font(.system(size: 12))
                .frame(maxWidth: 120, alignment: .leading)

            Button {
                tabManager.closeTab(id: tab.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
            .opacity(isHovered || isSelected ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isSelected
                    ? accentColor.opacity(0.25)
                    : tab.tabColor != .default ? accentColor.opacity(0.12) : Color.clear)
        )
        .opacity(isDragging ? 0.5 : 1.0)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { tabManager.selectTab(id: tab.id) }
        .contextMenu { contextMenuItems }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button("Rename") { promptRename() }

        Divider()

        Menu("Tab Color") {
            ForEach(TabColor.allCases, id: \.self) { c in
                Button {
                    tab.tabColor = c
                } label: {
                    HStack {
                        if let color = c.color {
                            Circle()
                                .fill(color)
                                .frame(width: 10, height: 10)
                        }
                        Text(LocalizedStringKey(c.label))
                        if tab.tabColor == c {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }

        Divider()

        Button("Close Tab", role: .destructive) {
            tabManager.closeTab(id: tab.id)
        }
    }

    private func promptRename() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Rename Tab", locale: locale)
        alert.addButton(withTitle: String(localized: "Confirm", locale: locale))
        alert.addButton(withTitle: String(localized: "Cancel", locale: locale))

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        field.stringValue = tab.customTitle ?? tab.displayTitle
        field.selectText(nil)
        alert.accessoryView = field

        if alert.runModal() == .alertFirstButtonReturn {
            let trimmed = field.stringValue.trimmingCharacters(in: .whitespaces)
            tab.customTitle = trimmed.isEmpty ? nil : trimmed
        }
    }
}
