import Foundation

final class AppearanceSettings: ObservableObject {
    static let shared = AppearanceSettings()

    private let fontSizeKey = "appearance.fontSize"

    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: fontSizeKey) }
    }

    private init() {
        let stored = UserDefaults.standard.double(forKey: "appearance.fontSize")
        fontSize = stored > 0 ? stored : 13
    }
}
