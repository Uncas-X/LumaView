# Langues de l’interface LumaView

<!-- doc-navigation:start -->
[Documentation](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · **Français** · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


L’application démarre avec **Suivre le système**. Elle choisit la première langue prise en charge dans la liste préférée de macOS, puis l’anglais si aucune ne convient. Un choix dans **LumaView → Langue…** prend effet immédiatement et n’est mémorisé que pour cette application.

Langues proposées : chinois simplifié, chinois traditionnel, anglais, japonais, coréen, français, allemand, espagnol, italien, portugais, russe, arabe, hindi, turc, néerlandais et polonais. Les variantes portugaises utilisent actuellement le catalogue portugais brésilien. Les noms natifs du sélecteur sont intentionnels, pour permettre de retrouver sa langue depuis une interface inconnue.

`catalog.json` associe des clés source lisibles en chinois simplifié aux chaînes traduites. `core-keys.json` définit commandes courantes, menus, réglages, navigation documentaire, libellés de métadonnées et aide clavier requis dans chaque catalogue. Les diagnostics rares utilisent le repli anglais lorsqu’une langue n’a pas d’entrée. Noms de fichiers, dossiers, codecs, formats et métadonnées photographiques incorporées restent inchangés. Le système fournit ses propres textes de boîtes de dialogue dans sa langue.

Utilisez `L10n.tr("source key")` pour le texte statique. Pour le texte dynamique, utilisez `L10n.format("第 %d / %d 页", current, total)` plutôt que d’interpoler une chaîne chinoise avant traduction. Conservez les types et nombres de paramètres dans toutes les traductions. Observez `L10n.languageDidChange` pour actualiser les interfaces existantes et redessiner les textes. Les tests utilisent `useLanguageForTesting` pour ne pas modifier la langue mémorisée de l’utilisateur.

Exécutez `Tests/run-localization-tests.sh` pour contrôler résolution de langue, couverture essentielle complète, cohérence des paramètres, replis et direction du texte arabe. Les traductions n’ont pas fait l’objet d’une révision linguistique professionnelle.
