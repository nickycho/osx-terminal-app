import Foundation

enum ScheduleType: String, Codable, CaseIterable {
    case oneTime  = "一次性"
    case periodic = "週期性"

    var localizationKey: String {
        switch self {
        case .oneTime: return "One-time"
        case .periodic: return "Periodic"
        }
    }
}

struct ScheduledInputItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var command: String
    var scheduleType: ScheduleType = .periodic
    var cronExpression: String = "* * * * *"
    var executeAt: Date = Date().nextMinute
    var targetTabID: UUID?
    var appendNewline: Bool = true
    var isEnabled: Bool = true
    var lastExecutedAt: Date?
}

private extension Date {
    var nextMinute: Date {
        let cal = Calendar.current
        guard let next = cal.date(byAdding: .minute, value: 1, to: self) else { return self }
        return cal.date(bySetting: .second, value: 0, of: next) ?? next
    }
}
