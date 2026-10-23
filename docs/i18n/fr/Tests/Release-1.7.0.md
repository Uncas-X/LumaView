> Les noms des échantillons personnels des rapports historiques ont été anonymisés ; les données et résultats des tests sont inchangés.

<!-- doc-navigation:start -->
[Documentation](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · **Français** · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# LumaView 1.7.0 — Rapport de validation

Date : 2026-10-22 (Asia/Shanghai). Environnement de cette campagne : macOS 15.7.9, x86_64. L’application cible macOS 13+ et ses quatre exécutables sont universels Intel / Apple Silicon.

## Modifications et résultats mesurés

- Ghostscript 10.08.0 est intégré : l’ouverture d’EPS, PostScript ou anciens AI PostScript produit en arrière-plan un PDF conservant tracés vectoriels, texte et images incorporées, confié ensuite au canevas existant. Aucune installation d’interpréteur ni conversion manuelle n’est nécessaire ; zoom, déplacement, rotation et navigation multipage gardent les interactions actuelles. Le TIFF incorporé reste un recours lorsque la conversion vectorielle échoue et que le fichier offre un aperçu ; ce recours matriciel n’est pas étiqueté vectoriel.
- L’échantillon original `sample-vector.eps` a été testé avec son contenu PostScript complet. L’analyse du PDF obtenu compte **147,521 opérations de tracé/dégradé, 59 opérations de texte et 160 appels XObject**. Les XObject sont comptés via les opérateurs PDF `Do` et peuvent être des images ou des Form ; ce nombre n’équivaut pas à des images distinctes. Le test confirme la conservation de véritables vecteurs ; les SHA-256 de l’EPS original et de `sample-vector.svg` ont été comparés avant/après et les originaux sont inchangés.
- PostScript utilise un processus distinct annulable, Ghostscript SAFER et le bac à sable système. L’entrée est copiée dans un dossier temporaire réservé ; l’interpréteur ne peut lire les autres fichiers de l’utilisateur, écrire arbitrairement hors de ce dossier ni utiliser des tubes externes. Les vérifications couvrent délai limite, annulation, réutilisation par plusieurs consommateurs, entrée endommagée et invalidation du cache. Seuls les résultats complets sont publiés atomiquement, sans PDF partiel pour les vignettes. La visionneuse réelle vérifie EPS à 3200% vectoriel, focus haut/bas et pagination gauche/droite des PS multipages, et qu’un passage à PNG pendant une conversion empêche l’ancien résultat de remplacer l’image courante.
- Le groupe Photoshop ajoute `.psb` à `.psd` pour découverte, image principale, vignettes et associations par défaut. Le composite compatible est lu en préservant les dimensions originales ; les grands fichiers produisent des aperçus limités aux besoins d’affichage. Validation de **112 combinaisons d’encodage, 128 structures avec marqueurs de transparence de calques, 1 grand PSB et 13 échantillons corrompus**. La transparence du composite est reconnue via le nombre de calques et les marqueurs Lr16/Lr32, Mtrn/Mt16/Mt32 ; un canal Alpha supplémentaire ordinaire n’est pas pris pour la transparence du composite. Les contrôles couvrent valeurs de pixels transparents, retrait du fond blanc, cohérence des encodages, annulation des grandes lignes et intégration image principale/vignettes.
- Le panneau des applications par défaut relit les associations réelles à chaque ouverture, réactivation et fin de réglage en lot. Les associations système persistent après redémarrage ; un brouillon non appliqué n’est pas présenté comme réussi. Une coche indique que tous les types du format désignent cette application ; une correspondance partielle ou un autre exemplaire ayant le même bundle ID produit un tiret expliqué par l’aide. Effacer change seulement le brouillon et ne révoque pas les associations système.
- « Sélectionner tous les formats » coche en une fois images, vecteurs/documents, vidéo et audio, y compris hors des résultats de recherche ; il faut encore appliquer pour enregistrer les associations. Détection, succès partiel, relecture des échecs, reconstruction du contrôleur, distinction brouillon/état réel et sélection globale ont été testés avec un backend mock en mémoire, sans modifier les applications système de l’utilisateur.
- Les nouvelles chaînes des réglages, de PostScript et Photoshop couvrent les 16 langues ; les contrôles des textes essentiels et paramètres de format réussissent.

## Validation de cette campagne

Seuls les journaux ci-dessous avec bilan complet de réussite sont comptés ; les modules historiques non relancés sont exclus.

| Contrôle | Réussites |
| --- | --- |
| Conversion vectorielle PostScript, annulation, isolation et EPS réel | 24 / 24 |
| Compatibilité SVG / EPS et contrôle des pièces jointes originales | 64 / 64 |
| Composites PSD / PSB, canaux transparents, grandes images et données endommagées | 712 / 712 |
| Relecture système et réglage en lot des applications par défaut (mock) | 101 / 101 |
| Panneau des formats, état après réouverture et sélection globale (mock) | 34 / 34 |
| 16 langues et paramètres | 174 / 174 |
| Déclarations de formats de l’application publiée | 15 / 15 |
| Bibliothèque d’images et décodage système | 78 / 78 |
| Géométrie du canevas, animations et souris | 66 / 66 |
| Analyse documentaire et dessin de pages complètes | 56 / 56 |
| Focus documentaire, zoom/pagination EPS / PS et annulation au changement de fichier | 75 / 75 |
| Clics dans une vraie fenêtre et cycle de vie | 65 / 65 |
| Vignettes de 443 fichiers, cache et rappels périmés | 37 / 37 |
| Annulation des requêtes de vignettes et isolation des consommateurs | 13 / 13 |
| Menu contextuel et presse-papiers privé de la version publiée installée | 28 / 28 |
| **Total** | **1542 / 1542** |

La version publiée optimisée installée a aussi subi 28 contrôles contextuels via le vrai menu et la distribution target/action, avec presse-papiers nommé distinct. Ils vérifient copie d’image, image vidéo courante, image PDF et page entière, rotation et rejet des résultats périmés au changement/à la fermeture ; le presse-papiers système de l’utilisateur n’a pas été écrasé. Les régressions des clics, du cycle de vie, du focus de page, de l’affichage intégral, du cache et de l’annulation des vignettes ont toutes réussi.

## Contrôle du dossier publié et de l’installation

Version **1.7.0, build 12**. Avant rédaction, bundle ID, version, build, liste complète des fichiers et SHA-256 ont été comparés entre `outputs/LumaView.app` et `/Applications/LumaView.app` ; les contenus sont identiques. Les quatre exécutables ont passé les contrôles des deux architectures et les deux applications `codesign --verify --deep --strict`. Ghostscript annonce 10.08.0 ; ressources linguistiques et de version correspondent aux sources et le SHA-256 de l’archive Ghostscript à son manifeste. La compilation resigne l’interpréteur : le binaire signé n’a donc pas à être identique octet pour octet à la copie non resignée du dossier source.

| Exécutable | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

Ce rapport ne remplace pas le contrôle d’intégrité ultérieur du ZIP et ne revendique aucune notarisation Apple. La signature est locale ad hoc ; Apple Silicon a été compilé de façon croisée et inspecté, sans exécution sur ce matériel durant cette campagne. Archive source Ghostscript, licences et instructions de reconstruction accompagnent les sources livrées.

## Périmètre et limites

Les images matricielles incorporées aux EPS / PS restent limitées par leur résolution ; polices ou fichiers externes et PostScript spécial ou endommagé ne sont pas garantis convertibles intégralement. L’aperçu PSD / PSB dépend du composite compatible enregistré, sans édition des calques ni reconstruction d’un composite absent ; un message demande alors de réenregistrer avec « Maximiser la compatibilité ». Les dimensions originales peuvent dépasser celles de l’aperçu affiché ; un aperçu limité ne signifie pas que tous les pixels source ont été décodés. Voir [FORMATS.md](../FORMATS.md) pour les autres limites.

## Origine des journaux de cette campagne

Les fichiers suivants sont copiés dans `Tests/` ; les rapports historiques non relancés sont conservés mais exclus du total :

- `PostScript-test-results.txt` ← `work/postscript-17/postscript-test-results.txt`
- `vector-compatibility-test-results.txt` ← `work/vector-compatibility-1.7.0/vector-compatibility-test-results.txt`
- `Photoshop-test-results.txt` ← `work/psb-support/results.txt`
- `Default-application-test-results.txt` ← `work/default-application-1.7-results.txt`
- `Default-preferences-test-results.txt` ← `work/default-preferences-tests/default-preferences-test-results.txt`
- `Localization-test-results.txt` ← `work/localization-1.7-results.txt`
- `Media-declaration-test-results.txt` ← `work/media-declaration-1.7.0.txt`
- `Core-test-results.txt` ← `work/core-1.7.0-run.log`
- `Canvas-test-results.txt` ← `work/canvas-1.7.0-run.log`
- `Document-core-test-results.txt` ← `work/document-1.7.0/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-1.7.0/document-test-results.txt`
- `UI-test-results.txt` ← `work/ui-1.7.0/ui-test-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.0/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.0-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.0/context-menu-test-results.txt`
