# LumaView interface languages

<!-- full-translation:start -->
[简体中文](../../docs/i18n/zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../docs/i18n/zh-Hant/Resources/Localizations/README.md) · [English](../../docs/i18n/en/Resources/Localizations/README.md) · [日本語](../../docs/i18n/ja/Resources/Localizations/README.md) · [한국어](../../docs/i18n/ko/Resources/Localizations/README.md) · [Français](../../docs/i18n/fr/Resources/Localizations/README.md) · [Deutsch](../../docs/i18n/de/Resources/Localizations/README.md) · [Español](../../docs/i18n/es/Resources/Localizations/README.md) · [Italiano](../../docs/i18n/it/Resources/Localizations/README.md) · [Português (Brasil)](../../docs/i18n/pt-BR/Resources/Localizations/README.md) · [Русский](../../docs/i18n/ru/Resources/Localizations/README.md) · [العربية](../../docs/i18n/ar/Resources/Localizations/README.md) · [हिन्दी](../../docs/i18n/hi/Resources/Localizations/README.md) · [Türkçe](../../docs/i18n/tr/Resources/Localizations/README.md) · [Nederlands](../../docs/i18n/nl/Resources/Localizations/README.md) · [Polski](../../docs/i18n/pl/Resources/Localizations/README.md)
<!-- full-translation:end -->


The app starts with **Follow System**. It chooses the first supported language in macOS’s preferred language list, then English if none is supported. A language selected in **LumaView → Language…** takes effect immediately and is remembered for this app only.

Supported choices: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, Portuguese, Russian, Arabic, Hindi, Turkish, Dutch and Polish. Portuguese variants currently use the Brazilian Portuguese catalog. The native names in the picker are intentional, so a user can recover from an unfamiliar interface language.

`catalog.json` maps readable Simplified Chinese source keys to localized strings. `core-keys.json` defines the common controls, menus, settings, document navigation, metadata labels, and keyboard-help strings required in every catalog. Low-frequency diagnostic messages use the English fallback when a language does not have its own entry. Names of files, directories, codecs, formats, and embedded camera metadata remain unchanged. The OS supplies native system dialog text in its own language.

Use `L10n.tr("source key")` for static text. For dynamic text, use `L10n.format("第 %d / %d 页", current, total)`, rather than interpolating a Chinese string before translation. Keep placeholder types and counts consistent across translations. Observe `L10n.languageDidChange` to refresh existing interfaces and redraw rendered text. The tests use `useLanguageForTesting` to avoid modifying the user's persisted language.

Run `Tests/run-localization-tests.sh` for locale resolution, complete core coverage, format-placeholder consistency, fallback behavior, and Arabic text direction. Translation text has not undergone professional linguistic review.
