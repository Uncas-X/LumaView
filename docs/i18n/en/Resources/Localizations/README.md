# LumaView interface languages

<!-- doc-navigation:start -->
[Documentation](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · **English** · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


The app starts with **Follow System**. It chooses the first supported language in macOS’s preferred language list, then English if none is supported. A language selected in **LumaView → Language…** takes effect immediately and is remembered for this app only.

Supported choices: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, Portuguese, Russian, Arabic, Hindi, Turkish, Dutch and Polish. Portuguese variants currently use the Brazilian Portuguese catalog. The native names in the picker are intentional, so a user can recover from an unfamiliar interface language.

`catalog.json` maps readable Simplified Chinese source keys to localized strings. `core-keys.json` defines the common controls, menus, settings, document navigation, metadata labels, and keyboard-help strings required in every catalog. Low-frequency diagnostic messages use the English fallback when a language does not have its own entry. Names of files, directories, codecs, formats, and embedded camera metadata remain unchanged. The OS supplies native system dialog text in its own language.

Use `L10n.tr("source key")` for static text. For dynamic text, use `L10n.format("第 %d / %d 页", current, total)`, rather than interpolating a Chinese string before translation. Keep placeholder types and counts consistent across translations. Observe `L10n.languageDidChange` to refresh existing interfaces and redraw rendered text. The tests use `useLanguageForTesting` to avoid modifying the user's persisted language.

Run `Tests/run-localization-tests.sh` for locale resolution, complete core coverage, format-placeholder consistency, fallback behavior, and Arabic text direction. Translation text has not undergone professional linguistic review.
