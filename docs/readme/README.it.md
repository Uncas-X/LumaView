# LumaView — Italiano

<!-- language-navigation:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · **Italiano** · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- language-navigation:end -->

Guida introduttiva a **LumaView 1.7.2 (build 14)**. Manuale completo in [inglese](README.en.md) o in [cinese](../../README.md).

LumaView è un visualizzatore nativo per macOS dedicato a immagini, video, audio e documenti multipagina. Si ispira alla navigazione rapida di Picasa Photo Viewer, ma ha un nome proprio e un’icona originale, senza affiliazione con Google. È pensato per consultare i file, non per modificarli o gestire una libreria fotografica.

## Download e installazione

Scarica [LumaView per macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip) oppure consulta [tutte le versioni](https://github.com/Uncas-X/LumaView/releases). L’app universale supporta Intel e Apple Silicon e richiede **macOS 13 o successivo**.

Estrai l’archivio e trascina `LumaView.app` nella cartella Applicazioni. L’app usa una firma locale ad hoc e non è stata autenticata tramite il servizio di notarizzazione Apple. Se macOS ne blocca l’avvio, verifica la provenienza e segui le indicazioni in Privacy e sicurezza per consentirne l’apertura.

## Primi passi

Trascina un file o una cartella nella finestra, oppure premi `Cmd+O`. Aprendo un singolo file puoi scorrere anche i contenuti multimediali vicini nella stessa cartella. La scansione riguarda solo il livello corrente e non include le sottocartelle.

- Striscia di miniature, zoom, spostamento, rotazione, schermo intero, transizioni fluide e sfondo traslucido con effetto vetro satinato.
- Le aree trasparenti delle immagini raster PNG, GIF, PSD e PSB restano trasparenti, con ombre che seguono il contenuto. Le pagine dei documenti hanno uno sfondo di carta bianca. PSD/PSB utilizzano l’immagine composita di compatibilità salvata, senza modificare i livelli.
- Video e audio usano prima la riproduzione nativa, con FFmpeg incluso come alternativa per la compatibilità. L’audio mostra la copertina incorporata oppure, se assente, una forma d’onda.
- Navigazione tra le pagine di PDF, AI compatibili con PDF e TIFF multipagina. Rendering vettoriale di SVG, EPS/PS supportati e AI meno recenti. EPS/PS vengono elaborati con Ghostscript incluso; le bitmap incorporate mantengono i limiti della risoluzione originale.
- Con un clic destro puoi aprire il file con un’altra app, mostrarlo nel Finder e copiare l’immagine, il fotogramma corrente, una pagina PDF o un’immagine incorporata nel PDF, quando supportata.
- Riproduzione/pausa e arresto dei contenuti multimediali sono separati dalla presentazione. Le impostazioni permettono di associare i formati a LumaView e scegliere tra 16 lingue. Per impostazione predefinita, la lingua segue il sistema.

## Scorciatoie

| Tasto | Azione |
|---|---|
| `Cmd+O` | Aprire un file o una cartella |
| `←` / `→` | File o pagina precedente/successivo secondo il focus |
| `↑` / `↓` | Nei documenti multipagina, spostare il focus su pagine/file |
| Rotellina, gesto di pizzicamento, `+` / `-` | Ingrandire/ridurre |
| `0`; `1` | Adattare alla finestra; alternare 100%/adattamento |
| `Cmd+R`; `F` | Ruotare; schermo intero |
| `P`; `S` | Riproduzione/pausa del contenuto multimediale; arresto |
| `Cmd+4` | Controllare la presentazione |
| `Cmd+C` | Copiare l’immagine, il fotogramma corrente o la pagina |

**Spazio cambia lo sfondo**, senza controllare la riproduzione.

## Compilazione

Installa Xcode o gli strumenti da riga di comando Swift, poi esegui dalla radice del repository:

```bash
./build.sh
open ../LumaView.app
```

`./build.sh --host` compila soltanto per l’architettura del Mac attuale. I file intermedi vengono salvati in `.build/`. `LUMAVIEW_WORK_ROOT` modifica questa directory, mentre `LUMAVIEW_APP_PATH` cambia il percorso dell’app generata. I percorsi si riferiscono alla radice del repository, non alla cartella di questa guida. Sono inclusi gli strumenti multimediali necessari e i relativi archivi di sorgenti e licenze.

## Limiti e privacy

LumaView legge file locali, senza caricarli nel cloud né modificare gli originali. Non include editor, modifica dei livelli, database della libreria fotografica o sincronizzazione cloud. Le immagini grandi possono usare un’anteprima ridotta: lo zoom non ripristina i dettagli omessi. Alcune conversioni devono elaborare l’intero file prima della riproduzione e richiedono tempo e cache locale. Non è garantito ogni codec; file protetti da DRM, danneggiati o non supportati potrebbero non aprirsi.

Consulta i [formati supportati, in cinese](../../FORMATS.md), le [informazioni sui componenti di terze parti](../../ThirdParty/README.md) e le [informazioni su Ghostscript](../../ThirdParty/README-Ghostscript.md).
