# Gebundelde mediatools

<!-- doc-navigation:start -->
[Documentatie](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · **Nederlands** · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView roept ongewijzigde FFmpeg 9.0.2 en ffprobe aan als afzonderlijke lokale processen. Ze zijn uit bron gebouwd voor Intel en Apple Silicon, gericht op macOS 13. Ze gebruiken statisch gekoppelde dav1d 1.5.3 voor AV1 en uitsluitend dynamische systeembibliotheken. Homebrew en VLC zijn tijdens gebruik niet nodig.

FFmpeg is geconfigureerd onder LGPL 2.1 of later, zonder `--enable-gpl` of `--enable-nonfree`. dav1d gebruikt BSD 2-Clause. Volledige licentieteksten staan in `Resources/ThirdPartyNotices` en worden in de app gekopieerd. Exacte ongewijzigde bijbehorende bronarchieven zitten in `sources/`, met SHA-256. Alle opties en bouwstappen staan in `tools/build-media-tools.sh`. LumaView legt geen extra beperking op aan wijziging/vervanging van deze aparte tools, of reverse-engineering die nodig is om zulke wijzigingen te debuggen.

Officiële bronnen:

- [FFmpeg-release en handtekening](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. De losse handtekening is geverifieerd met FFmpeg-releasesleutel `FCF986EA15E6E293A5644F10B4322F04D67658D8`.
- [dav1d-release](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [FFmpeg-licentie-informatie](https://ffmpeg.org/legal.html).

## Herbouwen

De gewone appbuild gebruikt meegeleverde universele binaries. Installeer voor herbouw Xcode Command Line Tools, Python 3, Meson 1.12.1 en Ninja 1.13.2. Gebruik bijvoorbeeld een lokale Python-virtualenv met `meson==1.12.1 ninja==1.13.2`. Activeer deze en voer uit:

```sh
./tools/build-media-tools.sh
./build.sh
```

De eerste opdracht verifieert bronchecksums, compileert beide architecturen en vervangt `Resources/MediaTools/{ffmpeg,ffprobe}`. Kies Python met `LUMAVIEW_PYTHON` en de tussenliggende bouwmap met `LUMAVIEW_MEDIA_BUILD`. Argumenten `x86_64` of `arm64` bouwen één architectuur; standaard `universal` combineert beide. De appbuild ondertekent tools en app met een lokale ad-hoc-handtekening.

Netwerk, opnameapparaten, ffplay, externe codecs behalve dav1d en GPL-encoders zijn uitgeschakeld. Alle interne decoders/demuxers die deze configuratie biedt zijn opgenomen. Audio-uitvoer wordt AAC; video gebruikt waar mogelijk remux, daarna VideoToolbox H.264, MPEG-4 of ProRes voor compatibiliteit. Dit is een weergavepad, geen export- of transcodeerinterface.

## PostScript-vectorinterpreter

EPS, PostScript en oude Illustrator-voorbeelden gebruiken daarnaast gebundelde Ghostscript 10.08.0 als apart beperkt lokaal subproces. Zie [README-Ghostscript.md](README-Ghostscript.md) voor AGPL-3.0-or-later, volledige bijbehorende bron, checksums en reproduceerbare universele build. Normaal bouwen vereist geen systeeminstallatie van Ghostscript.
