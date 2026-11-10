import Foundation
import AppKit

enum ShortcutAction: String, CaseIterable {
    case newTab         = "shortcut.newTab"
    case closeTab       = "shortcut.closeTab"
    case nextTab        = "shortcut.nextTab"
    case previousTab    = "shortcut.prevTab"
    case openSettings   = "shortcut.openSettings"
    case clearBuffer    = "shortcut.clearBuffer"

    var displayName: String {
        switch self {
        case .newTab:       return "New Tab"
        case .closeTab:     return "Close Tab"
        case .nextTab:      return "Next Tab"
        case .previousTab:  return "Previous Tab"
        case .openSettings: return "Open Settings"
        case .clearBuffer:  return "Clear Screen"
        }
    }

    var defaultShortcut: KeyboardShortcutData {
        switch self {
        case .newTab:       return KeyboardShortcutData(key: "t", modifiers: [.command])
        case .closeTab:     return KeyboardShortcutData(key: "w", modifiers: [.command])
        case .nextTab:      return KeyboardShortcutData(key: "]", modifiers: [.command, .shift])
        case .previousTab:  return KeyboardShortcutData(key: "[", modifiers: [.command, .shift])
        case .openSettings: return KeyboardShortcutData(key: ",", modifiers: [.command])
        case .clearBuffer:  return KeyboardShortcutData(key: "k", modifiers: [.command])
        }
    }
}

struct KeyboardShortcutData: Codable, Equatable {
    var key: String
    var modifiers: NSEvent.ModifierFlags

    enum CodingKeys: String, CodingKey { case key, modifiersRaw }

    init(key: String, modifiers: NSEvent.ModifierFlags) {
        self.key = key
        self.modifiers = modifiers
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(String.self, forKey: .key)
        let raw = try c.decode(UInt.self, forKey: .modifiersRaw)
        modifiers = NSEvent.ModifierFlags(rawValue: raw)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(key, forKey: .key)
        try c.encode(modifiers.rawValue, forKey: .modifiersRaw)
    }

    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option)  { parts.append("⌥") }
        if modifiers.contains(.shift)   { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(key.uppercased())
        return parts.joined()
    }
}

final class ShortcutSettings: ObservableObject {
    static let shared = ShortcutSettings()

    @Published private(set) var shortcuts: [ShortcutAction: KeyboardShortcutData] = [:]

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() { loadAll() }

    func shortcut(for action: ShortcutAction) -> KeyboardShortcutData {
        shortcuts[action] ?? action.defaultShortcut
    }

    func setShortcut(_ data: KeyboardShortcutData, for action: ShortcutAction) {
        shortcuts[action] = data
        save(data, for: action)
        objectWillChange.send()
    }

    func resetToDefault(for action: ShortcutAction) {
        shortcuts[action] = action.defaultShortcut
        UserDefaults.standard.removeObject(forKey: action.rawValue)
        objectWillChange.send()
    }

    private func loadAll() {
        for action in ShortcutAction.allCases {
            if let data = UserDefaults.standard.data(forKey: action.rawValue),
               let shortcut = try? decoder.decode(KeyboardShortcutData.self, from: data) {
                shortcuts[action] = shortcut
            } else {
                shortcuts[action] = action.defaultShortcut
            }
        }
    }

    private func save(_ data: KeyboardShortcutData, for action: ShortcutAction) {
        if let encoded = try? encoder.encode(data) {
            UserDefaults.standard.set(encoded, forKey: action.rawValue)
        }
    }
}

extension NSEvent.ModifierFlags {
    var swiftUIEventModifiers: SwiftUI.EventModifiers {
        var result: SwiftUI.EventModifiers = []
        if contains(.command) { result.insert(.command) }
        if contains(.option)  { result.insert(.option) }
        if contains(.control) { result.insert(.control) }
        if contains(.shift)   { result.insert(.shift) }
        return result
    }
}

import SwiftUI
