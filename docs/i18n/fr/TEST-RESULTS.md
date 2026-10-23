# LumaView 1.7.2 — Rapport de validation

<!-- doc-navigation:start -->
[Documentation](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · [繁體中文](../zh-Hant/TEST-RESULTS.md) · [English](../en/TEST-RESULTS.md) · [日本語](../ja/TEST-RESULTS.md) · [한국어](../ko/TEST-RESULTS.md) · **Français** · [Deutsch](../de/TEST-RESULTS.md) · [Español](../es/TEST-RESULTS.md) · [Italiano](../it/TEST-RESULTS.md) · [Português (Brasil)](../pt-BR/TEST-RESULTS.md) · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · [Türkçe](../tr/TEST-RESULTS.md) · [Nederlands](../nl/TEST-RESULTS.md) · [Polski](../pl/TEST-RESULTS.md)
<!-- doc-navigation:end -->


Version 1.7.2, build 14. Le 2026-10-22, macOS 15.7.9 / Intel. L’application et les outils intégrés ont passé les contrôles d’architecture universelle arm64 + x86_64 et de signature locale ; aucun essai sur matériel Apple Silicon n’a eu lieu durant cette campagne.

## Corrections de cette version

Les zones transparentes des images matricielles sont désormais affichées directement : PNG / GIF / PSD / PSB, etc. n’ajoutent plus de damier gris et blanc ni de bordure rectangulaire du canevas. L’ombre provient de la transparence réelle du composite affiché plutôt que du canevas entier ; les marges transparentes ne produisent donc aucune ombre rectangulaire supplémentaire, tandis que trous, masques doux distincts et zones semi-transparentes contribuent au véritable contour.

L’ancienne implémentation ajoutait un damier selon CGImage.alphaInfo seulement, oubliant les PSB avec masque Quartz distinct ; chaque zoom imposait aussi un shadowPath rectangulaire, et la bordure elle-même formait une ombre rectangulaire. Ces sources rectangulaires ont été retirées des images matricielles : l’alpha composite détermine automatiquement l’ombre de la couche. Le chemin d’export du dessin projette également l’ombre de l’image seule, sans rectangle prérempli. GIF / APNG continue de remplacer la texture courante à chaque image, et l’ombre évolue avec elle, sans analyser tous les pixels transparents ni construire un RGBA complet supplémentaire à chaque image.

Les documents conservent leur papier blanc et les vidéos leur surface rectangulaire. La copie utilise toujours les pixels originaux, sans fond, damier ou ombre d’affichage. Le décodeur PSB, la planification des vignettes et l’aperçu rapide de la version précédente n’ont pas changé.

## Validation de cette campagne

| Élément | Réussites |
| --- | --- |
| Transparence, ombre des contours et changement d’image | 133 / 133 |
| Géométrie du canevas, animations et souris | 66 / 66 |
| Analyse des documents et dessin des pages complètes | 56 / 56 |
| Documents de l’installation officielle, zoom EPS / PS, pagination et focus | 75 / 75 |
| Menu contextuel et copie de l’installation officielle | 28 / 28 |
| Total | 358 / 358 |

Les tests de transparence utilisent un même dessin troué, avec saillies irrégulières et larges marges transparentes, sous forme RGBA, masque Quartz distinct et PNG, GIF, PSD, PSB réellement encodés puis décodés. La composition CALayer et les pixels exportés par draw vérifient l’absence de plaque/ombre rectangulaire aux bords transparents et la présence d’ombres sur les contours internes et externes. Ils couvrent aussi image entièrement transparente, changement d’image, rotation, zoom, changements rapides et fond semi-transparent. Les PNG exportés ont été examinés manuellement.

Les SHA-256 des PNG issus des exports CALayer et draw des six types d’entrée sont identiques : `578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`. Les médias de test sont générés par code ; aucune photo de l’utilisateur n’est incluse dans les sources.

Une sonde supplémentaire de rendu logiciel limité a comparé les anciennes et nouvelles ombres sur un bitmap de 32 MP, avec canevas logiques de 16,384 × 7,812 et 300,000 × 128, en ajustement à la fenêtre, à 100% et à 3200%. Le pic RSS du processus était d’environ 428 MiB et les temps de dessin étaient proches ; il s’agit du coût d’un instantané logiciel CALayer.render(in:), pas d’une conclusion sur la fréquence d’images GPU. Aucun cache de rastérisation des couches n’a été ajouté pour cette raison.

L’installation officielle et outputs/LumaView.app présentent des listes complètes de fichiers et empreintes identiques, et passent toutes deux codesign --verify --deep --strict. Un ZIP de sauvegarde de l’ancienne version a été conservé avant installation ; les associations par défaut ont été relues et comparées avant et après. Le ZIP de livraison a ensuite passé les contrôles CRC et de version. Les rapports historiques restent dans Tests/Release-1.7.0.md et Tests/Release-1.7.1.md ; les contrôles anciens non relancés ne sont pas comptés ici.

SHA-256 de l’exécutable principal : `b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`.

## Origine des journaux

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
