import Foundation
import SwiftUI

enum TabColor: String, CaseIterable, Codable {
    case `default`, red, orange, yellow, green, blue, purple, pink

    var color: Color? {
        switch self {
        case .default: return nil
        case .red:     return Color(nsColor: .systemRed)
        case .orange:  return Color(nsColor: .systemOrange)
        case .yellow:  return Color(nsColor: .systemYellow)
        case .green:   return Color(nsColor: .systemGreen)
        case .blue:    return Color(nsColor: .systemBlue)
        case .purple:  return Color(nsColor: .systemPurple)
        case .pink:    return Color(nsColor: .systemPink)
        }
    }

    var label: String {
        switch self {
        case .default: return "預設"
        case .red:     return "紅色"
        case .orange:  return "橘色"
        case .yellow:  return "黃色"
        case .green:   return "綠色"
        case .blue:    return "藍色"
        case .purple:  return "紫色"
        case .pink:    return "粉紅"
        }
    }
}

final class TerminalTab: ObservableObject, Identifiable {
    let id: UUID
    @Published var shellTitle: String = ""
    @Published var customTitle: String?
    @Published var currentDirectory: String?
    @Published var tabColor: TabColor = .default
    @Published var isRunning: Bool = false
    @Published var isDetached: Bool = false
    let workingDirectory: String

    init(id: UUID = UUID(), workingDirectory: String = NSHomeDirectory()) {
        self.id = id
        self.workingDirectory = workingDirectory
        self.currentDirectory = workingDirectory
    }

    var displayTitle: String {
        if let t = customTitle, !t.isEmpty { return t }
        if let dir = currentDirectory {
            let name = (dir as NSString).lastPathComponent
            return name.isEmpty ? "/" : name
        }
        return shellTitle.isEmpty ? "Terminal" : shellTitle
    }
}
