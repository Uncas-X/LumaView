# LumaView 1.7.2

<!-- doc-navigation:start -->
[Dokumentation](../i18n/de/INDEX.md) · [简体中文](../i18n/zh-Hans/README.md) · [繁體中文](../i18n/zh-Hant/README.md) · [English](../i18n/en/README.md) · [日本語](../i18n/ja/README.md) · [한국어](../i18n/ko/README.md) · [Français](../i18n/fr/README.md) · **Deutsch** · [Español](../i18n/es/README.md) · [Italiano](../i18n/it/README.md) · [Português (Brasil)](../i18n/pt-BR/README.md) · [Русский](../i18n/ru/README.md) · [العربية](../i18n/ar/README.md) · [हिन्दी](../i18n/hi/README.md) · [Türkçe](../i18n/tr/README.md) · [Nederlands](../i18n/nl/README.md) · [Polski](../i18n/pl/README.md)
<!-- doc-navigation:end -->


**[Laden Sie die macOS-App herunter](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)** · [Versionen und Versionshinweise](https://github.com/Uncas-X/LumaView/releases)

Erfordert macOS 13+. Das gleiche Paket unterstützt Intel und Apple Silicon. Extrahieren Sie die heruntergeladene ZIP-Datei und ziehen Sie `LumaView.app` in „Programme“, um sie zu installieren.

Ein nativer macOS-Medienbetrachter, der von den Schnellansichtsgewohnheiten des Picasa Photo Viewer inspiriert ist und das Durchsuchen, Zoomen, Schwenken, Drehen, einen Filmstreifen, Vollbild und Diashows im gleichen Ordner ermöglicht. Version 1.5 fügte Audio-Cover und echte Wellenformen, mehrseitige Dokumentnavigation, eine mit dem aktuellen Zoom neu gezeichnete Vektor-Leinwand und Spracheinstellungen hinzu, die standardmäßig dem System folgen. Es verwendet einen unabhängigen Namen und ein Originalsymbol und erhebt nicht den Anspruch, alle Funktionen oder Interaktionen historischer Picasa-Versionen zu reproduzieren.

Version 1.7.2 vereinheitlicht die Bildtransparenz: Transparente Bereiche von Rasterbildern wie PNG, GIF und PSD / PSB zeigen den aktuellen Betrachtungshintergrund. Schatten folgen dem tatsächlichen Bildumriss und der Deckkraft; Es gibt kein Schachbrettmuster oder einen rechteckigen Schatten um die gesamte transparente Leinwand herum. Dokumente wie PDF behalten einen weißen Papierhintergrund.

Die Vorschauverbesserungen von PSD / PSB gegenüber 1.7.1 bleiben bestehen: Der Filmstreifen bevorzugt ein gültiges eingebettetes JPEG, während die Hauptansicht das tatsächliche Kompatibilitäts-Komposit dekodiert. RLE verwendet blockweise Lesezugriffe und ein Problem, das die Erstellung von Miniaturansichten für einige kleine Composites mit ICC-Profilen verhinderte, wurde behoben.

## Verwendung und Installation

Erfordert macOS 13 oder höher, mit Unterstützung für Intel und Apple Silicon.

1. Laden Sie `LumaView-macOS.zip` von [Releases](https://github.com/Uncas-X/LumaView/releases) herunter, extrahieren Sie es, ziehen Sie `LumaView.app` in „Programme“ und öffnen Sie es.
2. Legen Sie ein Bild, ein Video, eine Audiodatei oder einen Ordner in der App ab oder drücken Sie `⌘O`, um Dateien auszuwählen. Beim Öffnen einer Datei werden Medien im selben Ordner aufgelistet. Wenn Sie mehrere Dateien auswählen, wird diese Auswahl durchsucht. Ordnerscans decken nur die aktuelle Ebene ab und führen keine Rekursion in Unterordner durch.
3. Im Finder können Sie auch mit der rechten Maustaste auf eine Datei klicken und Öffnen mit → LumaView wählen.

Lokale Builds verwenden eine Ad-hoc-Signatur und wurden nicht von Apple notarisiert. Wenn Gatekeeper eine heruntergeladene Kopie auf einem anderen Mac blockiert, überprüfen Sie deren Quelle und verwenden Sie die Option „Datenschutz und Sicherheit“ des Systems, um das Öffnen zu ermöglichen.

## Standardanwendungseinstellungen

Wählen Sie **LumaView → Standardanwendung…**, drücken Sie `⌘,` oder öffnen Sie die Einstellungen im Menü „Mehr“. Die Formate sind in Bilder, Vektoren/Dokumente, Video und Audio gruppiert. Suchen und wählen Sie Formate aus und klicken Sie dann auf Als Standard für ausgewählte Formate festlegen. Immer wenn das Dialogfeld geöffnet wird, die App wieder aktiv wird oder Änderungen abgeschlossen werden, werden die tatsächlichen Systemzuordnungen gelesen: Ein Häkchen bedeutet, dass jeder Typ in der Gruppe mit dieser Kopie von LumaView geöffnet wird. Ein Bindestrich bedeutet, dass dies nur bei einigen Typen der Fall ist oder dass sie immer noch auf eine andere Kopie verweisen. Systemzuordnungen bleiben über Neustarts hinweg bestehen; Nicht angewendete Auswahlen werden nicht als erfolgreich angewendete Einstellungen angezeigt. Die Option „Alle Formate auswählen“ oben deckt alle Bilder, Vektordokumente, Videos und Audiodaten ab, unabhängig vom Suchfilter. Einzelne Kategorien können weiterhin separat ausgewählt werden. „Löschen“ löscht nur die aktuelle Auswahl und entfernt keine vorhandenen Systemstandards.

Die Einstellungen zeigen den Fortschritt an und lesen jedes Ergebnis vom System zurück. Abbrechen stoppt nachfolgende Änderungen; abgeschlossene Änderungen bleiben erhalten. Die Formatliste stellt auswählbare Dateizuordnungen dar und stellt keinen Anspruch darauf dar, dass jede interne Codierung oder Datei getestet wurde. Weitere Informationen finden Sie unter [Formate und Vorschauen](../i18n/de/FORMATS.md).

## Ansehen und Wiedergeben

Durch Öffnen der ersten Datei wird das Fenster auf den verfügbaren Bereich des aktuellen Bildschirms erweitert. Drücken Sie `F` für den Vollbildmodus. Klicken Sie auf den unteren Filmstreifen, um Dateien zu ändern. Die Steuerelemente werden ausgeblendet, nachdem der Zeiger eine Weile im Anzeigebereich verweilt, und werden wieder angezeigt, wenn er sich bewegt.

In Version 1.5.2 wurden leere oder wiederholt blinkende Miniaturansichten beim längeren Durchsuchen großer Ordner behoben: Sichtbare Miniaturansichten bleiben unabhängig voneinander erhalten und das Laden außerhalb des Bildschirms wird sofort abgebrochen. Ergebnisse aus dem vorherigen Ordner können nicht in die neue Liste aufgenommen werden. Nicht dekodierbare Dateien zeigen einen stabilen Platzhalter an und können erneut versucht werden, wenn ihr Bereich erneut aufgerufen wird.

Bilder und Videos unterstützen Zoom, Schwenken, Drehen und Vollbild. Fensterwechsel, Bildwechsel, Zoomen und Drehen nutzen kurze, fließende Übergänge, die durch weitere Eingaben unterbrochen werden können. Durch Aktivieren der Systemeinstellung „Bewegung reduzieren“ werden diese benutzerdefinierten Übergänge deaktiviert, während animierte Bilder weiterhin abgespielt werden. Der Standardhintergrund ist durchscheinendes Milchglas; Drücken Sie die Leertaste, um zwischen mattierten, dunklen und hellen Hintergründen zu wechseln.

Rastertransparenz folgt einer Regel: Zeigt den aktuellen Hintergrund und wirft Schatten nur von Pixeln mit sichtbarem Inhalt, wobei die Deckkraft durchscheinender Kanten erhalten bleibt. GIF / APNG Schatten ändern sich mit jedem Frame. Beim Kopieren eines Bildes bleiben die ursprünglichen transparenten Pixel erhalten und der Hintergrund und Schatten des Betrachters werden ausgeschlossen.

Die Steuerelemente für Audio-/Videowiedergabe, Stopp, Position und Lautstärke werden über dem Filmstreifen angezeigt. Medien werden beim Öffnen automatisch abgespielt und bleiben am Ende stehen, wenn sie fertig sind. Drücken Sie `P` zum Wiederholen oder `S` zum Stoppen und Zurückkehren zum Anfang. Die Diashow-Schaltfläche unten ist unabhängig von der Medienwiedergabe: Nachdem `⌘4` mit der kontinuierlichen Wiedergabe begonnen hat, werden die Bilder im ausgewählten Intervall weitergeschaltet, während Audio/Video vor dem Weiterschalten vollständig abgespielt wird. Das Abspielen einer einzelnen Audio-/Videodatei führt nicht automatisch zum nächsten Element.

Zuerst wird die native macOS-Wiedergabe ausprobiert. Wenn das System die Datei nicht direkt abspielen kann, bereiten die gebündelten Universaldateien FFmpeg 9.0.2 und dav1d 1.5.3 lokal eine kompatible Datei vor, indem sie gegebenenfalls zunächst einen Containerwechsel und dann eine Transkodierung versuchen. Es ist kein separater Player, Homebrew oder Codec-Paket erforderlich und es wird kein Netzwerkzugriff verwendet. Bei der Kompatibilitätswiedergabe wird darauf gewartet, dass die gesamte Datei vorbereitet wird, und der Fortschritt wird angezeigt. Durch das Ändern von Dateien oder das Schließen des Fensters wird die Vorbereitung abgebrochen. Das erstmalige Vorbereiten eines langen Videos kann viel Zeit und zusätzlichen Speicherplatz in Anspruch nehmen.

Drücken Sie `C` oder verwenden Sie das Menü „Mehr“, um die Schleife, das Radverhalten, das Schließen bei Hintergrundklick, den Filmstreifen, die Sortierung und die Diashow-Intervalle (2, 3, 5, 8 oder 10 Sekunden) zu konfigurieren. Das Rad zoomt standardmäßig; Halten Sie `Ctrl` gedrückt, um Dateien vorübergehend zu durchsuchen. Wenn das Rad auf Durchsuchen eingestellt ist, zoomt stattdessen vorübergehend `Ctrl`. Durch Klicken auf den Hintergrund außerhalb des Bildes wird der Viewer standardmäßig geschlossen. Diese Präferenzen werden lokal gespeichert.

## Kontextmenü und Kopieren

Klicken Sie mit der rechten Maustaste (oder bei gedrückter Ctrl-Taste) auf die Hauptansicht, um „Öffnen mit“ → „Anwendung“ / „Andere Anwendung“ oder „Im Finder anzeigen“ auszuwählen. „Öffnen mit“ wirkt sich nur auf diese Öffnung aus und ändert nicht die Standardzuordnungen. Für nicht dekodierbare Dateien bleiben beide Optionen verfügbar.

- Bilder: Wählen Sie „Bild kopieren“. Dadurch bleiben die Ansichtsdrehung und die transparenten Pixel erhalten und das gesamte aktuell dekodierte Bild wird kopiert, ohne dass Symbolleisten oder nur der vergrößerte Bildschirmbereich erfasst werden.
- Video: Wählen Sie „Aktuellen Frame kopieren“. Dadurch wird das Bild kopiert, das dem Moment entspricht, in dem das Kontextmenü geöffnet wurde, wobei die Videoausrichtung und Ansichtsdrehung beibehalten wird, ohne dass sich die Wiedergabeposition oder der Wiedergabestatus ändert.
- PDF / PDF-kompatibles AI: Klicken Sie mit der rechten Maustaste auf eine Bitmap auf einer Seite, um dieses Bild zu kopieren, oder wählen Sie „Aktuelle Seite kopieren“. Die Treffererkennung folgt der tatsächlichen Position nach dem Zoomen, Schwenken und Drehen. Gewöhnlicher Text und Vektorbereiche werden nicht als Bilder behandelt; Komplexe Masken oder Farbräume nutzen das sichtbare Ergebnis des Bildbereichs, der überlagerten Text enthalten kann. Eine als einzelnes Bild gescannte Seite wird als gesamter Scan kopiert.
- `⌘C` kopiert das aktuelle Bild, Videobild oder die aktuelle Dokumentseite; Audio bietet kein Kopieren von Bildern. Die Zwischenablage empfängt PNG und TIFF. Das Ändern von Dateien/Seiten oder das Schließen des Viewers verhindert, dass veraltete Kopierergebnisse die Zwischenablage überschreiben.

Kopien von Dokumentseiten und eingebetteten Bildern sind Bitmaps, die auf eine längste Seite von 8192 Pixeln und etwa 32 Millionen Pixel beschränkt sind; PDF/SVG Vektoranweisungen werden nicht in der Zwischenablage abgelegt. Wenn bei einem großen Bild eine begrenzte Vorschau angezeigt wird, wird diese Vorschau kopiert. Das Analysieren von PDF-Bildern weist Komplexitätsgrenzen auf: Spezielle Strukturen wie Bilder innerhalb von Musterfüllungen sind möglicherweise nicht einzeln auswählbar, die aktuelle Seite kann jedoch trotzdem kopiert werden.

Standard-Header SVG 1.0/1.1 werden offline analysiert, ohne dass externe DTDs geladen werden. Version 1.7 bündelt Ghostscript 10.08.0, um EPS/PostScript und älteres PostScript AI in PDF zu konvertieren und dabei Pfade, Text und eingebettete Bilder beizubehalten. In der Hauptansicht werden Vektoren im aktuellen Zoom neu gezeichnet. Mehrseitiges PS nutzt die vorhandene Seitennavigation. Es ist keine zusätzliche Installation erforderlich. Wenn die Konvertierung fehlschlägt, das EPS jedoch über eine gültige eingebettete TIFF-Datei verfügt, kann auf diese Vorschau zurückgegriffen werden, die deutlich als TIFF gekennzeichnet ist. Rasterbilder im Original werden nicht zu Vektoren.

## Audio, Dokumente und Sprachen

Audio zeigt eingebettete Cover in der Hauptansicht, sofern verfügbar. Andernfalls werden tatsächliche Samples asynchron analysiert, um eine Wellenform für die gesamte Spur anzuzeigen. Während der Analyse wird ein Platzhalter angezeigt und die Wiedergabe muss nicht warten. Audio- und Video-Miniaturansichten verwenden unten rechts das gleiche `▶ Dauer`-Logo mit übereinstimmender Schriftart, Hintergrund und Position. Bevor die Dauer verfügbar ist, wird `▶ –:––` angezeigt. Das Cover stammt aus eingebetteten Dateimetadaten, ohne dass das Netzwerk oder benachbarte Dateien durchsucht werden müssen.

PDF, PDF-kompatibles AI und mehrseitiges TIFF unterstützen das Durchsuchen von Seiten. Oberhalb des Dateifilmstreifens werden kleinere Miniaturansichten der Seiten, ein Schieberegler für den Seitenfortschritt und die aktuelle/gesamte Seitenzahl angezeigt. Drücken Sie `↑`, um Seiten zu fokussieren, und `↓`, um Dateien zu fokussieren. Das ausgewählte Miniaturbild in der fokussierten Zeile hat einen orangefarbenen Rand; Die andere Zeile behält ihre Auswahl mit einem grauen Rand. Es werden keine zusätzlichen Seiten-/Dateibezeichnungen angezeigt. `←` / `→`, `J` / `K` und `Home` / `End` wirken sich auf den aktuellen Fokus aus. Wenn Sie auf eine Zeile klicken, wird diese ebenfalls fokussiert. Die Seitennavigation stoppt auf der ersten und letzten Seite, ohne dass unerwartet zu einer anderen Datei gewechselt wird. Mit den unteren Schaltflächen „Vorherige/nächste Datei“ wechseln Sie immer zwischen Dateien. Die Seitennavigation bleibt verfügbar, wenn der Dateifilmstreifen ausgeblendet ist.

PDF, SVG und PDF-kompatibles AI zeichnen den sichtbaren Bereich aus Originalvektoranweisungen im aktuellen Zoom, anstatt eine feste Vorschau zu vergrößern. Transparente Dokumentbereiche verwenden einfaches weißes Papier ohne Schachbrettmuster. Beim Seitenwechsel wird die vollständige neue Seite vorbereitet und anschließend als Ganzes sanft eingeblendet. Beim Zeichnen mit Vektordetails im Hintergrund werden keine leeren Kacheln einzeln angezeigt. Eingebettete Fotos und andere Bitmaps bleiben durch ihre ursprüngliche Auflösung begrenzt.

Wählen Sie **LumaView → Sprache…**, auch im Menü „Mehr“ verfügbar. Die Standardeinstellung folgt dem System und unterstützt vereinfachtes Chinesisch, traditionelles Chinesisch, Englisch, Japanisch, Koreanisch, Französisch, Deutsch, Spanisch, Italienisch, Portugiesisch, Russisch, Arabisch, Hindi, Türkisch, Niederländisch und Polnisch. App-Menüs, Tooltips, Paginierung und Einstellungen werden sofort aktualisiert und die ausgewählte Sprache wird lokal gespeichert. Nicht unterstützte Systemsprachen greifen auf Englisch zurück; Ungewöhnliche Dekodierungsfehler können auch auf Englisch auftreten. Dateinamen, Pfade und Text in Dateien bleiben unverändert.

## Tastatur und Maus

| Aktion | Tastenkürzel / Geste |
| --- | --- |
| Vorheriges/nächstes Element (aktueller Fokus) | `←` / `→` oder `J` / `K` |
| Fokus auf Seiten / Dateien | `↑` / `↓` (mehrseitige Dokumente) |
| Erstes / letztes Element | `Home` / `End` |
| Öffnen Sie Dateien oder einen Ordner | `⌘O` |
| Standardanwendungseinstellungen | `⌘,` |
| Zoomen | Rad, Zwei-Finger-Zoom auf dem Trackpad, `+` / `−`, `Page Up` / `Page Down` |
| Radverhalten vorübergehend ändern | Halten Sie beim Scrollen `Ctrl` gedrückt |
| 100% / An Fenster anpassen | Klicken Sie auf das Bild oder `1` |
| An Fenster anpassen | `0` |
| Schwenken Sie ein gezoomtes Bild oder Video | Ziehen Sie die Ansicht |
| Ansicht im Uhrzeigersinn drehen | `⌘R` / `Ctrl+R`; Fügen Sie `Shift` für gegen den Uhrzeigersinn hinzu |
| Hintergrund wechseln | Leertaste |
| Vollbild betreten/verlassen | `F` / `⌃⌘F` / `F11` (sofern nicht vom System reserviert) |
| Audio oder Video abspielen/pausieren | `P` |
| Stoppen Sie die Medien und kehren Sie zum Start zurück | `S` |
| Diashow und kontinuierliche Wiedergabe starten/stoppen | `⌘4` |
| Im Medium 5 Sekunden zurück- / vorspringen | `Option + ←` / `Option + →` |
| Stummschalten/Stummschaltung aufheben | `M` |
| Dateiinformationen | `I` / `⌘I` |
| Filmstreifen ein-/ausblenden | `T` / `⌘T` |
| Weitere Optionen | `C` |
| Zeigt die aktuelle Datei im Finder an | `⌘Return` |
| Wiedergabe anhalten, Informationen schließen, Vollbild beenden, Fenster schließen | `Esc`, in der Reihenfolge entsprechend dem aktuellen Status behandelt |
| Minimieren / Schließen / Beenden | `⌘M` / `⌘W` / `⌘Q` |

`P` steuert nur das aktuelle Audio/Video, keine Bild-Diashows. Hilfe → Tastatur und Maus bietet auch eine In-App-Anleitung.

## Abdeckung und Einschränkungen

- Bilder verwenden die System-ImageIO-Dekodierung. Die tatsächliche Unterstützung für JPEG, PNG, GIF, HEIC, TIFF, BMP, WebP, RAW und andere Formate hängt von der Systemversion und dem Dateiinhalt ab.
- Sehr große Bilder werden nicht mehr allein deshalb abgelehnt, weil sie 150 Megapixel überschreiten. Um den Speicher zu begrenzen, werden die Vorschauen unter Beibehaltung der Originalabmessungen und Ausrichtungsmetadaten möglicherweise verkleinert. Der 100%-Zoom wird immer noch anhand der Originalabmessungen berechnet, es können jedoch keine Pixeldetails wiederhergestellt werden, die bei der Vorschaudekodierung ausgelassen wurden.
- Die Vektoranzeige unterstützt SVG, PDF, PDF-kompatibles AI und EPS/PS/Legacy AI, die vom mitgelieferten Interpreter verarbeitet werden. Mehrseitige PDF- / AI- / PS-Dateien unterstützen die Seitennavigation; SVG lehnt Skripte und externe Ressourcen ab. Eingebettete Bitmaps behalten ihre ursprünglichen Auflösungsgrenzen und nicht verfügbare, nicht eingebettete Schriftarten können ersetzt werden.
- PostScript wird in einem separaten Prozess mit SAFER und einer System-Sandbox ausgeführt, die nur die bereitgestellten temporären Ein- und Ausgabedateien zulässt und den Netzwerkzugriff verweigert. Ein schneller Dateiwechsel kann den Vorgang abbrechen; Miniaturansichten und die Hauptansicht teilen abgeschlossene zwischengespeicherte Ergebnisse. Jede Interpretation ist auf 90 Sekunden und 1 GB Ausgabe begrenzt, mit einem Cache-Bereinigungsziel von 2 GB.
- Photoshop PSD / PSB zeigt das in der Datei gespeicherte Komposit ohne Ebenenbearbeitung an. Bei sehr großen Leinwänden werden Vorschauen mit begrenztem Speicherbudget verwendet und die Originalabmessungen beibehalten. Informationen zu unterstützten Farbmodi, Bittiefen und Komprimierung finden Sie unter FORMATS.md.
- Die gebündelte Fallback-Dekodierung erweitert die Audio-/Videoabdeckung, DRM, beschädigte Dateien und proprietäre Kodierungen ohne verfügbaren Decoder können jedoch trotzdem fehlschlagen. Eine Erweiterung garantiert nicht, dass die interne Kodierung dekodiert werden kann. Nicht jedes Format, Gerät oder Systemversion wurde einzeln getestet.
- Der Kompatibilitätscache hat ein Bereinigungsziel von 2 GB; Gerade verwendete Dateien können den Cache vorübergehend über dieses Ziel wachsen lassen. Eine einzelne vorbereitete Datei ist auf 8 GB begrenzt, wobei mindestens 512 MB freier Speicherplatz reserviert ist. Die Vorbereitung stoppt und zeigt eine Meldung an, wenn der Platz nicht ausreicht.
- TIFF unterstützt mehrere Seiten; Andere zusammengesetzte Bildformate ohne implementierte Paginierung zeigen das erste Bild. Durch die Anzeigerotation wird niemals auf die Originale zurückgeschrieben. Bearbeiten, Löschen, eine Bibliotheksdatenbank, Freigabe, Cloud-Synchronisierung und externe Untertitelverwaltung sind nicht vorgesehen.
- Die App liest nur vom Benutzer geöffnete lokale Medien und ihren übergeordneten Ordner. Kompatibilitätswiedergabe schreibt in einen lokalen Cache; Es lädt keine Medien hoch und verändert keine Originale.

Weitere Formatbeispiele und Cache-/Vorschaugrenzen finden Sie unter [FORMATS.md](../i18n/de/FORMATS.md).

## Aus dem Quellcode erstellen

Erfordert Xcode oder Befehlszeilentools mit dem Swift-Compiler. Das Repository und das Quellpaket umfassen universelle Medientools von Intel/Apple Silicon, sodass für einen normalen Build kein zusätzliches Installieren oder Herunterladen von Drittanbieter-Abhängigkeiten erforderlich ist. Erstellen Sie nach dem Klonen oder Herunterladen aus dem Repository-Stammverzeichnis, das `build.sh` enthält; Das ursprüngliche Layout des Entwicklungsarbeitsbereichs ist nicht erforderlich.

```bash
cd /path/to/LumaView
./build.sh
open ../LumaView.app
```

Die Standardeinstellung erzeugt eine universelle App. `./build.sh --host` erstellt nur die aktuelle Mac-Architektur. Die App wird standardmäßig neben dem Quellverzeichnis als `LumaView.app` abgelegt; Legen Sie `LUMAVIEW_APP_PATH` für ein anderes Ziel fest. Build- und Test-Arbeitsdateien sind im Repository standardmäßig auf `.build/` eingestellt und können mit `LUMAVIEW_WORK_ROOT` verschoben werden. Diese generierten Dateien werden durch `.gitignore` ausgeschlossen.

Test-Builds verwenden `LUMAVIEW_TEST_BUILD=1 ./build.sh --host`, um eine separate LumaView-Tests-App ohne Deklarationen zum Öffnen von Dateien zu erstellen, wodurch verhindert wird, dass Testkopien mit der installierten App konkurrieren. UI-Testskripte verwenden diesen Modus standardmäßig. Verwenden Sie `LUMAVIEW_SKIP_TEST_BUILD=1` und `LUMAVIEW_TEST_APP_PATH`, um eine bereits erstellte App auszuwählen.

FFmpeg wurde unter LGPL 2.1 oder höher erstellt und statisch verknüpftes dav1d verwendet BSD 2-Clause. Entsprechende Quellarchive, Prüfsummen und Lizenzen liegen dem Quellpaket bei. Für die Neuerstellung der Medientools sind Xcode-Befehlszeilentools, Python 3, Meson 1.12.1 und Ninja 1.13.2 erforderlich. Installieren Sie die Python-Tools in einer virtuellen Umgebung und führen Sie `./tools/build-media-tools.sh` aus. Siehe [ThirdParty/README.md](../i18n/de/ThirdParty/README.md) für Schritte und Build-Konfiguration. PostScript verwendet eine separate ausführbare Ghostscript-Datei 10.08.0 (AGPL-3.0-or-later), in der die Lizenz, die vollständige entsprechende Quelle und das Build-Skript enthalten sind. Normale App-Builds verwenden die gebündelte Universalkomponente; Informationen zum Neuaufbau finden Sie im [Ghostscript-Handbuch](../i18n/de/ThirdParty/README-Ghostscript.md).

## Quelle und Validierung

- `Sources/`: AppKit-Schnittstelle, Medien-Canvas, Raster- und Vektorladen, Audio-/Video-Lebenszyklus, Kompatibilitätsvorbereitung und Standardanwendungseinstellungen.
- `Resources/Localizations/`: Sprachzeichenfolgen und die Kernliste der Übersetzungsschlüssel.
- `Resources/MediaFormats.json`: Formatkatalog; `Resources/MediaTools/`: gebündeltes FFmpeg / ffprobe.
- `ThirdParty/sources/`, `Resources/ThirdPartyNotices/`: entsprechende Medientool-Quellen und Lizenzen.
- `build.sh`: Universelle App-Kompilierung, Verpackung und lokale Signierung; `tools/build-media-tools.sh`: Medientools neu erstellen.

```bash
./Tests/run-core-tests.sh
./Tests/run-thumbnail-tests.sh
./Tests/run-thumbnail-request-tests.sh
./Tests/run-canvas-tests.sh
./Tests/run-ui-tests.sh
./Tests/run-video-tests.sh
./Tests/run-default-application-tests.sh
./Tests/run-default-preferences-tests.sh
./Tests/run-media-declaration-tests.sh
./Tests/run-document-tests.sh
./Tests/run-vector-compatibility-tests.sh
./Tests/run-postscript-tests.sh
./Tests/run-photoshop-tests.sh
./Tests/run-pdf-image-copy-tests.sh
./Tests/run-media-copy-tests.sh
./Tests/run-context-menu-tests.sh
./Tests/run-large-document-tests.sh
./Tests/run-audio-waveform-tests.sh
./Tests/run-audio-visual-tests.sh
./Tests/run-localization-tests.sh
```

Für Audio-Dekodierungs-Einheitstests ist ein Entwicklungs-FFmpeg mit den entsprechenden Encodern erforderlich, um MP3 / FLAC / Opus-Beispiele zu generieren. Setzen Sie `LUMAVIEW_TEST_FFMPEG` auf seinen Pfad. Die App- und Audio-Interface-Tests verwenden ausschließlich gebündelte Komponenten.

Für UI-Integrationsprüfungen ist ein angemeldeter grafischer macOS-Desktop erforderlich. Sie öffnen die App und überprüfen Interaktionen anhand generierter Medien. Build-Dateien und gespeicherte Testberichte sind standardmäßig `.build/`; Einige zur Laufzeit verwendete Testdateien verwenden das temporäre Systemverzeichnis. Tests lesen standardmäßig keine persönlichen Fotos. Kontextmenü-Kopiertests verwenden eine separate benannte Zwischenablage, ohne die aktuelle Zwischenablage des Benutzers zu ersetzen. Öffnen mit / Finder / Standardanwendungstests verwenden Mocks und ändern keine Dateizuordnungen. Den Validierungsbericht der bereitgestellten Version finden Sie unter [TEST-RESULTS.txt](../i18n/de/TEST-RESULTS.md).

Gespeicherte Berichte in `Tests/` sind historische Aufzeichnungen für ihre jeweiligen Versionen und kein Beweis dafür, dass ein neuer Checkout automatisch Tests in der aktuellen Umgebung bestanden hat. Persönliche Probennamen werden anonymisiert und Originalmedien werden nicht in das Repository aufgenommen. Historische `work/`-Pfade zeichnen die Testquellen zu diesem Zeitpunkt auf und sind keine erforderlichen Verzeichnisse für aktuelle Builds. Das Repository bewahrt entsprechende Quellarchive, Prüfsummen und Lizenzen von Drittanbietern, sodass der anfängliche Klon relativ groß ist.
