> Persönliche Beispieldateinamen in historischen Validierungsdatensätzen wurden anonymisiert. Testdaten und Ergebnisse bleiben unverändert.

<!-- doc-navigation:start -->
[Dokumentation](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · **Deutsch** · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# LumaView 1.7.0 Validierungsbericht

Datum: 2026-10-22 (Asia/Shanghai). Testumgebung: macOS 15.7.9, x86_64. Die App zielt auf macOS 13+ ab und alle vier ausführbaren Dateien sind universelle Intel/Apple Silicon-Binärdateien.

## In dieser Runde getestete Änderungen und Ergebnisse

- Das integrierte Ghostscript 10.08.0 wandelt direkt geöffnete EPS-, PostScript- und ältere PostScript-AI-Dateien im Hintergrund vollständig in PDF um. Vektorpfade, Text und eingebettete Bilder bleiben erhalten; das Ergebnis wird an die vorhandene Zeichenfläche übergeben. Benutzer benötigen weder einen separaten Interpreter noch eine manuelle Konvertierung; Zoomen, Schwenken, Drehen und mehrseitige Navigation folgen den aktuellen Interaktionen. Der eingebettete TIFF-Fallback wird weiterhin verwendet, wenn die Vektorkonvertierung fehlschlägt und die Datei eine Vorschau bietet. Raster-Fallback ist nicht als Vektor gekennzeichnet.
- Der Beispielanhang `sample-vector.eps` wurde mit seinem vollständigen PostScript-Inhalt getestet. Beim Scannen des generierten PDF wurden **147,521 Pfad-/Verlaufsoperationen, 59 Textoperationen und 160 XObject-Aufrufe** gefunden. XObjects werden hier als PDF `Do` Vorgänge gezählt und können Bilder oder Form-XObjects enthalten; Die Zahl ist keine Zählung unterschiedlicher Bilder. Tests bestätigten, dass echte Vektorinhalte erhalten blieben. SHA-256-Vergleiche des EPS und `sample-vector.svg` vor und nach dem Test zeigten unveränderte Originale.
- PostScript verwendet einen separaten abbrechbaren Prozess, Ghostscript SAFER, und eine Systemprozess-Sandbox. Die Eingabe wird in ein privates temporäres Verzeichnis kopiert; Der Interpreter kann keine anderen Benutzerdateien lesen, in beliebige externe Dateien schreiben oder externe Pipes verwenden. Zeitüberschreitung, Abbruch, Wiederverwendung durch mehrere Verbraucher, beschädigte Eingaben und Cache-Ungültigkeitsprüfungen bestanden. Abgeschlossene Ergebnisse werden atomar veröffentlicht, sodass Teil-PDFs keine Miniaturansichten füllen. Real-Viewer-Tests umfassten EPS bei 3200 % Vektorzoom, Auf-/Ab-Fokus und Links-/Rechts-Seitennavigation in mehrseitigem PS sowie den Wechsel zu PNG während der Konvertierung, ohne dass ein verspätetes Ergebnis die aktuelle Ansicht ersetzte.
- `.psb` wurde der Photoshop-Gruppe zusammen mit `.psd` für Erkennung, Hauptansicht, Miniaturansichten und Standardanwendungseinstellungen hinzugefügt. Eine gespeicherte Kompatibilitäts-Komposit wird gelesen und die ursprünglichen Leinwandabmessungen bleiben erhalten; Große Dateien erhalten je nach Anzeigebedarf eine begrenzte Vorschau. Die Validierung umfasste **112 Kodierungskombinationen, 128 Struktur-Testdateien mit Ebenen-Transparenzmarkierungen, 1 großes PSB und 13 beschädigte Testdateien**. Die Erkennung zusammengesetzter Transparenz verwendet die Ebenenanzahl und die Markierungen Lr16/Lr32, Mtrn/Mt16/Mt32. Gewöhnliche Extra-Alpha-Kanäle werden nicht mit zusammengesetzter Transparenz verwechselt. Die Tests umfassten transparente Pixelwerte, das Entfernen der weißen Hintergrundfarbe, die Kodierungskonsistenz, den Abbruch bei langen Zeilen und Regressionen bei der Haupt-/Miniaturansicht-Integration.
- Der Standard-Öffnungsdialog liest die tatsächlichen Systemzuordnungen beim Öffnen, bei der Reaktivierung der App und nach Abschluss der Batch-Einstellungen. Die Zuordnungen selbst bleiben über Neustarts hinweg bestehen; Nicht angewendete Entwürfe werden nicht als Erfolg angezeigt. Bei einem aktivierten Format ist jeder Typ dieser App zugewiesen. Ein Bindestrich weist auf teilweise Übereinstimmungen oder eine andere Kopie mit derselben Bundle-ID hin, wie im Tooltip erläutert. „Auswahl leeren“ ändert nur den Entwurf; Systemstandards werden dadurch nicht widerrufen.
- „Alle Formate auswählen“ oben wählt Bilder, Vektoren/Dokumente, Videos und Audio gleichzeitig aus, einschließlich Formaten außerhalb der Suchergebnisse. Zum Schreiben von Assoziationen muss weiterhin auf die Schaltfläche „Setzen“ geklickt werden. Erkennung, Teilerfolg, Fehlerrücklesung, Neuaufbau des Controllers, Unterschiede zwischen Entwurfs- und Ist-Zustand und Gesamtauswahl wurden mit einem In-Memory-Mock-Backend getestet. Durch Tests wurden die Systemstandardanwendungen des Benutzers nicht geändert.
- Neue Einstellungen, PostScript und Photoshop-Strings aus dieser Runde decken alle 16 Sprachen ab. Kerntext- und Formatplatzhalter haben die Validierung bestanden.

## Validierung dieser Testrunde

Es werden nur die unten aufgeführten Prüfungen mit vollständigen erfolgreichen Zusammenfassungen in den Protokollen dieser Runde gezählt; Historische Module, die nicht erneut ausgeführt wurden, sind ausgeschlossen.

| Prüfung | Bestanden |
| --- | --- |
| PostScript-Vektorkonvertierung, Abbruch, Isolierung und tatsächliches EPS | 24 / 24 |
| SVG / EPS-Kompatibilität und Überprüfung des Originalanhangs | 64 / 64 |
| PSD / PSB zusammengesetzte, transparente Kanäle, große Bilder und beschädigte Daten | 712 / 712 |
| Rücklesen des tatsächlichen Systems und Batch-Standardeinstellungen (Mock) | 101 / 101 |
| Standardformatdialog, Wiederöffnungsstatus und Auswahl aller Formate (Mock) | 34 / 34 |
| 16 Sprachen und Platzhalter | 174 / 174 |
| Formatdeklarationen der veröffentlichten App | 15 / 15 |
| Bildbibliothek und Systemdekodierung | 78 / 78 |
| Leinwandgeometrie, Animationen und Maus | 66 / 66 |
| Dokumentanalyse und vollständige Seitenzeichnung | 56 / 56 |
| Dokumentfokus, EPS/PS-Zoom und Paginierung, Abbruch bei Dateiänderung | 75 / 75 |
| Echtes Fensterklicken und Lebenszyklus | 65 / 65 |
| 443-Datei-Miniaturansichten, Cache und veraltete Rückrufe | 37 / 37 |
| Abbruch der Miniaturansichtsanfrage und Isolierung des Verbrauchers | 13 / 13 |
| Installiertes Release-App-Kontextmenü und private Zwischenablage | 28 / 28 |
| **Gesamt** | **1542 / 1542** |

Die installierte optimierte Release-App wurde 28 zusätzlichen Kontextmenüprüfungen über echte Menüs und target/action-Verteilung unterzogen, wobei eine separat benannte Zwischenablage verwendet wurde. Sie überprüften das Kopieren von Bildern, aktuellen Videobildern, PDF Bildern und ganzen Seiten, Drehung und veralteten Ergebnissen beim Wechseln/Schließen, ohne die Systemzwischenablage des Benutzers zu berühren. Bestehende Regressionsprüfungen für Mausklicks, Fensterlebenszyklus, Seitenfokus, vollständige Seitenpräsentation, Miniaturbild-Cache und Abbruch wurden alle bestanden.

## Release-Verzeichnis und Überprüfung der installierten App

Version **1.7.0, Build 12**. Vor dem Schreiben dieses Berichts wurden die Bundle-IDs, Versionen, Builds, vollständigen Dateilisten und SHA-256-Hashes von `outputs/LumaView.app` und `/Applications/LumaView.app` verglichen und als identisch befunden. Alle vier ausführbaren Dateien haben die Dual-Architecture-Inspektion bestanden, beide Apps haben `codesign --verify --deep --strict` bestanden, gebündeltes Ghostscript hat die Version 10.08.0 gemeldet, Lokalisierungs-/Versionsressourcen stimmten mit dem Quellbaum überein und der SHA-256 des Ghostscript-Quellarchivs stimmte mit der enthaltenen Prüfsummenliste überein. Der Interpreter wird während eines Builds neu signiert; Die neu signierte Binärdatei muss nicht Byte für Byte mit der noch nicht neu signierten Kopie im Quellverzeichnis übereinstimmen.

| Ausführbar | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

Dieser Bericht ersetzt keine nachfolgenden ZIP-Integritätsprüfungen und behauptet keine Notarisierung durch Apple. Die Signatur ist lokal und ad hoc. Die Cross-Kompilierung und Architekturprüfungen für Apple Silicon wurden abgeschlossen, diese Runde lief jedoch nicht auf Apple Silicon-Hardware. Das Ghostscript-Quellarchiv, die Lizenz und Anweisungen zum Neuaufbau liegen der Quellverteilung bei.

## Umfang und Grenzen

Bereits in EPS/PS eingebettete Bitmaps behalten ihre Quellauflösungsgrenzen; Externe Schriftarten oder Dateiressourcen sowie ungewöhnliches oder beschädigtes PostScript werden möglicherweise nicht vollständig konvertiert. PSD / PSB Vorschauen hängen von gespeicherten Kompatibilitätskompositionen ab und bearbeiten keine Photoshop-Ebenen oder rekonstruieren fehlende Komposits; Bei Abwesenheit empfiehlt die App, „Kompatibilität maximieren“ zu aktivieren und erneut zu speichern. Die Originalabmessungen der Leinwand können die angezeigte Vorschaugröße überschreiten. Eine begrenzte Vorschau wird nicht so dargestellt, als ob jedes Quellpixel dekodiert worden wäre. Weitere Formatbeschränkungen finden Sie unter [FORMATS.md](../FORMATS.md).

## Protokollquellen für diese Runde

Die folgenden Dateien wurden nach `Tests/` kopiert. Historische Berichte, die nicht wiederholt werden, bleiben bestehen, werden jedoch von der Gesamtzahl dieser Runde ausgeschlossen:

- `PostScript-test-results.txt` ← `work/postscript-17/postscript-test-results.txt`
- `vector-compatibility-test-results.txt` ← `work/vector-compatibility-1.7.0/vector-compatibility-test-results.txt`
- `Photoshop-test-results.txt` ← `work/psb-support/results.txt`
- `Default-application-test-results.txt` ← `work/default-application-1.7-results.txt`
- `Default-preferences-test-results.txt` ← `work/default-preferences-tests/default-preferences-test-results.txt`
- `Localization-test-results.txt` ← `work/localization-1.7-results.txt`
- `Media-declaration-test-results.txt` ← `work/media-declaration-1.7.0.txt`
- `Core-test-results.txt` ← `work/core-1.7.0-run.log`
- `Canvas-test-results.txt` ← `work/canvas-1.7.0-run.log`
- `Document-core-test-results.txt` ← `work/document-1.7.0/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-1.7.0/document-test-results.txt`
- `UI-test-results.txt` ← `work/ui-1.7.0/ui-test-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.0/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.0-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.0/context-menu-test-results.txt`
