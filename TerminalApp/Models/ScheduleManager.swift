import Foundation
import UserNotifications

final class ScheduleManager: NSObject, ObservableObject {
    static let shared = ScheduleManager()

    @Published var items: [ScheduledInputItem] = []
    @Published var activeToast: (title: String, body: String)? = nil
    weak var tabManager: TabManager?
    var openSettingsAction: (() -> Void)?

    private var timer: Timer?
    private let udKey = "schedule.items"

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        load()
    }

    // MARK: - CRUD

    func saveItem(_ item: ScheduledInputItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
        } else {
            items.append(item)
        }
        persist()
    }

    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    func toggleEnabled(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isEnabled.toggle()
        persist()
    }

    // MARK: - Timer

    func startTimer() {
        stopTimer()
        checkAndExecute()
        let t = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkAndExecute()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Execute

    func executeItem(_ item: ScheduledInputItem) {
        guard let tabManager else { return }
        let targetTab: TerminalTab?
        if let targetID = item.targetTabID {
            targetTab = tabManager.tabs.first { $0.id == targetID }
        } else {
            targetTab = tabManager.selectedTab
        }
        guard let tab = targetTab,
              let vm = tabManager.viewModels[tab.id] else { return }
        let text = item.command + (item.appendNewline ? "\r" : "")
        vm.session.send(text: text)

        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].lastExecutedAt = Date()
            persist()
        }
        sendNotification(for: item)
    }

    private func sendNotification(for item: ScheduledInputItem) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = item.name
        content.body = item.command
        content.sound = nil
        // 用 timeInterval trigger 而非 nil，可繞過 macOS 對前景 app 的 banner 抑制
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "schedule.\(item.id).\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }
}

extension ScheduleManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handler([.banner])
    }

    // MARK: - Cron

    private func checkAndExecute() {
        let now = Date()
        let cal = Calendar.current
        let minute  = cal.component(.minute,  from: now)
        let hour    = cal.component(.hour,    from: now)
        let day     = cal.component(.day,     from: now)
        let month   = cal.component(.month,   from: now)
        let weekday = cal.component(.weekday, from: now) - 1

        for item in items where item.isEnabled {
            // 防止同一分鐘重複執行
            if let last = item.lastExecutedAt {
                let sameMin = cal.component(.minute, from: last) == minute
                    && cal.component(.hour, from: last) == hour
                    && cal.isDate(last, inSameDayAs: now)
                if sameMin { continue }
            }

            switch item.scheduleType {
            case .periodic:
                guard cronMatches(item.cronExpression, minute: minute, hour: hour,
                                  day: day, month: month, weekday: weekday) else { continue }
                executeItem(item)

            case .oneTime:
                guard item.executeAt <= now else { continue }
                executeItem(item)
                // 執行後停用
                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                    items[idx].isEnabled = false
                    persist()
                }
            }
        }
    }

    func nextExecution(for item: ScheduledInputItem) -> Date? {
        switch item.scheduleType {
        case .oneTime:
            return item.isEnabled ? item.executeAt : nil
        case .periodic:
            return nextExecutionForCron(item.cronExpression)
        }
    }

    func nextExecutionForCron(_ expression: String) -> Date? {
        var cal = Calendar.current
        guard let start = cal.date(byAdding: .minute, value: 1, to: Date()) else { return nil }
        var comps = cal.dateComponents([.minute, .hour, .day, .month, .weekday, .year], from: start)
        comps.second = 0

        guard let base = cal.date(from: comps) else { return nil }
        let limit = cal.date(byAdding: .year, value: 1, to: base) ?? base

        var candidate = base
        while candidate <= limit {
            let m  = cal.component(.minute,  from: candidate)
            let h  = cal.component(.hour,    from: candidate)
            let d  = cal.component(.day,     from: candidate)
            let mo = cal.component(.month,   from: candidate)
            let wd = cal.component(.weekday, from: candidate) - 1
            if cronMatches(expression, minute: m, hour: h, day: d, month: mo, weekday: wd) {
                return candidate
            }
            candidate = cal.date(byAdding: .minute, value: 1, to: candidate) ?? limit
        }
        return nil
    }

    func validateCron(_ expression: String) -> Bool {
        let fields = expression.split(separator: " ", omittingEmptySubsequences: true)
        guard fields.count == 5 else { return false }
        let ranges = [0...59, 0...23, 1...31, 1...12, 0...6]
        for (field, range) in zip(fields, ranges) {
            guard (try? parseField(String(field), range: range)) != nil else { return false }
        }
        return true
    }

    // MARK: - Cron parsing

    private func cronMatches(_ expr: String, minute: Int, hour: Int,
                              day: Int, month: Int, weekday: Int) -> Bool {
        let fields = expr.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard fields.count == 5 else { return false }
        let ranges = [0...59, 0...23, 1...31, 1...12, 0...6]
        let values = [minute, hour, day, month, weekday]
        for (i, field) in fields.enumerated() {
            guard let set = try? parseField(field, range: ranges[i]) else { return false }
            if !set.contains(values[i]) { return false }
        }
        return true
    }

    private func parseField(_ field: String, range: ClosedRange<Int>) throws -> Set<Int> {
        if field == "*" { return Set(range) }

        if field.contains(",") {
            var result = Set<Int>()
            for part in field.split(separator: ",") {
                result.formUnion(try parseField(String(part), range: range))
            }
            return result
        }

        if field.contains("/") {
            let parts = field.split(separator: "/")
            guard parts.count == 2, let step = Int(parts[1]), step > 0 else {
                throw CronError.invalid
            }
            let base: Set<Int> = parts[0] == "*" ? Set(range) : try parseField(String(parts[0]), range: range)
            let sorted = base.sorted()
            guard let first = sorted.first else { return [] }
            return Set(stride(from: first, through: sorted.last ?? first, by: step))
        }

        if field.contains("-") {
            let parts = field.split(separator: "-")
            guard parts.count == 2,
                  let lo = Int(parts[0]), let hi = Int(parts[1]),
                  range.contains(lo), range.contains(hi), lo <= hi else {
                throw CronError.invalid
            }
            return Set(lo...hi)
        }

        guard let v = Int(field), range.contains(v) else { throw CronError.invalid }
        return [v]
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([ScheduledInputItem].self, from: data)
        else { return }
        items = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: udKey)
        }
    }

    enum CronError: Error { case invalid }
}
