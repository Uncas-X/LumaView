import Foundation

/// App-owned language choice; "system" resolves the first supported macOS preference.
/// Source-language keys stay readable in code. Missing translations fall back to English.
enum L10n {
    struct Language: Equatable {
        let code: String
        let nativeName: String
    }
    static let languages: [Language] = [
        .init(code: "zh-Hans", nativeName: "简体中文"), .init(code: "zh-Hant", nativeName: "繁體中文"),
        .init(code: "en", nativeName: "English"), .init(code: "ja", nativeName: "日本語"),
        .init(code: "ko", nativeName: "한국어"), .init(code: "fr", nativeName: "Français"),
        .init(code: "de", nativeName: "Deutsch"), .init(code: "es", nativeName: "Español"),
        .init(code: "it", nativeName: "Italiano"), .init(code: "pt-BR", nativeName: "Português"),
        .init(code: "ru", nativeName: "Русский"), .init(code: "ar", nativeName: "العربية"),
        .init(code: "hi", nativeName: "हिन्दी"), .init(code: "tr", nativeName: "Türkçe"),
        .init(code: "nl", nativeName: "Nederlands"), .init(code: "pl", nativeName: "Polski")
    ]
    static let languageDidChange = Notification.Name("LumaViewLanguageDidChange")
    static let preferenceKey = "LumaViewLanguage"
    private static var defaults = UserDefaults.standard
    private static var overrideLanguage: String?
    private static var catalog: [String: [String: String]] = loadCatalog()

    static var selectedLanguageCode: String {
        let saved = overrideLanguage ?? defaults.string(forKey: preferenceKey) ?? "system"
        return saved == "system" || languages.contains(where: { $0.code == saved }) ? saved : "system"
    }
    static var effectiveLanguageCode: String {
        selectedLanguageCode == "system" ? resolveLanguage(Locale.preferredLanguages) : selectedLanguageCode
    }
    static var locale: Locale { Locale(identifier: effectiveLanguageCode) }
    static var isRightToLeft: Bool { effectiveLanguageCode == "ar" }

    static func resolveLanguage(_ preferred: [String]) -> String {
        for language in preferred {
            if let supported = supportedLanguage(language) { return supported }
        }
        return "en"
    }
    static func supportedLanguage(_ identifier: String) -> String? {
        let parts = identifier.replacingOccurrences(of: "_", with: "-").lowercased().split(separator: "-").map(String.init)
        guard let base = parts.first else { return nil }
        if base == "zh" {
            if parts.contains("hant") { return "zh-Hant" }
            if parts.contains("hans") { return "zh-Hans" }
            if parts.contains("tw") || parts.contains("hk") || parts.contains("mo") { return "zh-Hant" }
            return "zh-Hans"
        }
        if base == "pt" { return "pt-BR" }
        return languages.first { $0.code.lowercased() == base }?.code
    }
    static func setLanguage(_ code: String) {
        guard code == "system" || languages.contains(where: { $0.code == code }) else { return }
        let old = selectedLanguageCode
        overrideLanguage = nil
        defaults.set(code, forKey: preferenceKey)
        if old != code { NotificationCenter.default.post(name: languageDidChange, object: nil) }
    }
    static func tr(_ key: String) -> String { translation(key, language: effectiveLanguageCode) }
    static func translation(_ key: String, language code: String) -> String {
        if code == "zh-Hans" { return key }
        return catalog[code]?[key] ?? catalog["en"]?[key] ?? key
    }
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: locale, arguments: arguments)
    }
    /// Used by command-line regression tests without changing the user's preference.
    static func useLanguageForTesting(_ code: String?) { overrideLanguage = code }
    static var catalogLanguages: Set<String> { Set(catalog.keys) }
    static var catalogKeys: Set<String> { Set(catalog["en"]?.keys.map { $0 } ?? []) }
    static func explicitTranslations(for code: String) -> [String: String] { catalog[code] ?? [:] }

    private static func loadCatalog() -> [String: [String: String]] {
        var candidates: [URL] = []
        if let path = ProcessInfo.processInfo.environment["LUMAVIEW_LOCALIZATIONS"] {
            candidates.append(URL(fileURLWithPath: path))
        }
        if let root = Bundle.main.resourceURL { candidates.append(root.appendingPathComponent("Localizations/catalog.json")) }
        // CLI development/test executables lack a resource bundle. Resolve relative
        // to this source path; release bundles always use their own resource above.
        candidates.append(URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/Localizations/catalog.json"))
        for url in candidates {
            if let data = try? Data(contentsOf: url),
               let result = try? JSONDecoder().decode([String: [String: String]].self, from: data) { return result }
        }
        return [:]
    }
}
