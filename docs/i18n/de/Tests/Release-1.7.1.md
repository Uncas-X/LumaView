> Persönliche Beispieldateinamen in historischen Validierungsdatensätzen wurden anonymisiert. Testdaten und Ergebnisse bleiben unverändert.

<!-- doc-navigation:start -->
[Dokumentation](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · **Deutsch** · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# LumaView 1.7.1 Validierungsbericht

Version 1.7.1, Build 13. 2026-10-22, macOS 15.7.9 / Intel. Die App und drei gebündelte Tools haben die arm64 + x86_64 Architektur- und lokalen Signaturprüfungen bestanden; Diese Runde wurde nicht auf Apple Silicon-Hardware durchgeführt.

## Probleme lokalisiert und behoben

Die drei PSB-Dateien des Benutzers waren 8-Bit-RGB-Vierkanal-RLE-Dateien mit zusammengesetzter Transparenz und jeweils etwa 108–123 MiB. Der Großteil jeder Datei besteht aus Layer-Daten, die direkt übersprungen werden können; Die Hauptleinwände enthalten etwa 8.5–9.6 Megapixel.

1. Der alte zeilenweise Decoder rief FileHandle für jeden PackBits-Marker und -Wert auf, was zu vielen kleinen Lesevorgängen führte und dazu führte, dass die Warteschlangen für Hauptbilder und Miniaturansichten zu lange belegt waren. Es liest jetzt Blöcke von bis zu 64 KiB, wobei literal/run Status- und Grenzprüfungen über die Blöcke hinweg beibehalten werden. Lange no-op-Daten bleiben abbrechbar. ZIP kehrt die Vorhersage nur für Stichprobenzeilen um und validiert weiterhin den gesamten komprimierten Stream.
2. Alle drei Dateien verfügen über ein gültiges RGB-JPEG-Miniaturbild in der Ressource 1036. Der Filmstreifen bevorzugt es nun und überprüft Format, Abmessungen, Seitenverhältnis und komprimierte Länge; Das Hauptbild dekodiert immer das reale Komposit. Ungültige Vorschauen, ältere BGR-Ressourcen oder fehlende Vorschauen fallen auf das Komposit zurück.
3. Das System ImageIO lehnt einige kleine PSD-Komposite mit einem gültigen generischen RGB ICC ab. Der frühere Fallback lieferte daher leere Miniaturansichten. Es dekodiert nun Pixel separat und hängt dann das verifizierte Original ICC an, wenn sein Farbmodell und die Komponentenanzahl übereinstimmen, anstatt das Profil zu verwerfen. Der ICC der Originaldateien entspricht dem Systemstandard Generic RGB Profile. Regressionstestdateien wurden aus dem Systemprofil generiert; Benutzerfotos wurden der Quelle nicht hinzugefügt.
4. Die PSB-Hauptansicht verwendet geparste Header-Informationen wieder und vermeidet einen zusätzlichen ImageIO-Layer-Scan für Metadaten. Originalabmessungen, Transparenz und Hauptbildqualität bleiben erhalten.

## Tests an den drei Originaldateien

Hierbei handelt es sich um lokale Messungen auf diesem Mac, die von der Auslastung und dem Dateicache beeinflusst werden, und nicht um Leistungsgarantien für jedes Gerät. Sowohl alte als auch neue Decoder verwendeten eine optimierte Kompilierung.

| Datei | Originalmaße | Alte Hauptbilddekodierung | Neue Hauptbild-Dekodierung | Neue Dekodierung zusammengesetzter Miniaturansichten (ohne eingebettete Vorschau) |
| --- | --- | --- | --- | --- |
| Probe A | 2582 × 3318 | Test nach mehr als 15 Sekunden abgebrochen | 0.68 Sekunden | 0.039 Sekunden |
| Probe B | 2610 × 3307 | 14.35 Sekunden | 0.65 Sekunden | 0.028 Sekunden |
| Probe C | 2843 × 3361 | Test nach mehr als 15 Sekunden abgebrochen | 0.70 Sekunden | 0.028 Sekunden |

Das gleichzeitige Anfordern von drei Miniaturansichten über den echten ImageLoader war in etwa 0.06 Sekunden abgeschlossen. Für die vollständigen Hauptbilder benötigte der Loader etwa 0.90 / 0.65 / 0.74 Sekunden. Die alte Version meldete alle drei zusammengesetzten Miniaturansichten als unsupported; Die neue Version war bei allen dreien erfolgreich. Die SHA-256-Werte der Originale stimmten vor und nach dem Test Byte für Byte überein; Die App hat die Originaldateien nicht verändert.

## In dieser Testrunde bestandene Prüfungen

| Prüfung | Ergebnis |
| --- | --- |
| PSD / PSB Kodierung und transparenter Verbund | 712 / 712 |
| RLE-Leistung, eingebettete Vorschauen, ICC, Chunk-Grenzen, Abbruch | 54 / 54 |
| Echte ImageLoader-Integration für drei Original-PSBs | 21 / 21 |
| 443-Datei-Filmstreifen, Cache, ungültige Rückrufe | 37 / 37 |
| Unabhängige Thumbnail-Anfragen und Abbruch | 13 / 13 |
| Bildbibliothek und Systemdekodierung | 78 / 78 |
| Installiertes optimiertes Release-App-Kontextmenü und Kopieren | 28 / 28 |
| Insgesamt | 943 / 943 |

Neue Tests umfassen dichte Ein-Byte-Literale, 64 KiB-Grenzen, Abbruch während langer no-op-Sequenzen, Kürzungen und Daten außerhalb der Grenzen, deutlich korrekte Inhalte für eingebettete Miniaturansichten und Hauptbilder, ICC, Transparenz und kleine nicht ganzzahlige Zoomfaktoren. Die vorhandenen 112-Kodierungskombinationen und 128 Struktur-Testdateien mit Ebenen-Transparenzmarkierungen bestehen weiterhin alle Prüfungen. Filmstreifenprüfungen umfassen schnelles Umschalten, Abbruch außerhalb des Bildschirms und die Verhinderung, dass alte Rückrufe die aktuelle Liste verunreinigen.

Vollständige Dateilisten und Hashes der installierten App und `outputs/LumaView.app` stimmten überein und beide haben `codesign --verify --deep --strict` bestanden. Die alte ZIP-Datei wurde vor der Installation gesichert; Standardöffnungszuordnungen wurden nicht geändert. Die gelieferte ZIP-Datei wurde separat auf CRC und Version überprüft. Der historische vollständige 1.7.0-Bericht bleibt unter `Tests/Release-1.7.0.md`; Seine Prüfungen, die nicht wiederholt wurden, werden in dieser Runde nicht berücksichtigt.

Hauptausführbare Datei SHA-256: `cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`.

## Protokolle

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
