import Foundation

final class AppearanceSettings: ObservableObject {
    static let shared = AppearanceSettings()

    static let defaultScrollbackLines = 10_000
    static let scrollbackRange = 1_000...100_000

    private let defaults: UserDefaults
    private let fontSizeKey = "appearance.fontSize"
    private let scrollbackLinesKey = "appearance.scrollbackLines"
    private let languageKey = "appearance.language"

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

    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: languageKey) }
    }

    var locale: Locale { language.locale }

    func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), locale: locale)
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

        if let rawLanguage = defaults.string(forKey: languageKey),
           let storedLanguage = AppLanguage(rawValue: rawLanguage) {
            language = storedLanguage
        } else {
            language = .system
        }
    }

    private static func normalize(_ value: Int) -> Int {
        min(max(value, scrollbackRange.lowerBound), scrollbackRange.upperBound)
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"

    var id: String { rawValue }

    var resolved: AppLanguage {
        guard self == .system else { return self }
        return Self.detectSystemLanguage()
    }

    var locale: Locale {
        Locale(identifier: resolved.rawValue)
    }

    var pickerLocalizationKey: String {
        switch self {
        case .system: return "Follow System"
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    private static func detectSystemLanguage() -> AppLanguage {
        for preferredLanguage in Locale.preferredLanguages {
            switch preferredLanguage.lowercased().prefix(2) {
            case "zh": return .traditionalChinese
            case "ja": return .japanese
            case "ko": return .korean
            case "en": return .english
            default: continue
            }
        }
        return .english
    }
}
