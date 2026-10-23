# Verificatierapport LumaView 1.7.2

<!-- doc-navigation:start -->
[Documentatie](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · [繁體中文](../zh-Hant/TEST-RESULTS.md) · [English](../en/TEST-RESULTS.md) · [日本語](../ja/TEST-RESULTS.md) · [한국어](../ko/TEST-RESULTS.md) · [Français](../fr/TEST-RESULTS.md) · [Deutsch](../de/TEST-RESULTS.md) · [Español](../es/TEST-RESULTS.md) · [Italiano](../it/TEST-RESULTS.md) · [Português (Brasil)](../pt-BR/TEST-RESULTS.md) · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · [Türkçe](../tr/TEST-RESULTS.md) · **Nederlands** · [Polski](../pl/TEST-RESULTS.md)
<!-- doc-navigation:end -->


Versie 1.7.2, build 14. 2026-10-22, macOS 15.7.9 / Intel. App en ingebouwde tools zijn gecontroleerd op universele arm64 + x86_64 en lokale handtekeningen; deze ronde is niet op Apple Silicon-hardware uitgevoerd.

## Deze oplossing

Rasterafbeeldingen tonen transparantie nu rechtstreeks en uniform: PNG / GIF / PSD / PSB leggen geen grijs-wit schaakbord of rechthoekige canvasrand meer op. Schaduw volgt de werkelijke composiettransparantie, niet het hele canvas; transparante marges krijgen geen extra rechthoekige schaduw en uitsparingen, aparte zachte maskers en halftransparantie vormen de echte contour.

De oude implementatie baseerde het schaakbord alleen op CGImage.alphaInfo en miste PSB met aparte Quartz mask. Bovendien werd bij iedere zoom een rechthoekige shadowPath afgedwongen en wierp de rand zelf een rechthoekige schaduw. Deze bronnen zijn verwijderd; de laagschaduw ontstaat automatisch uit composiet-alpha. De tekenexport werpt ook schaduw van de afbeelding zelf zonder vooraf een rechthoek te vullen. GIF / APNG vervangt bij frames de huidige textuur; schaduw volgt zonder ieder frame transparante pixels te scannen of een extra volledig RGBA-beeld te bouwen.

Wit documentpapier en rechthoekige video behouden hun bestaande weergave. Kopiëren gebruikt oorspronkelijke pixels zonder viewerachtergrond, schaakbord of weergaveschaduw. PSB-decoder, miniatuurplanning en snelle voorvertoning uit de vorige versie zijn niet gewijzigd.

## Verificatie van deze ronde

| Onderdeel | Geslaagd |
| --- | --- |
| Transparantie, contourschaduw en framewisseling | 133 / 133 |
| Canvasgeometrie, animatie en muis | 66 / 66 |
| Documentparsing en volledige paginaweergave | 56 / 56 |
| Geïnstalleerde release: documenten, EPS / PS-zoom, bladeren en focus | 75 / 75 |
| Geïnstalleerde release: contextmenu en kopiëren | 28 / 28 |
| Totaal | 358 / 358 |

De transparantietest gebruikt dezelfde vorm met uitsparingen, onregelmatige uitsteeksels en brede transparante marges als RGBA, aparte Quartz mask en daadwerkelijk gecodeerde/gedecodeerde PNG, GIF, PSD en PSB. CALayer-compositie en draw-exportpixels controleren geen rechthoekige onderlaag/schaduw aan transparante randen en wel schaduw langs binnen-/buitencontouren. Ook volledig transparante beelden, frames, draaien/zoomen, snelle wissels en doorschijnende viewerachtergrond zijn getest. Geëxporteerde PNG's zijn handmatig bekeken.

De PNG SHA-256 van CALayer-export en PNG draw-export voor alle zes inputs is identiek: `578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`. Testmateriaal is door code gemaakt; gebruikersfoto's staan niet in de bron.

Een extra begrensde softwaretekenproef gebruikte een 32 MP-bitmap met logisch canvas 16,384 × 7,812 en 300,000 × 128, en vergeleek oude/nieuwe schaduw bij passend, 100% en 3200%. Piek-RSS was circa 428 MiB; tekentijden waren vergelijkbaar. Dit meet de software-snapshotkosten van CALayer.render(in:), niet de GPU-framerate. Er is hiervoor geen rastercache voor lagen toegevoegd.

Bestandslijsten en hashes van de geïnstalleerde release en outputs/LumaView.app zijn volledig gelijk; beide slagen voor codesign --verify --deep --strict. Een oude ZIP-back-up is voor installatie bewaard; standaardkoppelingen zijn ervoor en erna uitgelezen. De geleverde ZIP kreeg daarna CRC- en versiecontrole. Historische rapporten staan in Tests/Release-1.7.0.md en Tests/Release-1.7.1.md; niet-herhaalde oude controles tellen niet mee.

SHA-256 hoofdprogramma: `b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`.

## Logbronnen

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
