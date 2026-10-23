# Dołączone narzędzia multimedialne

<!-- doc-navigation:start -->
[Dokumentacja](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · **Polski**
<!-- doc-navigation:end -->


LumaView uruchamia niezmienione FFmpeg 9.0.2 i ffprobe jako osobne lokalne procesy. Zbudowano je ze źródeł dla Intel i Apple Silicon z celem macOS 13. Używają statycznego dav1d 1.5.3 do AV1 i tylko dynamicznych bibliotek systemu. Do działania nie potrzeba Homebrew ani VLC.

FFmpeg skonfigurowano na LGPL 2.1 lub nowszej, bez `--enable-gpl` i `--enable-nonfree`. dav1d ma BSD 2-Clause. Pełne licencje są w `Resources/ThirdPartyNotices` i kopiowane do aplikacji. Dokładne niezmienione odpowiadające źródła są w `sources/`, z SHA-256. Wszystkie opcje i kroki są w `tools/build-media-tools.sh`. LumaView nie nakłada dodatkowych ograniczeń na modyfikację/zastępowanie tych osobnych narzędzi ani inżynierię wsteczną potrzebną do debugowania zmian.

Oficjalne źródła:

- [Wydanie i podpis FFmpeg](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. Osobny podpis zweryfikowano kluczem wydania FFmpeg `FCF986EA15E6E293A5644F10B4322F04D67658D8`.
- [Wydanie dav1d](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [Licencjonowanie FFmpeg](https://ffmpeg.org/legal.html).

## Przebudowa

Zwykła kompilacja używa dołączonych uniwersalnych binariów. Do przebudowy zainstaluj Xcode Command Line Tools, Python 3, Meson 1.12.1 i Ninja 1.13.2. Można użyć lokalnego wirtualnego środowiska Python z `meson==1.12.1 ninja==1.13.2`. Aktywuj je i uruchom:

```sh
./tools/build-media-tools.sh
./build.sh
```

Pierwsze polecenie sprawdza sumy źródeł, kompiluje obie architektury i zastępuje `Resources/MediaTools/{ffmpeg,ffprobe}`. Python wybiera `LUMAVIEW_PYTHON`, katalog pośredni `LUMAVIEW_MEDIA_BUILD`. Argument `x86_64` lub `arm64` buduje jedną architekturę; domyślne `universal` łączy obie. Kompilacja podpisuje narzędzia i aplikację lokalnym podpisem ad-hoc.

Sieć, urządzenia przechwytujące, ffplay, zewnętrzne kodeki poza dav1d i enkodery GPL są wyłączone. Wszystkie wewnętrzne dekodery/demultipleksery dostępne w konfiguracji są dołączone. Audio przygotowuje się jako AAC; wideo używa remux, gdy możliwe, potem zgodnego wyjścia VideoToolbox H.264, MPEG-4 lub ProRes. To ścieżka oglądania, nie interfejs eksportu/transkodowania.

## Interpreter wektorowy PostScript

EPS, PostScript i stary Illustrator dodatkowo używają dołączonego Ghostscript 10.08.0 jako osobnego ograniczonego lokalnego podprocesu. Licencja AGPL-3.0-or-later, pełne odpowiadające źródło, sumy i odtwarzalna uniwersalna kompilacja: [README-Ghostscript.md](README-Ghostscript.md). Zwykła budowa nie wymaga systemowego Ghostscript.
