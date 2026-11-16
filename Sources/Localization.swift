import Foundation

enum InterfaceLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans", english = "en", japanese = "ja"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .chinese: return "简体中文"
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }
    static var systemDefault: InterfaceLanguage {
        let first = Locale.preferredLanguages.first ?? "en"
        if first.hasPrefix("zh") { return .chinese }
        if first.hasPrefix("ja") { return .japanese }
        return .english
    }
}

enum Copy {
    private static let translations: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "Translations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([String: [String: String]].self, from: data) else { return [:] }
        return entries
    }()
    static func text(_ source: String, _ language: InterfaceLanguage) -> String {
        if language == .chinese { return source }
        return translations[language.rawValue]?[source] ?? source
    }
}
