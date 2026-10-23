# LumaView 1.7.2 Validierungsbericht

<!-- doc-navigation:start -->
[Dokumentation](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · [繁體中文](../zh-Hant/TEST-RESULTS.md) · [English](../en/TEST-RESULTS.md) · [日本語](../ja/TEST-RESULTS.md) · [한국어](../ko/TEST-RESULTS.md) · [Français](../fr/TEST-RESULTS.md) · **Deutsch** · [Español](../es/TEST-RESULTS.md) · [Italiano](../it/TEST-RESULTS.md) · [Português (Brasil)](../pt-BR/TEST-RESULTS.md) · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · [Türkçe](../tr/TEST-RESULTS.md) · [Nederlands](../nl/TEST-RESULTS.md) · [Polski](../pl/TEST-RESULTS.md)
<!-- doc-navigation:end -->


Version 1.7.2, Build 14. Getestet auf 2026-10-22 mit macOS 15.7.9 / Intel. Die App und die gebündelten Tools wurden als universelle arm64 + x86_64-Binärdateien mit lokalen Signaturen überprüft. Diese Runde lief nicht auf Apple Silicon-Hardware.

## In dieser Version behoben

Rasterbilder zeigen jetzt konsistent transparente Bereiche: PNG / GIF / PSD / PSB und andere zeichnen kein grau-weißes Schachbrett oder einen rechteckigen Leinwandrand mehr. Anzeigeschatten ergeben sich aus dem tatsächlich zusammengesetzten Alpha des aktuellen Bildes und nicht aus der gesamten Bildfläche. Transparente Ränder haben daher keinen zusätzlichen rechteckigen Schatten; Löcher, separate weiche Masken und durchscheinende Bereiche tragen zum eigentlichen Umriss bei.

Die alte Implementierung betrachtete beim Hinzufügen des Schachbrettmusters nur CGImage.alphaInfo, es fehlten PSB-Dateien mit einer separaten Quartz-Maske. Außerdem wurde bei jedem Zoom ein rechteckiger shadowPath erzwungen, und der Rand selbst erzeugte einen rechteckigen Schatten. Diese rechteckigen Quellen wurden für Rasterbilder entfernt; Ebenenschatten folgen jetzt automatisch dem zusammengesetzten Alpha. Die Exportzeichnung wirft ebenfalls einen Schatten vom Bild selbst, ohne zuvor ein Rechteck zu füllen. GIF / APNG Frame-Änderungen ersetzen die aktuelle Textur und aktualisieren den Schatten, ohne die transparenten Pixel jedes Frames zu scannen oder ein vollständiges zusätzliches RGBA-Bild zu erstellen.

Dokumentseiten behalten ihr weißes Papier und Videooberflächen behalten ihr bestehendes Rechteck. Beim Kopieren von Bildern werden weiterhin die Originalbildpixel ohne Viewer-Hintergrund, Schachbrettmuster oder Anzeigeschatten verwendet. Der PSB-Decoder, der Thumbnail-Planer und der Schnellvorschaupfad der vorherigen Version wurden nicht geändert.

## Validierung dieser Testrunde

| Prüfung | Bestanden |
| --- | --- |
| Transparenz, Umrissschatten und Bildwechsel | 133 / 133 |
| Leinwandgeometrie, Animation und Maus | 66 / 66 |
| Dokumentanalyse und vollständige Seitenwiedergabe | 56 / 56 |
| Installierte Release-App: Dokumente, EPS/PS-Zoom, Seitennavigation und Fokus | 75 / 75 |
| Installierte Release-App: Kontextmenüs und Kopieren | 28 / 28 |
| Insgesamt | 358 / 358 |

Bei Transparenztests wurden eine Grafik mit einem Loch, unregelmäßigen Vorsprüngen und großen transparenten Rändern verwendet, die separat als RGBA codiert wurde, eine separate Quartz-Maske und tatsächliche PNG-, GIF-, PSD- und PSB-Dateien, die codiert und decodiert wurden. CALayer Compositing und exportierte Pixel aus `draw` wurden überprüft, um zu prüfen, dass transparente Ränder keine rechteckige Grundfläche oder Schatten besitzen, die inneren und äußeren Bildkonturen dagegen Schatten werfen. Vollständig transparente Bilder, Bildwechsel, Drehung und Zoom, schnelles Umschalten und ein durchscheinender Betrachterhintergrund wurden ebenfalls abgedeckt. Exportierte PNGs wurden visuell überprüft.

Für diese sechs Eingaben waren der PNG SHA-256 des CALayer-Exports und der PNG `draw`-Export identisch: `578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`. Testmedien wurden per Code generiert; Der Quelle wurden keine persönlichen Fotos hinzugefügt.

Eine begrenzte Software-Rendering-Sonde verglich außerdem die neuen und alten Schatten bei „An Fenster anpassen“, 100 % und 3200 % auf einer 32 MP-Bitmap mit logischen Leinwänden von 16,384 × 7,812 und 300,000 × 128. Der maximale Testprozess-RSS betrug etwa 428 MiB; Alte und neue Renderzeiten waren ähnlich. Dabei werden Software-Snapshots über `CALayer.render(in:)` gemessen, nicht GPU-Frameraten. Infolgedessen wurde kein Layer-Raster-Cache hinzugefügt.

Die vollständigen Dateilisten und Hashes der installierten Release-App und von `outputs/LumaView.app` stimmen überein; beide haben `codesign --verify --deep --strict` bestanden. Die vorherige ZIP-Datei wurde vor der Installation gesichert. Standard-Dateizuordnungen wurden vorher und nachher zurückgelesen. Es folgten CRC- und Versionsprüfungen der gelieferten ZIP-Datei. Historische Berichte verbleiben in `Tests/Release-1.7.0.md` und `Tests/Release-1.7.1.md`; Prüfungen, die aus diesen Veröffentlichungen nicht erneut ausgeführt werden, werden in dieser Runde nicht gezählt.

Hauptausführbare Datei SHA-256: `b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`.

## Protokollquellen

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
