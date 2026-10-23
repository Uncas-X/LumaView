> Les noms des échantillons personnels des rapports historiques ont été anonymisés ; les données et résultats des tests sont inchangés.

<!-- doc-navigation:start -->
[Documentation](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · **Français** · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# LumaView 1.7.1 — Rapport de validation

Version 1.7.1, build 13. Le 2026-10-22, macOS 15.7.9 / Intel. L’application et les trois outils intégrés ont passé les contrôles arm64 + x86_64 et de signature locale ; aucun essai sur matériel Apple Silicon n’a eu lieu durant cette campagne.

## Problèmes identifiés et corrigés

Les trois PSB de l’utilisateur sont des fichiers RLE RGB 8 bits, 4 canaux, avec transparence composite, d’environ 108–123 MiB. L’essentiel de leur taille correspond à des données de calques directement ignorables ; le canevas principal compte environ 8.5–9.6 millions de pixels.

1. L’ancien décodeur ligne par ligne appelait FileHandle pour chaque marqueur et valeur PackBits, multipliant les petites lectures et immobilisant longtemps les files de l’image principale et des vignettes. La lecture se fait maintenant par blocs d’au plus 64 KiB, avec conservation de l’état literal/run entre blocs et contrôle des limites ; les longues séquences no-op restent annulables. ZIP ne restaure la prédiction que pour les lignes échantillonnées, tout en validant le flux compressé entier.
2. Les trois fichiers contiennent une vignette JPEG RGB valide dans la ressource 1036. Elle est désormais privilégiée pour la bande, après contrôle du format, des dimensions, du rapport largeur/hauteur et de la longueur compressée ; l’image principale décode toujours le vrai composite. Un aperçu invalide, une ancienne ressource BGR ou l’absence d’aperçu entraîne le recours au composite.
3. ImageIO refuse certains petits composites PSD avec profil Generic RGB ICC valide, ce qui produisait une vignette vide. Le recours décode séparément les pixels puis réattache le profil original validé, dont modèle et composantes concordent, sans simplement l’abandonner. Le profil des originaux est identique au Generic RGB Profile du système ; la nouvelle régression génère ses données avec ce profil système, sans photos de l’utilisateur dans les sources.
4. L’image principale PSB réutilise l’en-tête déjà analysé et évite un appel supplémentaire à ImageIO pour parcourir les calques à la recherche de métadonnées. Dimensions originales, transparence et qualité de l’image principale sont conservées.

## Mesures sur les trois fichiers originaux

Ces tests locaux sur ce Mac dépendent de la charge système et du cache de fichiers et ne garantissent pas les performances de tous les appareils. Anciens et nouveaux décodeurs sont compilés avec optimisations.

| Fichier | Dimensions originales | Ancien décodage principal | Nouveau décodage principal | Nouveau décodage de vignette composite (sans aperçu incorporé) |
| --- | --- | --- | --- | --- |
| Échantillon A | 2582 × 3318 | Test annulé après plus de 15 secondes | 0.68 seconde | 0.039 seconde |
| Échantillon B | 2610 × 3307 | 14.35 secondes | 0.65 seconde | 0.028 seconde |
| Échantillon C | 2843 × 3361 | Test annulé après plus de 15 secondes | 0.70 seconde | 0.028 seconde |

Les trois vignettes demandées simultanément via le véritable ImageLoader sont terminées en environ 0.06 seconde. Les images principales complètes via le chargeur demandent environ 0.90 / 0.65 / 0.74 seconde. L’ancienne version signalait unsupported pour les trois vignettes composites ; la nouvelle les réussit toutes. Les SHA-256 des originaux sont identiques avant/après, octet pour octet ; l’application ne les a pas modifiés.

## Contrôles réussis durant cette campagne

| Élément | Résultat |
| --- | --- |
| Encodages PSD / PSB et composite transparent | 712 / 712 |
| Performances RLE, aperçu incorporé, ICC, passages entre blocs et annulation | 54 / 54 |
| Intégration réelle ImageLoader des trois PSB originaux | 21 / 21 |
| Bande de 443 fichiers, cache et rappels invalidés | 37 / 37 |
| Requêtes de vignettes indépendantes et annulation | 13 / 13 |
| Bibliothèque d’images et décodage système | 78 / 78 |
| Menu contextuel et copie de la version publiée optimisée installée | 28 / 28 |
| Total | 943 / 943 |

Les nouveaux tests couvrent literal d’un octet très dense, limites de 64 KiB, annulation des longues séquences no-op, troncature et dépassements, contenus corrects distincts des vignettes incorporées et images principales, ICC, transparence et redimensionnement non entier de petites images. Les 112 combinaisons d’encodage et 128 structures avec marqueurs de transparence de calques précédentes restent valides. Les contrôles de la bande couvrent changements rapides, annulation hors écran et absence de contamination par les anciens rappels.

L’installation officielle et outputs/LumaView.app ont des listes complètes de fichiers et empreintes identiques, et passent codesign --verify --deep --strict. Un ZIP de sauvegarde de l’ancienne version a été conservé avant installation ; les associations par défaut n’ont pas été modifiées. Le ZIP livré est contrôlé séparément par CRC et version. Le rapport complet historique 1.7.0 reste dans Tests/Release-1.7.0.md ; ses vérifications non relancées sont exclues ici.

SHA-256 de l’exécutable principal : `cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`.

## Journaux

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
