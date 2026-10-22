# LumaView — Nederlands

<!-- language-navigation:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · **Nederlands** · [Polski](README.pl.md)
<!-- language-navigation:end -->

Dit is een snelstartgids. De volledige handleiding is beschikbaar in het [Engels](README.en.md) en [Chinees](../../README.md).

LumaView is een native macOS-app voor afbeeldingen, video, audio en documenten met meerdere pagina's. Het snelle bladeren is geïnspireerd op Picasa Photo Viewer, maar de app heeft een eigen naam en pictogram, zonder verbinding met Google. LumaView richt zich op bekijken, niet op fotobewerking of bibliotheekbeheer.

## Downloaden en installeren

**Versie 1.7.2, build 14.** Vereist macOS 13 of nieuwer. De universele app werkt op Macs met Intel en Apple Silicon.

1. Download [LumaView voor macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip). Eerdere versies staan bij [alle releases](https://github.com/Uncas-X/LumaView/releases).
2. Pak het archief uit en sleep `LumaView.app` naar de map Apps.
3. Open de app. Deze gebruikt een lokale ad-hocondertekening en is niet door Apple genotariseerd. Nadat je de herkomst hebt gecontroleerd, moet je mogelijk toestemming geven via **Privacy en beveiliging** in de macOS-instellingen.

## Bladeren en functies

Sleep een bestand of map naar het venster, of druk op **Cmd+O**. Eén bestand openen geeft toegang tot andere media in dezelfde map. Alleen het huidige mapniveau wordt doorzocht, zonder submappen.

- Selecteer bestanden via de miniaturenstrook. Zoomen, verschuiven, draaien en schermvullende weergave worden ondersteund, met vloeiende overgangen en een doorschijnende achtergrond met matglaseffect.
- Transparante delen van PNG, GIF, PSD en PSB blijven transparant; schaduwen volgen de vorm van de inhoud. Documentpagina's worden op wit papier weergegeven. PSD/PSB gebruikt de opgeslagen samengestelde compatibiliteitsafbeelding, niet de afzonderlijke lagen.
- Video en audio gebruiken eerst de native afspeelmogelijkheden. De meegeleverde FFmpeg ondersteunt aanvullende formaten, maar moet soms het hele bestand lokaal voorbereiden voordat het afspelen begint. Audio toont de ingesloten hoesafbeelding of anders een golfvorm. Afspelen/pauzeren en stoppen van media hebben eigen bediening, los van de diavoorstelling.
- Blader door pagina's van PDF, PDF-compatibele AI en TIFF met meerdere pagina's. SVG, ondersteunde EPS/PS en oudere AI worden als vectoren weergegeven. EPS/PS wordt verwerkt door de meegeleverde Ghostscript; ingesloten bitmapafbeeldingen blijven beperkt tot hun oorspronkelijke resolutie.
- Klik rechts om te openen met een andere app, het bestand in Finder te tonen of een afbeelding, het huidige videoframe, een PDF-pagina of een ondersteunde ingesloten PDF-afbeelding te kopiëren.

Kies in de instellingen voor welke formaten LumaView de standaardapp is, en de interfacetaal. Er zijn 16 talen; standaard volgt de app de systeemtaal.

## Sneltoetsen

| Toets | Actie |
| --- | --- |
| Cmd+O | Bestand of map openen |
| ← / → | Vorig/volgend bestand of vorige/volgende pagina, afhankelijk van de focus |
| ↑ / ↓ | Focus wisselen tussen pagina's en bestanden bij documenten met meerdere pagina's |
| Muiswiel / knijpgebaar / + / − | Zoomen |
| 0 / 1 | Passend in venster / wisselen tussen 100% en passend |
| Cmd+R | Draaien |
| F | Schermvullende weergave wisselen |
| P / S | Media afspelen of pauzeren / stoppen |
| Cmd+4 | Diavoorstelling bedienen |
| Cmd+C | Afbeelding, frame of pagina kopiëren |

**De spatiebalk verandert de achtergrond; deze bedient niet het afspelen of pauzeren.**

## Bouwen vanuit broncode

Installeer Xcode of de Swift Command Line Tools. De repository bevat de benodigde mediatools met de bijbehorende broncode- en licentiearchieven. Voer deze opdrachten uit vanuit de hoofdmap van de repository, niet vanuit deze documentatiemap:

```bash
./build.sh
open ../LumaView.app
```

`./build.sh --host` bouwt alleen voor de architectuur van de huidige Mac. Gegenereerde bestanden komen standaard in `.build/`. `LUMAVIEW_WORK_ROOT` wijzigt deze map; `LUMAVIEW_APP_PATH` wijzigt het uitvoerpad van de app.

## Beperkingen en privacy

De app leest lokale bestanden, uploadt niets naar de cloud en wijzigt geen originelen. Er is geen editor, laagbewerking, bibliotheekdatabase of cloudsynchronisatie. Grote afbeeldingen kunnen een verkleinde voorvertoning gebruiken; inzoomen herstelt geen details die daarin ontbreken. Niet elke codec wordt gegarandeerd ondersteund. Bestanden met DRM, beschadigde bestanden en niet-ondersteunde bestanden kunnen mislukken. Conversies gebruiken lokale schijfcache en kunnen tijd kosten.

Bekijk de [technische formaatondersteuning](../../FORMATS.md), in het Chinees, en de kennisgevingen over [mediatools van derden](../../ThirdParty/README.md) en [Ghostscript](../../ThirdParty/README-Ghostscript.md).
