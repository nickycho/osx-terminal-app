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
        case .default: return "Default"
        case .red:     return "Red"
        case .orange:  return "Orange"
        case .yellow:  return "Yellow"
        case .green:   return "Green"
        case .blue:    return "Blue"
        case .purple:  return "Purple"
        case .pink:    return "Pink"
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
