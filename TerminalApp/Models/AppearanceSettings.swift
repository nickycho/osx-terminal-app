import Foundation

final class AppearanceSettings: ObservableObject {
    static let shared = AppearanceSettings()

    static let defaultScrollbackLines = 10_000
    static let scrollbackRange = 1_000...100_000

    private let defaults: UserDefaults
    private let fontSizeKey = "appearance.fontSize"
    private let scrollbackLinesKey = "appearance.scrollbackLines"

    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: fontSizeKey) }
    }

    @Published var scrollbackLines: Int {
        didSet {
            let normalized = Self.normalize(scrollbackLines)
            if scrollbackLines != normalized {
                scrollbackLines = normalized
            } else {
                defaults.set(scrollbackLines, forKey: scrollbackLinesKey)
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedFontSize = defaults.double(forKey: fontSizeKey)
        fontSize = storedFontSize > 0 ? storedFontSize : 13

        if let storedScrollback = defaults.object(forKey: scrollbackLinesKey) as? Int {
            scrollbackLines = Self.normalize(storedScrollback)
        } else {
            scrollbackLines = Self.defaultScrollbackLines
        }
    }

    private static func normalize(_ value: Int) -> Int {
        min(max(value, scrollbackRange.lowerBound), scrollbackRange.upperBound)
    }
}
