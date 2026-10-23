# Bundled media tools

<!-- full-translation:start -->
[简体中文](../docs/i18n/zh-Hans/ThirdParty/README.md) · [繁體中文](../docs/i18n/zh-Hant/ThirdParty/README.md) · [English](../docs/i18n/en/ThirdParty/README.md) · [日本語](../docs/i18n/ja/ThirdParty/README.md) · [한국어](../docs/i18n/ko/ThirdParty/README.md) · [Français](../docs/i18n/fr/ThirdParty/README.md) · [Deutsch](../docs/i18n/de/ThirdParty/README.md) · [Español](../docs/i18n/es/ThirdParty/README.md) · [Italiano](../docs/i18n/it/ThirdParty/README.md) · [Português (Brasil)](../docs/i18n/pt-BR/ThirdParty/README.md) · [Русский](../docs/i18n/ru/ThirdParty/README.md) · [العربية](../docs/i18n/ar/ThirdParty/README.md) · [हिन्दी](../docs/i18n/hi/ThirdParty/README.md) · [Türkçe](../docs/i18n/tr/ThirdParty/README.md) · [Nederlands](../docs/i18n/nl/ThirdParty/README.md) · [Polski](../docs/i18n/pl/ThirdParty/README.md)
<!-- full-translation:end -->


LumaView invokes unmodified FFmpeg 9.0.2 and ffprobe as separate local processes. These are built from source for Intel and Apple Silicon, targeting macOS 13. They use statically linked dav1d 1.5.3 for AV1 decoding and only system dynamic libraries. Homebrew and VLC are not required at runtime.

FFmpeg is configured under LGPL 2.1 or later, without `--enable-gpl` or `--enable-nonfree`. dav1d uses the BSD 2-Clause license. Full license notices are in `Resources/ThirdPartyNotices` and are copied into the application bundle. The exact, unmodified corresponding source archives are included in `sources/`, with SHA-256 checksums. All configuration flags and build steps are in `tools/build-media-tools.sh`. LumaView places no additional restriction on modification or replacement of these separate tools, or reverse engineering needed to debug such modifications.

Official sources:

- [FFmpeg release and signature](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. Its detached signature was verified against the FFmpeg release key `FCF986EA15E6E293A5644F10B4322F04D67658D8`.
- [dav1d release](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [FFmpeg license information](https://ffmpeg.org/legal.html).

## Rebuild

The normal application build uses the included universal binaries. To rebuild those tools, install Xcode Command Line Tools, Python 3, Meson 1.12.1 and Ninja 1.13.2. For example, use a local Python virtual environment and install `meson==1.12.1 ninja==1.13.2` there. Activate it, then run:

```sh
./tools/build-media-tools.sh
./build.sh
```

The first command verifies the source checksums, compiles both architectures and replaces `Resources/MediaTools/{ffmpeg,ffprobe}`. Use `LUMAVIEW_PYTHON` to select Python and `LUMAVIEW_MEDIA_BUILD` to select the intermediate build directory. `x86_64` or `arm64` arguments compile a single architecture; the default `universal` combines them. The app build signs the nested tools and app with a local ad-hoc signature.

Networking, capture devices, ffplay, external codecs other than dav1d, and GPL encoders are disabled. All internal decoders/demuxers available to this configuration are included. Audio output is prepared as AAC; video uses remux where possible, then VideoToolbox H.264, MPEG-4 or ProRes compatibility output. This is a viewing path, not an export or transcoding UI.

## PostScript vector interpreter

EPS, PostScript and legacy Illustrator preview additionally use bundled Ghostscript 10.08.0 as a separate, restricted local subprocess. See [README-Ghostscript.md](README-Ghostscript.md) for its AGPL-3.0-or-later license, complete corresponding source archive, checksums and reproducible universal build. The ordinary app build needs no system Ghostscript installation.
