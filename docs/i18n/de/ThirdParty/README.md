# Gebündelte Medientools

<!-- doc-navigation:start -->
[Dokumentation](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · **Deutsch** · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView ruft unveränderte FFmpeg 9.0.2 und ffprobe als separate lokale Prozesse auf. Diese basieren auf Quellen für Intel und Apple Silicon und zielen auf macOS 13 ab. Sie verwenden statisch verknüpfte dav1d 1.5.3 für die AV1-Dekodierung und nur dynamische Systembibliotheken. Homebrew und VLC sind zur Laufzeit nicht erforderlich.

FFmpeg ist unter LGPL 2.1 oder höher konfiguriert, ohne `--enable-gpl` oder `--enable-nonfree`. dav1d verwendet die BSD 2-Clause-Lizenz. Vollständige Lizenzhinweise befinden sich in `Resources/ThirdPartyNotices` und werden in das Anwendungspaket kopiert. Die genauen, unveränderten entsprechenden Quellarchive sind in `sources/` enthalten, mit SHA-256-Prüfsummen. Alle Konfigurationsflags und Buildschritte befinden sich in `tools/build-media-tools.sh`. LumaView legt keine zusätzlichen Einschränkungen hinsichtlich der Änderung oder des Austauschs dieser separaten Tools oder des zum Debuggen solcher Änderungen erforderlichen Reverse Engineering fest.

Offizielle Quellen:

- [FFmpeg-Veröffentlichung und Signatur](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. Die abgetrennte Signatur wurde anhand des FFmpeg-Versionsschlüssels `FCF986EA15E6E293A5644F10B4322F04D67658D8` überprüft.
- [dav1d-Veröffentlichung](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [FFmpeg-Lizenzinformationen](https://ffmpeg.org/legal.html).

## Neu kompilieren

Der normale Anwendungsaufbau verwendet die enthaltenen universellen Binärdateien. Um diese Tools neu zu erstellen, installieren Sie Xcode Command Line Tools, Python 3, Meson 1.12.1 und Ninja 1.13.2. Verwenden Sie beispielsweise eine lokale virtuelle Python-Umgebung und installieren Sie dort `meson==1.12.1 ninja==1.13.2`. Aktivieren Sie es und führen Sie dann Folgendes aus:

```sh
./tools/build-media-tools.sh
./build.sh
```

Der erste Befehl überprüft die Quellprüfsummen, kompiliert beide Architekturen und ersetzt `Resources/MediaTools/{ffmpeg,ffprobe}`. Verwenden Sie `LUMAVIEW_PYTHON`, um Python auszuwählen, und `LUMAVIEW_MEDIA_BUILD`, um das Zwischen-Build-Verzeichnis auszuwählen. `x86_64`- oder `arm64`-Argumente kompilieren eine einzelne Architektur; Der Standardwert `universal` kombiniert sie. Der App-Build signiert die verschachtelten Tools und die App mit einer lokalen Ad-hoc-Signatur.

Netzwerk, Aufnahmegeräte, ffplay, andere externe Codecs als dav1d und GPL-Encoder sind deaktiviert. Alle für diese Konfiguration verfügbaren internen Decoder/Demuxer sind enthalten. Die Audioausgabe erfolgt als AAC; Video verwendet nach Möglichkeit Remux, dann VideoToolbox H.264, MPEG-4 oder ProRes-Kompatibilitätsausgabe. Dies ist ein Anzeigepfad, keine Export- oder Transkodierungs-Benutzeroberfläche.

## PostScript-Vektorinterpreter

EPS, PostScript und die ältere Illustrator-Vorschau verwenden zusätzlich das gebündelte Ghostscript 10.08.0 als separaten, eingeschränkten lokalen Unterprozess. Siehe [README-Ghostscript.md](README-Ghostscript.md) für die AGPL-3.0-or-later-Lizenz, vollständiges entsprechendes Quellarchiv, Prüfsummen und reproduzierbare Universal-Builds. Für die normale App-Erstellung ist keine Systeminstallation von Ghostscript erforderlich.
