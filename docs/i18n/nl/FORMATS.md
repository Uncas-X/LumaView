# Formaten en voorvertoningen

<!-- doc-navigation:start -->
[Documentatie](INDEX.md) · [简体中文](../zh-Hans/FORMATS.md) · [繁體中文](../zh-Hant/FORMATS.md) · [English](../en/FORMATS.md) · [日本語](../ja/FORMATS.md) · [한국어](../ko/FORMATS.md) · [Français](../fr/FORMATS.md) · [Deutsch](../de/FORMATS.md) · [Español](../es/FORMATS.md) · [Italiano](../it/FORMATS.md) · [Português (Brasil)](../pt-BR/FORMATS.md) · [Русский](../ru/FORMATS.md) · [العربية](../ar/FORMATS.md) · [हिन्दी](../hi/FORMATS.md) · [Türkçe](../tr/FORMATS.md) · **Nederlands** · [Polski](../pl/FORMATS.md)
<!-- doc-navigation:end -->


De formaatcatalogus van LumaView 1.7.2 bevat 72 groepen afbeeldingen, vectoren / documenten, video en audio. De catalogus dient voor bestandsherkenning en standaardapps, niet als afzonderlijk geteste compatibiliteitslijst. Dezelfde extensie kan andere coderingen bevatten; openen hangt af van inhoud, systeemmogelijkheden en ingebouwde decoders.

## Afbeeldingen

| Categorie | Formaatvoorbeelden |
| --- | --- |
| Gangbare afbeeldingen | JPEG, PNG / APNG, GIF, TIFF, BMP, HEIC / HEIF, WebP |
| Overige afbeeldingen | AVIF, JPEG XL, JPEG 2000, ICO / CUR / ICNS, PSD / PSB, TGA, HDR / OpenEXR, Netpbm |
| Camera-RAW | DNG, Canon CR2 / CR3 / CRW, Nikon NEF / NRW, Sony ARW / SR2 / SRF, plus ORF, RAF, RW2, PEF, SRW |

macOS ImageIO decodeert afbeeldingen. De tabel noemt kandidaten uit de catalogus; met name RAW, nieuwe coderingen en professionele formaten variëren per systeemversie. Er is geen afzonderlijk gebundelde RAW-decoder. GIF ondersteunt animatie, TIFF meerdere pagina's; andere samengestelde formaten zonder paginering tonen alleen het eerste beeld.

Transparante delen van PNG / APNG, GIF, PSD / PSB en andere rasters tonen consequent de huidige achtergrond, zonder grijs-wit schaakbord. De schaduw volgt werkelijke pixeltransparantie, inclusief aparte zachte maskers en ieder animatieframe, zonder rechthoekige schaduw of rand aan leeg canvas. Dit geldt alleen voor bekijken; kopieën behouden oorspronkelijke transparantie zonder weergaveschaduw. PDF, SVG en andere vectordocumenten volgen het witte-papierbeleid hieronder.

**Photoshop PSD / PSB:** leest de ingesloten composiet voor hoofdbeeld, miniatuur en kopiëren, zonder Photoshop-lagen te reconstrueren of bewerken. Als expliciet geen compatibele composiet is opgeslagen, wordt gevraagd opnieuw op te slaan met ‘Compatibiliteit maximaliseren’. PSD / PSB zijn bestandsversies 1 / 2; volgens de [Adobe-specificatie](https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/) is de maximale zijde respectievelijk 30,000 / 300,000 pixels.

112 basiscoderingscombinaties zijn getest: zowel PSD als PSB met grijs met één/extra kanalen, RGB met drie/extra kanalen op 8 / 16 / 32 bit, en CMYK op 8 / 16 bit. Iedere combinatie omvat ongecomprimeerd, PackBits RLE, ZIP en ZIP prediction. Nog 128 grijs/RGB-voorbeelden met echte laagrecords testen het onderscheid tussen gebruikersalpha en composiettransparantie op 8 / 16 / 32 bit, met positieve/negatieve laagaantallen, globale Lr16/Lr32-records, transparantiemarkeringen en ongecomprimeerde/ZIP-codering. Ook een begrensde PSB-voorvertoning van 300,000 × 128 pixels, hoofdbeeld en miniaturen zijn getest. Deze matrixvoorbeelden zijn uit de specificatie gegenereerd. 1.7.1 testte daarnaast drie echte PSB's van circa 108–123 MiB met lagen, transparante composieten en ICC. Dit bewijst niet dat elke Photoshop-export is geverifieerd.

De filmstrip verkiest de geldige Photoshop RGB JPEG-miniatuur (resource 1036) en controleert codering, afmetingen, verhouding en lengte. Bij ontbrekende, beschadigde of niet-ondersteunde voorbeelden wordt de composiet gebruikt. Ingesloten voorbeelden zijn meestal klein en alleen voor de filmstrip; het hoofdbeeld leest altijd de compatibele composiet. RLE wordt in blokken tot 64 KiB gelezen, zonder een bestandslezing per compressiemarker; annuleren blijft mogelijk over blokgrenzen en bij lange no-op-reeksen.

ZIP, RLE met hoge bitdiepte, grote beelden en extra kanalen gebruiken de ingebouwde regelgewijze terugvallezer, gevolgd door ImageIO-kleurinterpretatie. Expliciete composiettransparantie wordt uitgelezen; RGB/grijs verwijdert de witte composietondergrond en voegt een apart masker toe. Zonder verklaring worden alleen basiskleuren getoond en opgeslagen selecties niet als transparantie behandeld. Meerdere alpha's, steunkleurkanalen, CMYK-transparantie en complexe maskers zijn niet volledig getest; gelijkheid met Photoshop-laagcompositie is niet gegarandeerd. De terugval bewaart het eerste ingesloten ICC-profiel tot 4 MiB voor systeemverwerking. Als het systeem een kleine geldige ICC-composiet weigert, worden pixels apart gedecodeerd en het gevalideerde oorspronkelijke ICC met overeenkomend model en componenten opnieuw aangehecht, niet weggegooid. Grotere profielen worden overgeslagen, mogelijk met standaardkleurinterpretatie. 32-bitdata dient voor voorvertoning, zonder volledige Photoshop HDR-toonregeling. Lab, geïndexeerde kleuren, duotoon en andere speciale modi vallen buiten de testmatrix; openen hangt af van structuur en systeemdecoder. Voor 1-bit PackBits bestaat een aparte native decodeertest met klein beeld.

Grote afbeeldingen worden niet enkel wegens meer dan 150 miljoen pixels geweigerd. Het geheugenbudget levert een voorbeeld van maximaal 8192 pixels langs de lange zijde en circa 32 miljoen pixels totaal, mogelijk lager. Informatie bewaart bronafmetingen en oriëntatie en markeert verkleinde voorvertoningen. Zoom volgt bronafmetingen; vergroten levert geen nog niet gedecodeerde brondetails. Beschadigde of onvolledig decodeerbare bestanden geven nog steeds fouten.

## Vectoren en documenten

| Formaat | Huidig gedrag |
| --- | --- |
| SVG | Offline systeem-vectorweergave, bijgewerkt bij zoomen; herkende standaard SVG DTD-verklaringen zijn toegestaan zonder DTD te laden. Aangepaste/interne DTD's, scripts, eventhandlers en externe bronnen worden geweigerd; sommige complexe of dynamische SVG's werken niet. |
| PDF | Paginaminiaturen, voortgang, nummers, focus en toetsenbordnavigatie; tekent op de huidige schaal met behoud van uitsnede en paginarichting; geen documentbewerking. |
| AI | PDF-compatibele gegevens worden direct getoond, met meerdere pagina's / tekengebieden. Oude PostScript AI wordt door ingebouwde Ghostscript naar vector-PDF omgezet; alleen propriëtaire Illustrator-data is niet gegarandeerd bruikbaar. |
| EPS / PostScript | Ingebouwde Ghostscript 10.08.0 zet de volledige tekening om naar PDF met paden, tekst en ingesloten afbeeldingen en toont die op het vectorcanvas; ondersteunt meerbladige PS. Bij mislukte interpretatie kan DOS EPS met geldige TIFF terugvallen op een als raster gemarkeerd voorbeeld. Bitmaps behouden hun bronlimiet; onbeschikbare niet-ingesloten fonts kunnen vervangen worden. |

Het hoofdcanvas bewaart PDF / SVG-bronnen en tekent het zichtbare gebied op huidige schaal in tegels van 512 pixels, tot 3200% zoom. Bij paginawisseling wordt eerst op de achtergrond een volledige schermgeschikte basis voorbereid; na een overgang van de hele pagina vult de oorspronkelijke vectorlaag details op huidige schaal aan, zonder blokgewijs verschijnende lege gebieden. De basis is maximaal 4096 pixels langs de lange zijde en beperkt de vectorscherpte niet. Documentpapier is wit, zonder schaakbord; ingesloten foto's blijven brongebonden. Iedere TIFF-pagina gebruikt dezelfde begrensde rastervoorvertoning als grote afbeeldingen. Versleutelde, niet-ontgrendelde PDF's kunnen niet direct worden bekeken; er is geen wachtwoordinvoer. Rendering wijzigt geen originelen.

PDF / PDF-compatibele AI ondersteunt rechtsklik-kopie van de aangeklikte bitmap of hele pagina. Gangbare XObject, inline-afbeeldingen, geneste Form, uitsneden en oriëntatie worden ondersteund. Complexe maskers of kleurruimten gebruiken het gerenderde zichtbare gebied. Speciale structuren zoals bitmaps in Pattern of pagina's boven het scanbudget kunnen aparte kopieën verhinderen. Uitvoer is PNG/TIFF met maximaal 8192 pixels lange zijde en circa 32 miljoen pixels; het origineel blijft gelijk.

## Video en audio

| Categorie | Voorbeelden in de catalogus |
| --- | --- |
| Gangbare videocontainers | MP4 / M4V, MOV, MKV, WebM, AVI, FLV, WMV / ASF, MPEG, TS / M2TS, 3GP |
| Overige video en bitstreams | OGV, RM / RMVB, VOB, MOD / TOD, Motion JPEG, MXF, DV, NUT, NSV, AMV, Bink / Smacker, plus H.264, HEVC, VVC, IVF, Y4M-streams |
| Gangbare audio | MP3, AAC, M4A, WAV, AIFF, CAF, FLAC, Ogg / Vorbis, Opus, WMA |
| Overige audio | Speex, APE, WavPack, TTA, TAK, Shorten, AC-3 / E-AC-3 / TrueHD, DTS, AMR, AU / SND, RealAudio, DSD, MKA, Musepack, GSM / QCP, IFF Audio |

Eerst wordt AVFoundation geprobeerd. Als rechtstreeks afspelen niet lukt, worden gebundelde FFmpeg 9.0.2 / ffprobe gebruikt, met statisch gekoppelde dav1d 1.5.3 voor AV1. Geschikte video probeert eerst een andere container met behoud van codering; daarna pas een systeemcompatibele codering. Ook audio kan compatibel worden voorbereid.

Voorbereiding is lokaal, netwerkfuncties zijn uitgeschakeld en extra installatie is niet nodig. Het hele bestand wordt eerst verwerkt; onmiddellijk afspelen is niet gegarandeerd. De interface toont voortgang, een ander bestand of sluiten annuleert. Transcoderen kan beeld-, geluid- of kleurkwaliteit veranderen; het origineel blijft intact. Snelheid bij hoge resolutie, framerate, complexe codering en lange bestanden hangt af van het apparaat.

De cache ruimt automatisch op met doel 2 GB; gebruikte bestanden blijven behouden, dus dit is geen harde totale limiet. Eén voorbereid bestand is maximaal 8 GB en minimaal 512 MB vrije schijfruimte blijft nodig; overschrijding stopt met foutmelding. Opnieuw openen kan geldige cache hergebruiken.

DRM, beschadiging, niet-meegeleverde externe decoders, propriëtaire coderingen en sommige bijzondere containers kunnen afspelen verhinderen. Zeldzame formaten staan in de catalogus, maar er is geen belofte dat alles werkt of iedere coderingscombinatie is getest. Geen beheer van externe ondertitels, schijfmenu's of streaming.

## Audiohoezen en golfvormen

Het hoofdbeeld verkiest ingesloten hoezen uit het origineel: eerst native metadata, zo nodig attached picture via het ingebouwde hulpmiddel. Hoezen worden tot 2048 pixels lange zijde gedecodeerd; fouten vallen terug op de golfvorm. Zonder ingesloten hoes wordt niets gedownload en geen cover.jpg uit dezelfde map gelezen.

Zonder hoes wordt uit werkelijke gedecodeerde samples een piekenvelop van de hele audio gemaakt, met maximaal 4096 sample-intervallen. Iedere PCM-buffer is begrensd; ook lange audio wordt niet volledig in geheugen geladen. Compatibele audio gebruikt het voorbereide lokale bestand voor de golfvorm. Dit is een overzicht van de hele opname, geen realtime spectrum; afspelen gaat tijdens generatie verder. Bestandswissel of sluiten annuleert analyse, late resultaten overschrijven het huidige bestand niet. Filmstripduur wordt onafhankelijk asynchroon gelezen zonder ieder bestand te kiezen; audio en video gebruiken `▶ Duur`.

## Standaardapp instellen

Via **LumaView → Standaardapp…** of `⌘,` kiest u formaatgroepen en past ze toe. Werkelijke systeemkoppelingen worden bij openen, heractivering en afronding gelezen en blijven na herstart bestaan. Een vinkje betekent alle typen bij de huidige app; een streepje een deel of een andere LumaView-kopie. ‘Alle formaten selecteren’ omvat iedere categorie ongeacht zoeken; ‘Alles selecteren’ per groep alleen die categorie. Niet-toegepaste vinkjes zijn een concept; wissen trekt geschreven koppelingen niet in. Het systeem kan extensies met dezelfde type-ID als één bestandstype zien, zodat sommige samen veranderen.

De interface leest resultaten terug en meldt mislukte formaten. Annuleren stopt alleen nog niet uitgevoerde wijzigingen, reeds uitgevoerde worden niet automatisch teruggedraaid. Herstellen kan in Finder via ‘Toon info → Open met → Wijzig alles’, met de oorspronkelijke app.
