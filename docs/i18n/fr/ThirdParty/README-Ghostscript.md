# Outil de conversion de documents Ghostscript

<!-- doc-navigation:start -->
[Documentation](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · **Français** · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView appelle Ghostscript **10.08.0**, publié par Artifex le 2026-09-08, comme exécutable local distinct pour convertir EPS et PostScript en PDF temporaire. Le PDF conserve les tracés vectoriels, textes et dégradés pris en charge. Les images déjà incorporées sous forme de pixels restent matricielles. Ghostscript n’est pas lié à l’application Swift et aucune installation Homebrew n’est nécessaire pour exécuter cet outil fourni.

## Licence et sources correspondantes

Ghostscript est distribué sous **GNU Affero General Public License version 3 ou ultérieure**, conformément au fichier `LICENSE` original de cette version. La licence complète, les mentions de copyright Ghostscript, l’exception d’incorporation de polices, les mentions Adobe CMap et celles des dépendances sont copiées sans modification dans `Resources/ThirdPartyNotices/Ghostscript/`. Artifex propose aussi une licence commerciale distincte, non comprise ici. Voir la [page officielle des licences](https://www.ghostscript.com/licensing/index.html).

La version source correspondante exacte, non modifiée, avec sources des dépendances et polices intégrées, se trouve dans `ThirdParty/sources/ghostscript-10.08.0.tar.xz`. Son SHA-256 est enregistré dans `ThirdParty/sources/SHA256SUMS-Ghostscript` :

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

Provenance : [page officielle des versions](https://www.ghostscript.com/releases/index.html) et [fichiers de la version Artifex 10.08.0](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). La somme correspond à celle publiée pour l’archive `.tar.xz`. Les sources et ce script de compilation accompagnent la distribution source de LumaView. LumaView n’impose aucune restriction supplémentaire à la modification ou au remplacement de cet outil distinct, ni à la rétro-ingénierie nécessaire à leur débogage. Ces mentions décrivent le composant tiers fourni et ne prétendent pas changer la licence du code de l’application.

## Reconstruction

Prérequis : macOS, Xcode Command Line Tools, l’archive source fournie et les outils de compilation standard de macOS. Aucune bibliothèque Homebrew n’est utilisée. Depuis le dossier source de LumaView :

```sh
./tools/build-document-tools.sh
./build.sh
```

Le script vérifie l’archive, compile Intel et Apple Silicon depuis des dossiers sources distincts, retire les symboles locaux et réunit les architectures dans `Resources/DocumentTools/gs`. Toutes deux ciblent macOS 13.0 ou ultérieur. Il n’exécute pas `make install` et n’écrit pas dans un gestionnaire de paquets système. `LUMAVIEW_DOCUMENT_BUILD` choisit le dossier intermédiaire ; `LUMAVIEW_DOCUMENT_JOBS` règle le parallélisme de make (4 par défaut). L’argument facultatif `x86_64` ou `arm64` ne compile qu’une architecture. La compilation de l’application signe l’exécutable copié avec l’application.

L’exécutable contient le code d’initialisation, les polices fournies, Adobe CMaps et les profils ICC dans son système de fichiers interne `%rom%`. Les chemins de recherche externes par défaut sont vides. Seul le périphérique de sortie `pdfwrite` est activé. Impression/CUPS, X11, GTK, fontconfig, D-Bus, Tesseract/OCR, pilotes dynamiques, IJS externe et outils d’extraction documentaire sont désactivés. Les bibliothèques de décodage, couleur et polices sont compilées depuis l’archive correspondante ; les liaisons dynamiques se limitent aux bibliothèques système Apple. Consultez la [documentation officielle de compilation](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html) pour le système ROM et la compilation croisée.

LumaView lance l’interpréteur avec `-dSAFER`, un fichier d’entrée et de sortie précis, un dossier temporaire privé, une annulation et un délai limite. L’environnement du processus ne doit pas hériter d’options Ghostscript ou de chemins de bibliothèques définis par l’utilisateur. Exemple pour des fichiers de test fiables générés :

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

Toutes les options figurent dans `tools/build-document-tools.sh` ; aucune modification n’est appliquée à l’archive source. L’exécution native ne peut être testée que sur les architectures prises en charge par la machine de compilation. Les contrôles de publication inspectent les deux tranches Mach-O et exécutent un EPS généré contenant tracés et texte sur l’architecture compatible avec l’hôte, afin de confirmer que le PDF conserve les opérateurs de dessin vectoriel et de texte.
