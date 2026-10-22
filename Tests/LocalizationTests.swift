import Foundation

@main struct LocalizationTests {
    static var checks = 0
    static var failures: [String] = []
    static func expect(_ condition: @autoclosure () -> Bool, _ name: String) {
        checks += 1
        if !condition() { failures.append(name) }
    }
    static func tokens(_ string: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: "%[0-9.$+\\-]*[0-9]*[dif@]")
        return regex.matches(in: string, range: NSRange(string.startIndex..., in: string)).map { (string as NSString).substring(with: $0.range) }.sorted()
    }
    static func main() throws {
        let resource = URL(fileURLWithPath: CommandLine.arguments[1])
        let catalog = try JSONDecoder().decode([String: [String: String]].self, from: Data(contentsOf: resource.appendingPathComponent("catalog.json")))
        let core = try JSONDecoder().decode([String].self, from: Data(contentsOf: resource.appendingPathComponent("core-keys.json")))
        expect(L10n.languages.count == 16, "16 named languages")
        expect(Set(L10n.languages.map(\.code)) == Set(catalog.keys), "every selectable language has a catalog")
        expect(L10n.resolveLanguage(["zh-CN"]) == "zh-Hans", "mainland Chinese")
        expect(L10n.resolveLanguage(["zh-SG"]) == "zh-Hans", "Singapore Chinese")
        expect(L10n.resolveLanguage(["zh_TW"]) == "zh-Hant", "Taiwan Chinese")
        expect(L10n.resolveLanguage(["zh-HK"]) == "zh-Hant", "Hong Kong Chinese")
        expect(L10n.resolveLanguage(["zh-MO"]) == "zh-Hant", "Macao Chinese")
        expect(L10n.resolveLanguage(["zh-Hant-US"]) == "zh-Hant", "explicit traditional script")
        expect(L10n.resolveLanguage(["zh-Hans-TW"]) == "zh-Hans", "explicit simplified script overrides Taiwan region")
        expect(L10n.resolveLanguage(["zh-Hant-CN"]) == "zh-Hant", "explicit traditional script overrides mainland region")
        expect(L10n.resolveLanguage(["pt-PT"]) == "pt-BR", "Portuguese falls back to shipped Portuguese")
        expect(L10n.resolveLanguage(["en-GB"]) == "en", "English region")
        expect(L10n.resolveLanguage(["de_CH"]) == "de", "German underscore region")
        expect(L10n.resolveLanguage(["sv-SE", "ja-JP", "en-US"]) == "ja", "first supported system language")
        expect(L10n.resolveLanguage(["sv-SE", "fi-FI"]) == "en", "unsupported languages fall back to English")
        expect(L10n.resolveLanguage([]) == "en", "empty system preference falls back to English")
        expect(L10n.supportedLanguage("jargon") == nil, "do not match partial language names")
        let english = catalog["en"]!
        for language in L10n.languages {
            let table = catalog[language.code]!
            expect(core.allSatisfy { table[$0] != nil }, "core coverage \(language.code)")
            let mismatch = table.filter { key, value in tokens(key) != tokens(value) }
            expect(mismatch.isEmpty, "format placeholders \(language.code): \(mismatch.keys.sorted())")
            let blank = table.filter { !$0.key.isEmpty && $0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            expect(blank.isEmpty, "nonblank translations \(language.code)")
            expect(table.keys.allSatisfy { english[$0] != nil }, "known source keys \(language.code)")
            if !language.code.hasPrefix("zh"), language.code != "ja" {
                let han = try! NSRegularExpression(pattern: "[\\p{Han}]")
                expect(table.values.allSatisfy { han.firstMatch(in: $0, range: NSRange($0.startIndex..., in: $0)) == nil }, "no accidental Chinese \(language.code)")
            }
            L10n.useLanguageForTesting(language.code)
            expect(L10n.effectiveLanguageCode == language.code, "explicit language \(language.code)")
            expect(L10n.format("第 %d / %d 页", 3, 12).contains("3"), "page format \(language.code)")
            expect(L10n.format("无法打开文档：%@", "example.pdf").contains("example.pdf"), "file placeholder \(language.code)")
            expect(L10n.format("已选 %d / %d 种格式", 4, 72).contains("72"), "selection counts \(language.code)")
        }
        L10n.useLanguageForTesting("en")
        expect(LocalizationMetadata.value("4000 × 3000 像素", for: "尺寸") == "4,000 × 3,000 Pixels", "dimensions translated with locale number formatting")
        expect(LocalizationMetadata.value("12.5 秒", for: "时长") == "12.5 Seconds", "media duration parsed and localized")
        expect(LocalizationMetadata.value("1/125 秒", for: "快门") == "1/125 seconds", "fractional shutter preserved")
        expect(LocalizationMetadata.value("第 2 页，共 12 页", for: "页面") == "Page 2 / 12", "page metadata localized")
        expect(LocalizationMetadata.value("WAV 音频", for: "类型") == "WAV Audio", "media type suffix localized")
        expect(LocalizationMetadata.value("4096 × 2048 像素（矢量渲染）", for: "预览").contains("Vector Rendering"), "vector preview metadata localized")
        expect(LocalizationMetadata.value("8192 × 4096 像素；缩放按原尺寸计算，预览细节有限", for: "大图预览").contains("Preview Detail Is Limited"), "large preview metadata localized")
        expect(LocalizationMetadata.value("4000 × 3000 像素", for: "文件名") == "4000 × 3000 像素", "filename never translated")
        expect(LocalizationMetadata.value("/照片/视频", for: "位置") == "/照片/视频", "path never translated")
        expect(LocalizationMetadata.value("相机自定义名称", for: "相机") == "相机自定义名称", "embedded camera text never translated")
        expect(L10n.format("正在准备兼容播放… %d%%", 42).hasSuffix("42%"), "escaped percentage formats correctly")
        L10n.useLanguageForTesting("ja")
        expect(L10n.tr("无法读取这个媒体文件。") == english["无法读取这个媒体文件。"], "untranslated diagnostics fall back to English")
        expect(L10n.tr("JPEG XL") == "JPEG XL", "technical format names pass through")
        L10n.useLanguageForTesting("ar")
        expect(L10n.isRightToLeft, "Arabic text direction")
        L10n.useLanguageForTesting("zh-Hans")
        expect(L10n.tr("文件") == "文件", "source-language identity")
        expect(!L10n.isRightToLeft, "Chinese text direction")
        L10n.useLanguageForTesting(nil)
        if failures.isEmpty { print("PASS: \(checks) localization checks (16 languages, \(core.count) required core keys, \(english.count) total source keys)") }
        else { failures.forEach { print("FAIL: \($0)") }; exit(1) }
    }
}
