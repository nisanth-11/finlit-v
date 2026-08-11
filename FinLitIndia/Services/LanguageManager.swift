import Foundation
import SwiftUI

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var languageCode: String {
        didSet { UserDefaults.standard.set(languageCode, forKey: "language") }
    }

    private init() {
        languageCode = UserDefaults.standard.string(forKey: "language") ?? "en"
    }

    func t(_ key: String) -> String {
        TranslationTable.staticTranslations[languageCode]?[key]
            ?? TranslationTable.staticTranslations["en"]?[key]
            ?? key
    }
}

// Usage in views: `@ObservedObject private var lang = LanguageManager.shared`
// then `lang.t("home")` — holding it as @ObservedObject is what makes the
// view re-render when the language changes; a free-function lookup would not.
