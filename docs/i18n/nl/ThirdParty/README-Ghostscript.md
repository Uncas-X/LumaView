# Ghostscript-documentconversie

<!-- doc-navigation:start -->
[Documentatie](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · **Nederlands** · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView gebruikt Ghostscript **10.08.0**, uitgegeven door Artifex op 2026-09-08, als apart lokaal programma om EPS en PostScript naar tijdelijke PDF om te zetten. PDF behoudt ondersteunde vectorpaden, tekst en verlopen. Al ingesloten rasterpixels blijven raster. Ghostscript wordt niet aan de Swift-app gekoppeld; Homebrew is niet nodig om deze meegeleverde executable te starten.

## Licentie en bijbehorende broncode

Ghostscript wordt verspreid onder de **GNU Affero General Public License versie 3 of later**, volgens de oorspronkelijke `LICENSE` van deze release. De volledige licentie, copyrightmelding, uitzondering voor fontinsluiting, Adobe CMap-meldingen en afhankelijkheidsmeldingen worden ongewijzigd in `Resources/ThirdPartyNotices/Ghostscript/` gekopieerd. Artifex biedt ook een aparte commerciële licentie; dit pakket bevat die niet. Zie de [officiële licentiepagina](https://www.ghostscript.com/licensing/index.html).

De exacte ongewijzigde bijbehorende bronrelease, inclusief afhankelijke bibliotheken en fonts, staat in `ThirdParty/sources/ghostscript-10.08.0.tar.xz`. De SHA-256 staat in `ThirdParty/sources/SHA256SUMS-Ghostscript`:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

Bronherkomst: [officiële releasepagina](https://www.ghostscript.com/releases/index.html) en [Artifex 10.08.0-bestanden](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). De checksum komt overeen met de gepubliceerde `.tar.xz`-checksum. Bronpakket en bouwscript begeleiden de LumaView-brondistributie. LumaView beperkt wijziging/vervanging van deze aparte tool of noodzakelijke reverse-engineering voor debugging niet aanvullend. Deze meldingen beschrijven de externe component; ze herlicentiëren de appbron niet.

## Herbouwen

Vereisten: macOS, Xcode Command Line Tools, meegeleverd bronarchief en standaard macOS-bouwgereedschap. Geen Homebrew-bibliotheken. Vanuit de LumaView-bronmap:

```sh
./tools/build-document-tools.sh
./build.sh
```

Het script verifieert het archief, bouwt Intel- en Apple Silicon-slices in aparte bronmappen, verwijdert lokale symbolen en combineert naar `Resources/DocumentTools/gs`. Beide richten zich op macOS 13.0 of later. Er wordt geen `make install` uitgevoerd en geen systeempakketbeheer gewijzigd. `LUMAVIEW_DOCUMENT_BUILD` kiest de tussenmap; `LUMAVIEW_DOCUMENT_JOBS` bepaalt make-parallellisme (standaard 4). Optioneel `x86_64` of `arm64` bouwt één architectuur. De appbuild ondertekent de gekopieerde executable samen met de app.

De executable bevat initialisatiecode, fonts, Adobe CMaps en ICC-profielen in het interne `%rom%`-bestandssysteem. Externe standaardzoekpaden zijn leeg. Alleen uitvoerapparaat `pdfwrite` is actief. Afdrukken/CUPS, X11, GTK, fontconfig, D-Bus, Tesseract/OCR, dynamische drivers, externe IJS en documentextractietools zijn uitgeschakeld. Alle decoder-/kleur-/fontbibliotheken komen uit het bijbehorende archief; dynamische koppeling beperkt zich tot Apple-systeembibliotheken. ROM en crosscompilatie staan in de [officiële bouwdocumentatie](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html).

LumaView start de interpreter met `-dSAFER`, specifieke invoer/uitvoer, een eigen tijdelijke werkmap, annulering en timeout. De procesomgeving mag geen gebruikersopties of bibliotheekpaden van Ghostscript erven. Voorbeeld voor gegenereerde vertrouwde testbestanden:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

Volledige opties staan in `tools/build-document-tools.sh`; het bronarchief is niet gepatcht. Native uitvoering kan alleen worden getest op architecturen die de bouwhost ondersteunt. Releasecontroles inspecteren beide Mach-O-slices en voeren een gegenereerde EPS met paden en tekst uit via de hostgeschikte slice, om vector- en tekstoperators in de PDF te bevestigen.
