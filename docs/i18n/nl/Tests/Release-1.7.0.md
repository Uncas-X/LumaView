> Persoonlijke voorbeeldnamen in historische rapporten zijn geanonimiseerd; testgegevens en resultaten zijn ongewijzigd.

<!-- doc-navigation:start -->
[Documentatie](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · **Nederlands** · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# Verificatierapport LumaView 1.7.0

Datum: 2026-10-22 (Asia/Shanghai). Testomgeving: macOS 15.7.9, x86_64. De app richt zich op macOS 13+; alle vier executables zijn universeel voor Intel / Apple Silicon.

## Wijzigingen en gemeten resultaten

- Ingebouwde Ghostscript 10.08.0 zet direct geopende EPS, PostScript en oude PostScript AI op de achtergrond om naar PDF met behoud van vectorpaden, tekst en ingesloten beelden, voor het bestaande canvas. Geen aparte interpreter of handmatige conversie nodig; zoomen, slepen, draaien en paginanavigatie blijven gelijk. Ingesloten TIFF blijft terugval als vectorconversie mislukt en het bestand een voorbeeld heeft; rasterterugval wordt niet als vector benoemd.
- De oorspronkelijke bijlage `sample-vector.eps` is met volledige PostScript-inhoud getest. De PDF-scan vond **147,521 pad-/verloopbewerkingen, 59 tekstbewerkingen en 160 XObject-aanroepen**. XObject wordt geteld via PDF `Do` en kan beeld of Form zijn, niet noodzakelijk een aparte afbeelding. Echte vectorinhoud is behouden; SHA-256 van EPS en `sample-vector.svg` vóór/na bevestigt ongewijzigde originelen.
- PostScript gebruikt een apart annuleerbaar proces, Ghostscript SAFER en systeemsandbox. Invoer wordt naar een eigen tijdelijke map gekopieerd; de interpreter kan geen andere gebruikersbestanden lezen, willekeurig buiten de map schrijven of externe pipes gebruiken. Timeout, annulering, meerdere consumenten, beschadigde invoer en cache-invalidatie zijn getest. Voltooide resultaten worden atomair gepubliceerd; gedeeltelijke PDF's vullen geen miniaturen. De echte viewer testte EPS op 3200%, focus omhoog/omlaag en pagina's links/rechts bij meerbladige PS, en dat oude conversie een inmiddels gekozen PNG niet overschrijft.
- `.psb` is aan Photoshop toegevoegd naast `.psd` voor ontdekking, hoofdbeeld, miniaturen en standaardapp. De compatibele composiet wordt gelezen met behoud van canvasafmetingen; grote bestanden krijgen een begrensd voorbeeld naar weergavebehoefte. **112 coderingscombinaties, 128 structuurvoorbeelden met laagtransparantiemarkeringen, 1 grote PSB en 13 beschadigde voorbeelden** zijn getest. Transparantie volgt laagaantal en Lr16/Lr32, Mtrn/Mt16/Mt32; gewone extra Alpha wordt niet verward met composiettransparantie. Pixelwaarden, witte-ondergrondverwijdering, coderingsconsistentie, annulering van lange regels en hoofdbeeld-/miniatuurintegratie zijn gedekt.
- Standaardapp-instellingen lezen echte systeemkoppelingen bij openen, heractivering en na batchinstelling. Koppelingen overleven herstarts; niet-toegepaste concepten worden niet als geslaagd weergegeven. Alle typen naar deze kopie geeft een vinkje; gedeeltelijk of andere kopie met dezelfde bundle ID geeft een streepje met uitleg. Wissen verandert alleen het concept, niet de systeemstandaard.
- ‘Alle formaten selecteren’ kiest afbeeldingen, vector/document, video en audio inclusief buiten zoekresultaten; schrijven vereist nog de instelknop. Detectie, gedeeltelijk succes, foutteruglezing, controllerherbouw, concept versus echt en alles selecteren zijn getest met een in-memory mock; gebruikersstandaardapps zijn niet veranderd.
- Nieuwe instellingen-, PostScript- en Photoshop-teksten dekken alle 16 talen; kerntekst- en placeholdertests zijn geslaagd.

## Verificatie van deze ronde

Alleen onderstaande logs met volledige succesoverzichten uit deze ronde tellen mee; niet-herhaalde historische modules niet.

| Controle | Geslaagd |
| --- | --- |
| PostScript-vectorconversie, annulering, isolatie en echte EPS | 24 / 24 |
| SVG / EPS-compatibiliteit en oorspronkelijke bijlagen | 64 / 64 |
| PSD / PSB-composiet, transparantie, grote beelden en schade | 712 / 712 |
| Systeemstandaard teruglezen en batchinstellen (mock) | 101 / 101 |
| Formaatvenster, heropenen en alle formaten (mock) | 34 / 34 |
| 16 talen en placeholders | 174 / 174 |
| Formaatdeclaraties release-app | 15 / 15 |
| Afbeeldingsbibliotheek en systeemdecodering | 78 / 78 |
| Canvasgeometrie, animatie en muis | 66 / 66 |
| Documentparsing en volledige paginaweergave | 56 / 56 |
| Documentfocus, EPS / PS-zoom, bladeren en annuleren bij wisselen | 75 / 75 |
| Echte vensterklikken en levenscyclus | 65 / 65 |
| Miniaturen van 443 bestanden, cache en verouderde callbacks | 37 / 37 |
| Annulering miniatuuraanvragen en consumentisolatie | 13 / 13 |
| Geïnstalleerde release: contextmenu en privéklembord | 28 / 28 |
| **Totaal** | **1542 / 1542** |

De geïnstalleerde geoptimaliseerde release kreeg nog 28 contextmenucontroles via echte menu's en target/action, met een apart benoemd klembord. Getest: afbeeldingen, videoframes, PDF-afbeeldingen en pagina's kopiëren, draaien en verouderde resultaten bij wisselen/sluiten. Het gebruikersklembord werd niet overschreven. Bestaande regressies voor muisklikken, vensterlevenscyclus, paginafocus, volledige pagina's, miniatuurcache en annulering slaagden.

## Release- en installatieverificatie

Versie **1.7.0, build 12**. Voor het rapport zijn bundle ID, versie, build, volledige bestandslijst en SHA-256 van `outputs/LumaView.app` en `/Applications/LumaView.app` vergeleken; inhoud is gelijk. Alle vier executables hebben beide architecturen, beide apps slagen voor `codesign --verify --deep --strict`. Ghostscript meldt 10.08.0; lokalisatie en versieresources matchen de bron, de SHA-256 van het Ghostscript-archief matcht de meegeleverde checksum. De build ondertekent de interpreter opnieuw; het ondertekende bestand hoeft daarom niet bytegelijk te zijn aan de nog niet opnieuw ondertekende bronkopie.

| Executable | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

Dit vervangt de latere ZIP-integriteitscontrole niet en claimt geen Apple-notarisatie. De handtekening is lokaal tijdelijk; Apple Silicon is gecrosscompileerd en op architectuur gecontroleerd, maar deze ronde niet op hardware uitgevoerd. Ghostscript-bronarchief, licenties en herbouwinstructies worden met de bron geleverd.

## Reikwijdte en grenzen

Ingesloten EPS / PS-bitmaps behouden hun resolutielimiet; externe fonts/bestanden, bijzondere of beschadigde PostScript worden niet gegarandeerd volledig geconverteerd. PSD / PSB vereist een compatibele composiet, bewerkt geen lagen en reconstrueert geen ontbrekende composiet; bij ontbreken wordt opslaan met ‘Compatibiliteit maximaliseren’ gevraagd. Het broncanvas kan groter zijn dan het voorbeeld; een begrensde voorvertoning claimt geen volledig gedecodeerde bronpixels. Overige grenzen staan in [FORMATS.md](../FORMATS.md).

## Logbronnen van deze ronde

Deze bestanden zijn naar `Tests/` gekopieerd; niet-herhaalde historische rapporten blijven behouden maar tellen niet mee:

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
