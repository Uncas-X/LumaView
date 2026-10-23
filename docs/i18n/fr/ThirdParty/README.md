# Outils multimédias intégrés

<!-- doc-navigation:start -->
[Documentation](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · **Français** · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView appelle FFmpeg 9.0.2 et ffprobe non modifiés comme processus locaux distincts. Ils sont compilés depuis leurs sources pour Intel et Apple Silicon, avec macOS 13 comme cible. Ils utilisent dav1d 1.5.3 lié statiquement pour décoder AV1 et uniquement des bibliothèques dynamiques système. Ni Homebrew ni VLC ne sont nécessaires à l’exécution.

FFmpeg est configuré sous LGPL 2.1 ou ultérieure, sans `--enable-gpl` ni `--enable-nonfree`. dav1d utilise BSD 2-Clause. Les mentions de licence complètes figurent dans `Resources/ThirdPartyNotices` et sont copiées dans l’application. Les archives sources correspondantes exactes et non modifiées figurent dans `sources/`, avec leurs sommes SHA-256. Toutes les options de configuration et étapes de compilation sont dans `tools/build-media-tools.sh`. LumaView n’impose aucune restriction supplémentaire à la modification ou au remplacement de ces outils distincts, ni à la rétro-ingénierie nécessaire au débogage de ces modifications.

Sources officielles :

- [Version et signature FFmpeg](https://ffmpeg.org/download.html) : `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. La signature détachée a été vérifiée avec la clé de publication FFmpeg `FCF986EA15E6E293A5644F10B4322F04D67658D8`.
- [Version dav1d](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/) : `dav1d-1.5.3.tar.xz`.
- [Informations de licence FFmpeg](https://ffmpeg.org/legal.html).

## Reconstruction

La compilation normale de l’application utilise les exécutables universels fournis. Pour reconstruire ces outils, installez Xcode Command Line Tools, Python 3, Meson 1.12.1 et Ninja 1.13.2. Vous pouvez par exemple installer `meson==1.12.1 ninja==1.13.2` dans un environnement virtuel Python local. Activez-le, puis lancez :

```sh
./tools/build-media-tools.sh
./build.sh
```

La première commande vérifie les sommes de contrôle, compile les deux architectures et remplace `Resources/MediaTools/{ffmpeg,ffprobe}`. `LUMAVIEW_PYTHON` choisit Python et `LUMAVIEW_MEDIA_BUILD` le dossier de compilation intermédiaire. Les arguments `x86_64` ou `arm64` compilent une seule architecture ; `universal`, par défaut, les réunit. La compilation de l’application signe les outils imbriqués et l’application avec une signature locale ad hoc.

Réseau, périphériques de capture, ffplay, codecs externes autres que dav1d et encodeurs GPL sont désactivés. Tous les décodeurs/démultiplexeurs internes disponibles dans cette configuration sont inclus. L’audio est préparé en AAC ; la vidéo utilise si possible un remultiplexage, puis une sortie compatible VideoToolbox H.264, MPEG-4 ou ProRes. Ce mécanisme sert à la consultation, pas à une interface d’export ou de transcodage.

## Interpréteur vectoriel PostScript

Les aperçus EPS, PostScript et anciens Illustrator utilisent également Ghostscript 10.08.0 intégré, dans un sous-processus local distinct et restreint. Consultez [README-Ghostscript.md](README-Ghostscript.md) pour sa licence AGPL-3.0-or-later, ses sources correspondantes complètes, sommes de contrôle et compilation universelle reproductible. Une compilation normale ne nécessite pas d’installation système de Ghostscript.
