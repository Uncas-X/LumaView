# LumaView — Deutsch

<!-- language-navigation:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · **Deutsch** · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- language-navigation:end -->

Diese Kurzanleitung beschreibt **LumaView 1.7.2 (Build 14)**. Die vollständige Dokumentation finden Sie auf [Englisch](README.en.md) und [Chinesisch](../../README.md).

LumaView ist ein nativer macOS-Betrachter für Bilder, Videos, Audio und mehrseitige Dokumente. Die schnelle Navigation orientiert sich am Bedienkonzept von Picasa Photo Viewer. Die App hat einen eigenen Namen und ein eigenes Symbol und steht in keiner Verbindung zu Google. Im Mittelpunkt steht das Betrachten von Dateien.

## Download und Installation

Laden Sie [LumaView für macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip) herunter oder öffnen Sie [alle Veröffentlichungen](https://github.com/Uncas-X/LumaView/releases). Die Universal-App unterstützt Intel und Apple Silicon und benötigt **macOS 13 oder neuer**.

Entpacken Sie die ZIP-Datei und ziehen Sie `LumaView.app` in den Ordner „Programme“. Die App verwendet eine lokale Ad-hoc-Signatur und ist nicht von Apple notarisiert. Falls macOS den Start blockiert, überprüfen Sie die Herkunft und folgen Sie den Hinweisen unter „Datenschutz & Sicherheit“, um das Öffnen zu erlauben.

## Erste Schritte

Ziehen Sie eine Datei oder einen Ordner in das Fenster oder verwenden Sie `Cmd+O`. Nach dem Öffnen einer einzelnen Datei können Sie durch benachbarte Medien im selben Ordner blättern. Es wird nur die aktuelle Ordnerebene eingelesen, ohne Unterordner.

- Miniaturansichten, Zoom, Verschieben, Drehen und Vollbild erleichtern das Betrachten. Übergänge sind animiert; der Hintergrund ist halbtransparent mit Milchglaseffekt.
- Transparente Bereiche von PNG-, GIF-, PSD- und PSB-Rasterbildern bleiben transparent. Schatten folgen dem Bildinhalt; Dokumentseiten erhalten einen weißen Papierhintergrund. PSD/PSB nutzen das gespeicherte Kompatibilitäts-Kompositbild, keine bearbeitbaren Ebenen.
- Video und Audio werden bevorzugt mit Systemfunktionen wiedergegeben. Bei Bedarf übernimmt das mitgelieferte FFmpeg die Kompatibilitätsverarbeitung. Audio zeigt das eingebettete Cover oder andernfalls eine Wellenform.
- PDF, PDF-kompatible AI und mehrseitige TIFF bieten Seitennavigation. SVG, unterstützte EPS/PS und ältere AI werden als Vektoren gerendert. EPS/PS verwenden das mitgelieferte Ghostscript; eingebettete Rasterbilder bleiben an ihre ursprüngliche Auflösung gebunden.
- Ein Rechtsklick bietet „Öffnen mit“, Anzeigen im Finder und Kopieren von Bildern, aktuellen Videobildern, PDF-Seiten oder unterstützten eingebetteten PDF-Bildern.
- Wiedergabe/Pause und Stopp für Medien sind von der Diashow getrennt. In den Einstellungen lassen sich Dateiformate mit LumaView verknüpfen und 16 Oberflächensprachen auswählen. Standardmäßig folgt die Sprache dem System.

## Tastaturbefehle

| Taste | Funktion |
|---|---|
| `Cmd+O` | Datei oder Ordner öffnen |
| `←` / `→` | Vorherige/nächste Datei oder Seite, abhängig vom Fokus |
| `↑` / `↓` | Bei mehrseitigen Dokumenten Seiten/Dateien fokussieren |
| Mausrad, Pinch-Geste, `+` / `-` | Vergrößern/verkleinern |
| `0`; `1` | An Fenster anpassen; zwischen 100 % und Anpassung wechseln |
| `Cmd+R`; `F` | Drehen; Vollbild |
| `P`; `S` | Medienwiedergabe/Pause; Stopp |
| `Cmd+4` | Diashow steuern |
| `Cmd+C` | Bild, aktuelles Videobild oder Seite kopieren |

**Die Leertaste wechselt den Hintergrund**, nicht die Wiedergabe. Bei mehrseitigen Dokumenten ist die aktuelle Auswahl in der fokussierten Reihe orange umrandet; in der anderen Reihe ist sie grau.

## Aus dem Quelltext bauen

Installieren Sie Xcode oder die Swift-Kommandozeilenwerkzeuge. Führen Sie im Stammverzeichnis des Repositorys aus:

```bash
./build.sh
open ../LumaView.app
```

`./build.sh --host` baut nur für die Architektur des aktuellen Macs. Zwischenprodukte liegen standardmäßig in `.build/`. `LUMAVIEW_WORK_ROOT` ändert dieses Verzeichnis, `LUMAVIEW_APP_PATH` den Ausgabepfad der App. Die Pfade beziehen sich auf das Stammverzeichnis des Repositorys, nicht auf dieses Dokument. Benötigte Medienwerkzeuge sowie zugehörige Quelltext- und Lizenzarchive liegen bei.

## Grenzen und Datenschutz

LumaView liest lokale Dateien, lädt sie nicht in eine Cloud und verändert keine Originale. Bildbearbeitung, Ebenenbearbeitung, Fotobibliothek-Datenbank und Cloud-Synchronisierung sind nicht enthalten. Große Bilder können als verkleinerte Vorschau erscheinen; Zoomen stellt ausgelassene Details nicht wieder her. Manche Medien müssen vor der Wiedergabe vollständig lokal konvertiert werden. Das benötigt Zeit und Festplattencache. Nicht jeder Codec ist abgedeckt; DRM-geschützte, beschädigte oder nicht unterstützte Dateien lassen sich möglicherweise nicht öffnen.

Weitere Informationen: [Formatübersicht auf Chinesisch](../../FORMATS.md), [Drittanbieterhinweise](../../ThirdParty/README.md), [Ghostscript-Hinweise](../../ThirdParty/README-Ghostscript.md).
