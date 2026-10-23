# Ghostscript-Tool zur Dokumentenkonvertierung

<!-- doc-navigation:start -->
[Dokumentation](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · **Deutsch** · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView ruft Ghostscript **10.08.0**, veröffentlicht von Artifex am 2026-09-08, als separate lokale ausführbare Datei auf, um EPS und PostScript in ein temporäres PDF zu konvertieren. Die Ausgabe PDF behält unterstützte Vektorpfade, Text und Farbverläufe bei. Bereits als Rasterpixel eingebettete Bilder bleiben Rasterbilder. Ghostscript ist nicht mit der Swift-Anwendung verknüpft und es ist keine Homebrew-Installation erforderlich, um diese gebündelte ausführbare Datei auszuführen.

## Lizenz und entsprechende Quelle

Ghostscript wird unter der **GNU Affero General Public License Version 3 oder höher** vertrieben, wie in der Originaldatei `LICENSE` in dieser Version angegeben. Die vollständige Lizenz, der Ghostscript-Urheberrechtshinweis, die Ausnahme zur Schriftarteinbettung, die Adobe CMap-Hinweise und die enthaltenen Abhängigkeitshinweise werden ohne Änderungen in `Resources/ThirdPartyNotices/Ghostscript/` kopiert. Eine separate kommerzielle Lizenz ist auch von Artifex erhältlich; Dieses Paket beinhaltet keine kommerzielle Lizenz. Siehe die [offizielle Lizenzseite](https://www.ghostscript.com/licensing/index.html).

Die genaue, unveränderte entsprechende Quellversion, einschließlich der gebündelten Abhängigkeits- und Schriftartquellen, ist unter `ThirdParty/sources/ghostscript-10.08.0.tar.xz` enthalten. Sein SHA-256 ist in `ThirdParty/sources/SHA256SUMS-Ghostscript` aufgezeichnet:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

Herkunft der Quelle: [offizielle Veröffentlichungsseite](https://www.ghostscript.com/releases/index.html) und [Artifexs 10.08.0 Veröffentlichungsressourcen](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). Die Prüfsumme stimmt mit der Prüfsumme überein, die für das Asset `.tar.xz` veröffentlicht wurde. Das Quellpaket und dieses Build-Skript liegen der LumaView-Quellverteilung bei. LumaView erlegt keine zusätzliche Einschränkung für die Änderung oder den Austausch dieses separaten Tools oder für das Reverse Engineering auf, das zum Debuggen solcher Änderungen erforderlich ist. Diese Hinweise beschreiben die gebündelte Drittanbieterkomponente; Sie erheben nicht den Anspruch, die Quelle der Anwendung erneut zu lizenzieren.

## Neu kompilieren

Anforderungen: macOS, Xcode-Befehlszeilentools, das enthaltene Quellarchiv und standardmäßige macOS-Build-Tools. Es werden keine Homebrew-Bibliotheken verwendet. Aus dem LumaView-Quellverzeichnis:

```sh
./tools/build-document-tools.sh
./build.sh
```

Das Skript überprüft das Quellarchiv, erstellt Intel- und Apple Silicon-Slices aus separaten Quellverzeichnissen, entfernt lokale Symbole und kombiniert die Slices zu `Resources/DocumentTools/gs`. Beide Slices zielen auf macOS 13.0 oder höher ab. Es führt weder `make install` noch schreibt es in einen Systempaketmanager. `LUMAVIEW_DOCUMENT_BUILD` wählt das Zwischen-Build-Verzeichnis aus; `LUMAVIEW_DOCUMENT_JOBS` steuert die Parallelität von make (Standard 4). Das optionale Argument `x86_64` oder `arm64` erstellt nur eine Architektur. Der Anwendungsbuild signiert die kopierte ausführbare Datei zusammen mit der App.

Die ausführbare Datei enthält Initialisierungscode, gebündelte Schriftarten, Adobe CMaps und ICC-Profile in ihrem internen `%rom%`-Dateisystem. Externe Standardsuchpfade sind leer. Nur das Ausgabegerät `pdfwrite` ist aktiviert. Drucken/CUPS, X11, GTK, Fontconfig, D-Bus, Tesseract/OCR, dynamische Treiber, externes IJS und Tools zur Dokumentenextraktion sind deaktiviert. Alle enthaltenen Decoder-/Farb-/Schriftartenbibliotheken werden aus dem entsprechenden Quellarchiv kompiliert; Die dynamische Verknüpfung ist auf Apple-Systembibliotheken beschränkt. Weitere Informationen zum ROM-Dateisystem und den Cross-Compilation-Mechanismen finden Sie in der [offiziellen Build-Dokumentation](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html).

LumaView führt den Interpreter mit `-dSAFER`, einer bestimmten Eingabe- und Ausgabedatei, einem privaten temporären Arbeitsverzeichnis, einem Abbruch und einem Timeout aus. Die Prozessumgebung darf keine vom Benutzer angegebenen Ghostscript-Optionen oder Bibliothekspfade erben. Beispiel für generierte vertrauenswürdige Testvorrichtungen:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

Die vollständigen Build-Optionen finden Sie in `tools/build-document-tools.sh`; Das Quellarchiv ist nicht gepatcht. Die native Ausführung kann nur für Architekturen getestet werden, die vom Build-Host unterstützt werden. Die Release-Prüfungen prüfen beide Mach-O-Slices und führen ein generiertes EPS mit Pfaden und Text durch das hostkompatible Slice aus. Dabei wird bestätigt, dass die Ausgabe PDF weiterhin Vektorzeichnungs- und Textoperatoren enthält.
