# LumaView 1.7.2

<!-- doc-navigation:start -->
[Documentatie](../i18n/nl/INDEX.md) · [简体中文](../i18n/zh-Hans/README.md) · [繁體中文](../i18n/zh-Hant/README.md) · [English](../i18n/en/README.md) · [日本語](../i18n/ja/README.md) · [한국어](../i18n/ko/README.md) · [Français](../i18n/fr/README.md) · [Deutsch](../i18n/de/README.md) · [Español](../i18n/es/README.md) · [Italiano](../i18n/it/README.md) · [Português (Brasil)](../i18n/pt-BR/README.md) · [Русский](../i18n/ru/README.md) · [العربية](../i18n/ar/README.md) · [हिन्दी](../i18n/hi/README.md) · [Türkçe](../i18n/tr/README.md) · **Nederlands** · [Polski](../i18n/pl/README.md)
<!-- doc-navigation:end -->


**[Download de macOS-app](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)** · [Versies en wijzigingsnotities](https://github.com/Uncas-X/LumaView/releases)

Voor macOS 13+; hetzelfde pakket ondersteunt Intel en Apple Silicon. Pak de gedownloade ZIP uit en sleep `LumaView.app` naar ‘Apps’.

Een native mediaviewer voor macOS, geïnspireerd op het snelle bekijken met Picasa Photo Viewer, met bladeren binnen dezelfde map, zoomen, slepen, draaien, filmstrip, volledig scherm en diavoorstelling. Versie 1.5 voegde audiohoezen en echte golfvormen, navigatie door documenten met meerdere pagina's, een bij zoomen opnieuw getekend vectorcanvas en meertalige instellingen toe die standaard het systeem volgen. De app heeft een eigen naam en oorspronkelijk pictogram; er wordt geen volledige overeenkomst met alle functies en interacties van de vroegere Picasa geclaimd.

1.7.2 maakt transparantie consistent: PNG, GIF, PSD / PSB en andere rasterafbeeldingen laten de huidige achtergrond zien; de schaduw volgt de werkelijke vorm en transparantie. Het grijs-witte schaakbord en de rechthoekige schaduw van het volledige transparante canvas verdwijnen. Documenten zoals PDF behouden hun witte papier.

De PSD / PSB-optimalisaties uit 1.7.1 blijven behouden: de filmstrip leest eerst een geldige ingesloten JPEG, terwijl het hoofdbeeld de echte compatibele composiet decodeert. RLE wordt in blokken gelezen; ook het ontbreken van miniaturen bij sommige kleine composieten met ICC-profiel is verholpen.

## Gebruik en installatie

Vereist macOS 13 of nieuwer; ondersteunt Intel en Apple Silicon.

1. Download `LumaView-macOS.zip` via [Releases](https://github.com/Uncas-X/LumaView/releases), pak uit, sleep `LumaView.app` naar ‘Apps’ en open de app.
2. Sleep afbeeldingen, video, audio of een map naar de app, of selecteer bestanden met `⌘O`. Eén geopend bestand toont de media in dezelfde map; een meervoudige selectie toont alleen die bestanden. Alleen het huidige mapniveau wordt doorzocht, niet de submappen.
3. U kunt in Finder ook rechtsklikken en ‘Open met → LumaView’ kiezen.

Lokale builds gebruiken een tijdelijke handtekening en zijn niet door Apple genotariseerd. Als Gatekeeper op een andere Mac de download blokkeert, kunt u na controle van de herkomst openen toestaan onder ‘Privacy en beveiliging’ in de systeeminstellingen.

## Standaardapp voor bestanden

Kies **LumaView → Standaardapp…**, druk op `⌘,` of open de instellingen via ‘Meer’. Formaten zijn gegroepeerd als afbeeldingen, vectoren / documenten, video en audio; zoek en vink ze aan, en klik op ‘Instellen als standaardapp voor geselecteerde formaten’. Bij openen van het venster, heractivering van de app en afronding worden de werkelijke systeemkoppelingen gelezen: een vinkje betekent dat de hele groep door deze LumaView wordt geopend; een streepje betekent een gedeeltelijke koppeling of een andere kopie. Systeemkoppelingen blijven na herstart behouden; nog niet toegepaste selecties worden niet als geslaagde instellingen voorgesteld. ‘Alle formaten selecteren’ bovenaan omvat alle afbeeldingen, vectordocumenten, video en audio, onafhankelijk van de zoekfilter; ook per categorie kan alles worden geselecteerd. Wissen verwijdert alleen de huidige selectie, niet bestaande systeemkoppelingen.

De instelling toont voortgang en leest ieder systeemresultaat terug. Annuleren stopt volgende wijzigingen, maar behoudt de reeds uitgevoerde. De lijst geeft selecteerbare bestandskoppelingen aan, niet dat elke interne codering of elk bestand is getest; zie [Formaten en voorvertoningen](../i18n/nl/FORMATS.md).

## Bekijken en afspelen

Bij het eerste bestand wordt het venster uitgebreid tot de bruikbare ruimte van het huidige scherm; `F` opent volledig scherm. De onderste filmstrip wisselt direct van bestand. De bediening verdwijnt als de muis enige tijd in het beeld blijft en verschijnt weer bij bewegen.

1.5.2 verhelpt lege of voortdurend knipperende miniaturen na langdurig bladeren door grote mappen: zichtbare miniaturen worden apart vastgehouden, laden buiten beeld wordt tijdig geannuleerd en oude mapresultaten worden niet in de nieuwe lijst geschreven. Niet-decodeerbare bestanden tonen een stabiele tijdelijke afbeelding; bij terugkeer naar dat bereik kan opnieuw worden geprobeerd.

Afbeeldingen en video's kunnen zoomen, verschuiven, draaien en volledig scherm gebruiken. Vensterbewegingen, beeldwissels, zoomen en draaien hebben korte vloeiende overgangen die door vervolghandelingen onderbroken kunnen worden. ‘Verminder beweging’ in het systeem schakelt deze eigen overgangen uit; bewegende afbeeldingen blijven afspelen. Standaard is de achtergrond doorschijnend matglas; de spatiebalk wisselt tussen matglas, donker en licht.

Transparante rastergebieden volgen één regel: de huidige achtergrond is zichtbaar, schaduw volgt alleen inhoudelijke pixels en halftransparante randen behouden hun dekking. Tijdens GIF / APNG beweegt de schaduw met ieder frame. Gekopieerde afbeeldingen behouden oorspronkelijke transparante pixels zonder viewerachtergrond of schaduw.

Afspelen, stoppen, voortgang en volume voor audio/video staan boven de filmstrip. Afspelen start automatisch; na afloop blijft het einde staan, `P` speelt opnieuw en `S` stopt en keert terug naar het begin. De onderste diavoorstellingsknop staat los van audio/video: na inschakelen met `⌘4` wisselen afbeeldingen volgens het interval, terwijl audio/video eerst afloopt. Los afspelen van audio/video gaat niet automatisch naar het volgende bestand.

Eerst wordt native macOS-weergave geprobeerd. Als het systeem een bestand niet rechtstreeks kan afspelen, bereiden de ingebouwde universele FFmpeg 9.0.2 en dav1d 1.5.3 lokaal een compatibel bestand voor; waar mogelijk wordt eerst de container vervangen, daarna getranscodeerd. Geen extra speler, Homebrew of codecpakket nodig, en geen netwerktoegang. Compatibel afspelen wacht op voorbereiding van het volledige bestand, met voortgang; een ander bestand kiezen of het venster sluiten annuleert dit. De eerste voorbereiding van lange video kan veel tijd en extra schijfruimte kosten.

`C` of ‘Meer’ stelt doorlopend bladeren, wielgedrag, sluiten via de achtergrond, filmstrip, sortering en dia-interval (2, 3, 5, 8, 10 seconden) in. Het wiel zoomt standaard; `Ctrl` ingedrukt schakelt tijdelijk naar bestanden bladeren. Als bladeren de standaard is, schakelt `Ctrl` tijdelijk naar zoomen. ‘Sluiten door op de achtergrond buiten het beeld te klikken’ staat standaard aan. Voorkeuren worden lokaal opgeslagen.

## Contextmenu en kopiëren

Rechtsklik op het hoofdbeeld (of Ctrl-klik) voor ‘Open met → App / Andere app…’ of ‘Toon in Finder’. Open met geldt alleen voor deze keer en verandert geen standaardkoppeling; beide opties werken ook voor niet-decodeerbare bestanden.

- Afbeeldingen: ‘Kopieer afbeelding’ behoudt de huidige draairichting en transparante pixels en kopieert de volledige gedecodeerde afbeelding, niet de werkbalk of een ingezoomde schermafdruk.
- Video: ‘Kopieer huidig frame’ kopieert het frame op het moment dat het contextmenu werd geopend, behoudt video-oriëntatie en weergaverotatie en verandert afspeelpositie of -status niet.
- PDF / PDF-compatibele AI: rechtsklik op een rasterafbeelding voor ‘Kopieer deze afbeelding’, of kies ‘Kopieer huidige pagina’. De werkelijke klikpositie blijft correct na zoomen, slepen en draaien. Gewone tekst en vectoren gelden niet als afbeelding; bij complexe maskers of kleurruimten wordt het zichtbare beeldgebied gekopieerd, mogelijk inclusief tekst erboven. Een pagina die als één afbeelding is gescand wordt als volledige scan gekopieerd.
- `⌘C` kopieert de huidige afbeelding, videoframe of documentpagina; audio biedt geen afbeeldingkopie. Het klembord krijgt PNG en TIFF. Na bestand-/paginawissel of sluiten overschrijft een verouderd kopieerresultaat het klembord niet.

Documenten en ingesloten afbeeldingen worden gekopieerd als bitmap met maximaal 8192 pixels langs de lange zijde en ongeveer 32 miljoen pixels; PDF/SVG-vectorinstructies komen niet op het klembord. Als een grote afbeelding als begrensde voorvertoning wordt getoond, wordt die voorvertoning gekopieerd. Het zoeken naar PDF-afbeeldingen heeft een complexiteitslimiet; bijzondere structuren zoals afbeeldingen in patroonvullingen kunnen niet altijd apart worden gekozen, maar de hele pagina blijft kopieerbaar.

Standaard SVG 1.0/1.1-headers worden offline gelezen zonder externe DTD. 1.7 bundelt Ghostscript 10.08.0, dat EPS / PostScript en oude PostScript AI omzet naar PDF met behoud van paden, tekst en ingesloten afbeeldingen; het hoofdbeeld tekent vectoren opnieuw bij zoomen. Meerbladige PS gebruikt de bestaande paginanavigatie. Extra software is niet nodig. Als conversie mislukt maar EPS een geldige TIFF bevat, is terugval op een expliciet als TIFF gemarkeerde voorvertoning mogelijk. Oorspronkelijke bitmaps worden geen vectoren.

## Audio, documenten en talen

Bij ingesloten audiohoes toont het hoofdbeeld die eerst; anders worden echte samples asynchroon geanalyseerd voor de golfvorm van de volledige audio. Tijdens analyse staat een tijdelijke afbeelding; afspelen hoeft niet te wachten. Audio en video tonen rechtsonder in de filmstrip hetzelfde `▶ Duur`, met hetzelfde lettertype, vlak en positie; vóór uitlezen verschijnt `▶ –:––`. Hoezen komen uit ingesloten metadata, niet van internet of afbeeldingen in dezelfde map.

PDF, PDF-compatibele AI en meerbladige TIFF ondersteunen pagina's. Kleinere paginaminiaturen, een paginabalk en huidige / totale pagina staan boven de bestandsfilmstrip. `↑` focust pagina's en `↓` bestanden. Een oranje rand markeert de geselecteerde miniatuur in de gefocuste rij; de andere rij behoudt een grijze selectierand. Er zijn geen extra labels ‘Pagina's / Bestanden’. `←` / `→`, `J` / `K` en `Home` / `End` bedienen de huidige focus. Klikken op een rij focust die ook. Aan de eerste/laatste pagina stopt navigatie zonder onverwacht van bestand te wisselen. De onderste vorige-/volgende-bestandsknoppen wisselen altijd bestanden. Paginanavigatie blijft bestaan als de bestandsfilmstrip verborgen is.

PDF, SVG en PDF-compatibele AI tekenen het zichtbare gebied met oorspronkelijke vectorinstructies op de huidige schaal, in plaats van een vast voorbeeld te vergroten. Transparante documentgebieden tonen wit papier zonder schaakbord. Bij paginawisseling wordt eerst de hele nieuwe pagina voorbereid en daarna als geheel ingevloeid; vectorverfijning op de achtergrond laat geen blokken met lege gebieden verschijnen. Ingesloten foto's en andere bitmaps blijven beperkt tot hun bronresolutie.

Kies **LumaView → Taal…** of open via ‘Meer’. Standaard wordt het systeem gevolgd; ondersteund worden Vereenvoudigd Chinees, Traditioneel Chinees, Engels, Japans, Koreaans, Frans, Duits, Spaans, Italiaans, Portugees, Russisch, Arabisch, Hindi, Turks, Nederlands en Pools. Menu's, tooltips, paginering en instellingen worden direct bijgewerkt; de taal wordt lokaal bewaard. Niet-ondersteunde systeemtalen vallen terug op Engels; zeldzame decodeerfouten kunnen ook Engels zijn. Bestandsnamen, paden en oorspronkelijke tekst in bestanden blijven ongewijzigd.

## Toetsenbord en muis

| Actie | Sneltoets / gebaar |
| --- | --- |
| Vorig / volgend item (huidige focus) | `←` / `→` of `J` / `K` |
| Paginafocus / bestandsfocus | `↑` / `↓` (meerbladige documenten) |
| Eerste / laatste item | `Home` / `End` |
| Bestand of map openen | `⌘O` |
| Standaardapp | `⌘,` |
| Zoomen | Wiel, knijpen op trackpad, `+` / `−`, `Page Up` / `Page Down` |
| Wielgedrag tijdelijk wisselen | Scroll met `Ctrl` ingedrukt |
| 100% / passend in venster | Klik op beeld of `1` |
| Passend in venster | `0` |
| Vergrote afbeelding of video verschuiven | Sleep het beeld |
| Weergave rechtsom draaien | `⌘R` / `Ctrl+R`, met `Shift` linksom |
| Achtergrond wisselen | Spatiebalk |
| Volledig scherm aan / uit | `F` / `⌃⌘F` / `F11` (indien niet door systeem gebruikt) |
| Audio/video afspelen / pauzeren | `P` |
| Audio/video stoppen en naar begin | `S` |
| Diavoorstelling en doorlopend afspelen starten / stoppen | `⌘4` |
| Audio/video 5 seconden terug / vooruit | `Option + ←` / `Option + →` |
| Dempen / geluid herstellen | `M` |
| Bestandsinformatie | `I` / `⌘I` |
| Filmstrip tonen / verbergen | `T` / `⌘T` |
| Meer opties | `C` |
| Huidig bestand in Finder tonen | `⌘Return` |
| Pauzeren, informatie sluiten, volledig scherm verlaten, venster sluiten | `Esc`, achtereenvolgens volgens huidige toestand |
| Minimaliseren / sluiten / stoppen | `⌘M` / `⌘W` / `⌘Q` |

`P` bedient alleen de huidige audio/video, niet de diavoorstelling. ‘Help → Toetsenbord en muis’ biedt ook ingebouwde uitleg.

## Ondersteuning en beperkingen

- Afbeeldingen worden door systeem-ImageIO gedecodeerd; werkelijke ondersteuning van JPEG, PNG, GIF, HEIC, TIFF, BMP, WebP, RAW enzovoort hangt af van systeemversie en bestand.
- Enorme afbeeldingen worden niet meer uitsluitend wegens meer dan 150 miljoen pixels geweigerd. Zo nodig wordt een verkleind voorbeeld gemaakt om geheugen te begrenzen, met behoud van bronafmetingen en oriëntatie. 100% zoom wordt op bronafmetingen berekend, maar herstelt geen niet-gedecodeerde details.
- SVG, PDF, PDF-compatibele AI en via de ingebouwde interpreter EPS / PS / oude AI ondersteunen vectorweergave. Meerbladige PDF / AI / PS kunnen bladeren; SVG weigert scripts en externe bronnen. Bitmaps in vectoren behouden hun resolutielimiet; ontbrekende niet-ingesloten lettertypen kunnen vervangen worden.
- PostScript draait apart met SAFER en systeem-sandbox: alleen de huidige tijdelijke invoer en uitvoer zijn toegestaan, netwerk is verboden. Snelle bestandswissels kunnen annuleren; miniaturen en hoofdbeeld delen een cache van voltooide resultaten. Elke interpretatie duurt maximaal 90 seconden, uitvoer maximaal 1 GB, cache-opruimdoel 2 GB.
- Photoshop PSD / PSB toont de opgeslagen composiet, zonder lagenbewerking. Grote canvassen krijgen een voorbeeld binnen het geheugenbudget met behoud van bronafmetingen; kleurmodi, bitdiepten en compressie staan in FORMATS.md.
- Ingebouwde compatibiliteitsdecodering breidt audio/video uit, maar DRM, beschadigde bestanden en propriëtaire coderingen zonder decoder kunnen onbruikbaar blijven. Een extensie garandeert geen decodeerbare inhoud; niet alle formaten, apparaten en systeemversies zijn afzonderlijk getest.
- De compatibiliteitscache heeft een opruimdoel van 2 GB; gebruikte bestanden kunnen dit tijdelijk overschrijden. Eén voorbereid bestand is maximaal 8 GB, met minimaal 512 MB vrije ruimte. Bij ruimtegebrek stopt de voorbereiding met een melding.
- TIFF ondersteunt meerdere pagina's; andere samengestelde afbeeldingsformaten zonder paginering tonen het eerste beeld. Weergaverotatie wordt niet in het origineel geschreven. Geen bewerken, verwijderen, bibliotheekdatabase, delen, cloudsynchronisatie of beheer van externe ondertitels.
- Alleen geopende lokale media en de bijbehorende map worden gelezen. Compatibel afspelen schrijft een lokale cache, uploadt geen media en wijzigt geen originelen.

Meer voorbeelden en cache-/voorvertoningsgrenzen staan in [FORMATS.md](../i18n/nl/FORMATS.md).

## Bouwen uit broncode

Vereist Xcode of Command Line Tools met Swift-compiler. De repository en het bronpakket bevatten universele Intel / Apple Silicon-mediatools; normaal bouwen vereist geen extra installatie of downloads van afhankelijkheden. Ga na klonen of downloaden naar de repositoryroot met `build.sh`; de oude ontwikkelwerkruimte is niet nodig.

```bash
cd /path/to/LumaView
./build.sh
open ../LumaView.app
```

Standaard ontstaat een universele app; `./build.sh --host` bouwt alleen voor de huidige Mac. De app staat naast de bronmap als `LumaView.app`; `LUMAVIEW_APP_PATH` kiest een andere locatie. Bouw- en testwerkbestanden staan standaard in `.build/` binnen de repository, te wijzigen met `LUMAVIEW_WORK_ROOT`; gegenereerde bestanden worden door `.gitignore` uitgesloten.

Testbuild `LUMAVIEW_TEST_BUILD=1 ./build.sh --host` maakt een aparte `LumaView Tests`-app zonder bestandsassociaties, zodat die de geïnstalleerde versie niet overneemt. UI-tests gebruiken dit standaard; met `LUMAVIEW_SKIP_TEST_BUILD=1` en `LUMAVIEW_TEST_APP_PATH` kiest u een reeds gebouwde app.

FFmpeg is gebouwd onder LGPL 2.1 of later; statisch gekoppelde dav1d gebruikt BSD 2-Clause. Bijbehorende bronarchieven, checksums en licenties zitten in het bronpakket. Herbouw van mediatools vereist Xcode Command Line Tools, Python 3, Meson 1.12.1 en Ninja 1.13.2; installeer eventueel in een Python-virtualenv en voer `./tools/build-media-tools.sh` uit. Stappen en configuratie staan in [ThirdParty/README.md](../i18n/nl/ThirdParty/README.md). PostScript gebruikt aparte Ghostscript 10.08.0 (AGPL-3.0-or-later), inclusief licentie, volledige bijbehorende bron en bouwscript. Normaal bouwen gebruikt de meegeleverde tweearchitectuurcomponenten; herbouw staat in [Ghostscript-documentatie](../i18n/nl/ThirdParty/README-Ghostscript.md).

## Broncode en verificatie

- `Sources/`: AppKit-interface, mediacanvas, raster-/vectorladen, audio/video-levenscyclus, compatibiliteitsvoorbereiding en standaardapp-instellingen.
- `Resources/Localizations/`: vertalingen en kernsleutellijst.
- `Resources/MediaFormats.json`: formaatcatalogus; `Resources/MediaTools/`: gebundelde FFmpeg / ffprobe.
- `ThirdParty/sources/`, `Resources/ThirdPartyNotices/`: bijbehorende bronnen en licenties van mediatools.
- `build.sh`: universeel compileren, verpakken en lokaal ondertekenen; `tools/build-media-tools.sh`: mediatools herbouwen.

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

Audio-decodeerunittests maken MP3 / FLAC / Opus en vereisen een ontwikkel-FFmpeg met de betreffende encoders; geef het pad via `LUMAVIEW_TEST_FFMPEG`. Appgebruik en audio-UI-tests gebruiken alleen gebundelde componenten.

UI-integratietests vereisen een ingelogde grafische macOS-sessie, openen de app en testen met automatisch gegenereerde media. Builds en opgeslagen rapporten staan standaard in `.build/`; sommige runtime-materialen gebruiken de systeemtempmap. Tests lezen standaard geen privéfoto's. Contextmenu-kopieertests gebruiken een apart benoemd klembord en overschrijven het gebruikersklembord niet; Open met / Finder / standaardapp-tests gebruiken mocks en wijzigen geen koppelingen. Verificatie van de geleverde versie staat in [TEST-RESULTS.txt](../i18n/nl/TEST-RESULTS.md).

Opgeslagen rapporten in `Tests/` zijn historische controles van die versie, geen bewijs dat de huidige omgeving na klonen automatisch is geslaagd. Persoonlijke bestandsnamen zijn geanonimiseerd; originele media staan niet in de repository. Historische `work/`-paden geven toenmalige testbronnen weer en zijn niet vereist voor de huidige build. De repository bewaart bijbehorende bronarchieven, checksums en licenties van derden; de eerste clone is daarom vrij groot.
