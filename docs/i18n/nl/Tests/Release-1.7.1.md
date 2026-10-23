> Persoonlijke voorbeeldnamen in historische rapporten zijn geanonimiseerd; testgegevens en resultaten zijn ongewijzigd.

<!-- doc-navigation:start -->
[Documentatie](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · **Nederlands** · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# Verificatierapport LumaView 1.7.1

Versie 1.7.1, build 13. 2026-10-22, macOS 15.7.9 / Intel. App en drie ingebouwde tools zijn op arm64 + x86_64 en lokale handtekeningen gecontroleerd; deze ronde niet uitgevoerd op Apple Silicon-hardware.

## Vastgesteld en opgelost

De drie gebruikers-PSB's zijn 8-bit RGB, 4 kanalen, RLE met composiettransparantie, circa 108–123 MiB. Het meeste volume bestaat uit direct overslaanbare laagdata; het hoofdcanvas is circa 8.50–9.60 miljoen pixels.

1. De oude regeldecodeerder las FileHandle voor iedere PackBits-marker en waarde, met veel kleine lezingen en lange bezetting van hoofdbeeld-/miniatuurqueues. Nu worden blokken tot 64 KiB gelezen, met behoud van literal/run over blokgrenzen en grenscontroles; lange no-op blijft annuleerbaar. ZIP herstelt voorspelling alleen voor bemonsterde regels, maar valideert de volledige compressiestroom.
2. Alle drie bevatten een geldige RGB JPEG-miniatuur in resource 1036. De filmstrip gebruikt die eerst, met formaat-, afmeting-, verhouding- en compressielengtecontrole; hoofdbeeld decodeert altijd de echte composiet. Ongeldige voorbeelden, oude BGR-resource of ontbrekende voorbeelden vallen terug op de composiet.
3. ImageIO weigert sommige kleine PSD-composieten met geldige Generic RGB ICC, waardoor de oude versie lege miniaturen gaf. De terugval decodeert pixels apart en hecht het gevalideerde oorspronkelijke ICC met gelijk kleurmodel/componenten opnieuw aan, zonder het weg te gooien. Het oorspronkelijke profiel is gelijk aan systeem-Generic RGB Profile; nieuwe regressies genereren data met dat systeemprofiel, zonder gebruikersfoto's in de bron.
4. Het PSB-hoofdbeeld hergebruikt de gelezen header en vermijdt een extra ImageIO-laagscan voor metadata. Bronafmetingen, transparantie en hoofdbeeldkwaliteit blijven behouden.

## Metingen aan drie originele bestanden

Dit zijn lokale metingen op deze Mac, afhankelijk van belasting en bestandscache, geen garantie voor elk apparaat. Oude en nieuwe decoders zijn geoptimaliseerd gebouwd.

| Bestand | Bronafmetingen | Oude hoofddecodering | Nieuwe hoofddecodering | Nieuwe composietminiatuur (zonder ingesloten voorbeeld) |
| --- | --- | --- | --- | --- |
| Sample A | 2582 × 3318 | Test geannuleerd na meer dan 15 seconden | 0.68 seconde | 0.039 seconde |
| Sample B | 2610 × 3307 | 14.35 seconden | 0.65 seconde | 0.028 seconde |
| Sample C | 2843 × 3361 | Test geannuleerd na meer dan 15 seconden | 0.70 seconde | 0.028 seconde |

Drie gelijktijdige miniatuuraanvragen via echte ImageLoader waren in circa 0.06 seconde klaar. Volledige hoofdbeelden kostten via de loader circa 0.90 / 0.65 / 0.74 seconde. De oude drie composietminiaturen gaven unsupported; de nieuwe slagen. SHA-256 vóór/na is bytegelijk; de app schreef niet naar originelen.

## Geslaagde controles

| Onderdeel | Resultaat |
| --- | --- |
| PSD / PSB-codering en transparante composiet | 712 / 712 |
| RLE-prestaties, ingesloten voorbeeld, ICC, blokgrenzen en annulering | 54 / 54 |
| Echte ImageLoader-integratie met drie originele PSB's | 21 / 21 |
| Filmstrip met 443 bestanden, cache en verlopen callbacks | 37 / 37 |
| Onafhankelijke miniatuuraanvragen en annulering | 13 / 13 |
| Afbeeldingsbibliotheek en systeemdecodering | 78 / 78 |
| Geïnstalleerde geoptimaliseerde release: contextmenu en kopiëren | 28 / 28 |
| Totaal | 943 / 943 |

Nieuwe tests dekken dichte éénbyte-literals, 64 KiB-grenzen, lange no-op-annulering, afkappen/grensoverschrijding, aparte correcte inhoud van miniatuur en hoofdbeeld, ICC, transparantie en niet-gehele schaal van kleine beelden. Bestaande 112 coderingscombinaties en 128 laagtransparantiestructuren blijven slagen. Filmstripcontroles dekken snel wisselen, annuleren buiten beeld en geen vervuiling van de huidige lijst door oude callbacks.

Geïnstalleerde versie en outputs/LumaView.app hebben gelijke volledige lijsten en hashes, beide slagen voor codesign --verify --deep --strict. Een oude ZIP-back-up is vóór installatie bewaard; standaardkoppelingen zijn niet gewijzigd. Leverings-ZIP krijgt apart CRC-/versiecontrole. Het volledige historische 1.7.0-rapport blijft in Tests/Release-1.7.0.md; niet-herhaalde controles tellen niet mee.

SHA-256 hoofdprogramma: `cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`.

## Logs

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
