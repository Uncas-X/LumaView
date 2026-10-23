# Języki interfejsu LumaView

<!-- doc-navigation:start -->
[Dokumentacja](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · **Polski**
<!-- doc-navigation:end -->


Aplikacja zaczyna od **Zgodnie z systemem**. Wybiera pierwszy obsługiwany język z preferencji macOS, a gdy brak — angielski. Wybór w **LumaView → Język…** działa natychmiast i jest pamiętany tylko dla tej aplikacji.

Dostępne: chiński uproszczony, chiński tradycyjny, angielski, japoński, koreański, francuski, niemiecki, hiszpański, włoski, portugalski, rosyjski, arabski, hindi, turecki, niderlandzki i polski. Warianty portugalskiego obecnie używają katalogu brazylijskiego. Rodzime nazwy w selektorze są celowe, by można było wrócić z nieznanego języka.

`catalog.json` mapuje czytelne uproszczone chińskie klucze źródłowe na tłumaczenia. `core-keys.json` określa wspólne kontrolki, menu, ustawienia, nawigację dokumentów, metadane i pomoc klawiatury wymagane w każdym katalogu. Rzadkie komunikaty diagnostyczne używają angielskiego, jeśli brak wpisu w języku. Nazwy plików, katalogów, kodeków, formatów i osadzone metadane aparatu pozostają. System dostarcza tekst swoich okien we własnym języku.

Dla stałego tekstu używaj `L10n.tr("source key")`. Dla dynamicznego — `L10n.format("第 %d / %d 页", current, total)`, zamiast interpolować chiński tekst przed tłumaczeniem. Typy i liczby znaczników muszą być zgodne. Obserwuj `L10n.languageDidChange`, aby odświeżać interfejs i rysowany tekst. Testy używają `useLanguageForTesting`, nie zmieniając zapisanego języka użytkownika.

Uruchom `Tests/run-localization-tests.sh` dla wyboru języka, pokrycia kluczy, zgodności znaczników, języka zapasowego i kierunku arabskiego. Tłumaczenia nie przeszły profesjonalnej redakcji językowej.
