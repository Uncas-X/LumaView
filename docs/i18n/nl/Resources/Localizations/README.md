# Interfacetalen van LumaView

<!-- doc-navigation:start -->
[Documentatie](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · **Nederlands** · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


De app start met **Volg systeem**. De eerste ondersteunde taal in de macOS-voorkeurslijst wordt gekozen, anders Engels. Een keuze in **LumaView → Taal…** werkt direct en wordt alleen voor deze app onthouden.

Beschikbaar: Vereenvoudigd Chinees, Traditioneel Chinees, Engels, Japans, Koreaans, Frans, Duits, Spaans, Italiaans, Portugees, Russisch, Arabisch, Hindi, Turks, Nederlands en Pools. Portugese varianten gebruiken momenteel de Braziliaans-Portugese catalogus. De eigen taalnamen in de kiezer zijn bewust gekozen, zodat gebruikers uit een onbekende interfacetaal kunnen terugkeren.

`catalog.json` koppelt leesbare Vereenvoudigd-Chinese bronsleutels aan vertalingen. `core-keys.json` definieert algemene bediening, menu's, instellingen, documentnavigatie, metadatalabels en toetsenbordhulp die elke catalogus moet bevatten. Zeldzame diagnostiek valt terug op Engels als de taal geen eigen item heeft. Namen van bestanden, mappen, codecs, formaten en ingesloten camerametadata veranderen niet. Het besturingssysteem levert systeemdialogen in zijn eigen taal.

Gebruik `L10n.tr("source key")` voor vaste tekst. Gebruik voor dynamische tekst `L10n.format("第 %d / %d 页", current, total)`, in plaats van vóór vertaling een Chinese string te interpoleren. Houd typen en aantallen placeholders gelijk. Observeer `L10n.languageDidChange` om bestaande interfaces en getekende tekst te vernieuwen. Tests gebruiken `useLanguageForTesting` om de opgeslagen gebruikerstaal niet te wijzigen.

Voer `Tests/run-localization-tests.sh` uit voor taalkeuze, volledige kernsleuteldekking, placeholderconsistentie, terugval en Arabische tekstrichting. De vertalingen hebben geen professionele taalkundige beoordeling gehad.
