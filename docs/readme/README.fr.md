# LumaView — Français

<!-- language-navigation:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Français** · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- language-navigation:end -->

Guide de démarrage de **LumaView 1.7.2 (build 14)**. Manuel complet en [anglais](README.en.md) ou en [chinois](../../README.md).

LumaView est une visionneuse native macOS pour images, vidéos, audio et documents multipages. Inspirée de Picasa Photo Viewer, elle possède son propre nom et une icône originale, sans affiliation avec Google. Elle privilégie la consultation des fichiers.

## Télécharger et installer

Téléchargez [LumaView pour macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip) ou consultez [toutes les versions](https://github.com/Uncas-X/LumaView/releases). L’application universelle prend en charge Intel et Apple Silicon et nécessite **macOS 13 ou ultérieur**.

Décompressez l’archive et glissez `LumaView.app` dans Applications. L’application utilise une signature locale ad hoc et n’est pas notariée par Apple. Si macOS bloque son ouverture, vérifiez sa provenance puis suivez les indications de Confidentialité et sécurité pour l’autoriser.

## Utilisation

Déposez un fichier ou un dossier dans la fenêtre, ou utilisez `Cmd+O`. Ouvrir un fichier permet de parcourir les médias voisins du même dossier. L’analyse reste limitée au niveau courant, sans parcourir les sous-dossiers.

- Bande de vignettes, zoom, déplacement, rotation, plein écran, transitions fluides et fond translucide à effet de verre dépoli.
- Les zones transparentes des images matricielles PNG, GIF, PSD et PSB restent transparentes ; les ombres suivent le contenu. Les pages de documents conservent un fond de papier blanc. Les PSD/PSB utilisent l’image composite de compatibilité enregistrée, sans édition des calques.
- Lecture vidéo/audio native en priorité, avec FFmpeg intégré comme solution de compatibilité. L’audio affiche sa pochette intégrée, ou une forme d’onde en son absence.
- Navigation dans les PDF, AI compatibles PDF et TIFF multipages. Rendu vectoriel des SVG, des EPS/PS pris en charge et des anciens AI. Ghostscript intégré traite les EPS/PS ; les images matricielles incorporées restent limitées à leur résolution d’origine.
- Un clic droit permet d’ouvrir le fichier avec une autre application, de l’afficher dans le Finder, ou de copier l’image, l’image vidéo courante, une page PDF ou une image incorporée au PDF lorsque celle-ci est prise en charge.
- Lecture/pause et arrêt des médias sont séparés du diaporama. Les réglages permettent d’associer les formats à LumaView et de choisir parmi 16 langues. Par défaut, la langue suit celle du système.

## Raccourcis

| Touche | Action |
|---|---|
| `Cmd+O` | Ouvrir un fichier ou un dossier |
| `←` / `→` | Fichier ou page précédent/suivant selon le focus |
| `↑` / `↓` | Donner le focus aux pages/aux fichiers d’un document multipage |
| Molette, pincement, `+` / `-` | Zoomer/dézoomer |
| `0` ; `1` | Ajuster à la fenêtre ; basculer entre 100 % et ajustement |
| `Cmd+R` ; `F` | Rotation ; plein écran |
| `P` ; `S` | Lecture/pause du média ; arrêt |
| `Cmd+4` | Commander le diaporama |
| `Cmd+C` | Copier l’image, l’image vidéo courante ou la page |

**Espace change le fond**, sans commander la lecture.

## Compiler

Installez Xcode ou les outils de ligne de commande Swift, puis exécutez à la racine du dépôt :

```bash
./build.sh
open ../LumaView.app
```

`./build.sh --host` compile seulement pour l’architecture du Mac courant. Les fichiers intermédiaires vont dans `.build/`. `LUMAVIEW_WORK_ROOT` change ce dossier et `LUMAVIEW_APP_PATH` le chemin de l’application produite. Ces chemins partent de la racine du dépôt, pas du dossier de ce guide. Les outils multimédias nécessaires, leurs sources et leurs licences sont fournis dans le dépôt.

## Limites et confidentialité

LumaView lit les fichiers locaux, sans téléversement ni modification des originaux. Il ne fournit ni éditeur, ni gestion de calques, ni base de photothèque, ni synchronisation cloud. Les grandes images peuvent utiliser un aperçu réduit : agrandir cet aperçu ne restitue pas les détails écartés. Certaines conversions doivent traiter le fichier entier avant la lecture et utilisent du temps et un cache local. Tous les codecs ne sont pas garantis ; les fichiers protégés par DRM, endommagés ou non pris en charge peuvent échouer.

Voir les [formats pris en charge, en chinois](../../FORMATS.md), les [mentions tierces](../../ThirdParty/README.md) et les [mentions Ghostscript](../../ThirdParty/README-Ghostscript.md).
