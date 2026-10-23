# LumaView 1.7.2

<!-- doc-navigation:start -->
[Documentazione](../i18n/it/INDEX.md) · [简体中文](../i18n/zh-Hans/README.md) · [繁體中文](../i18n/zh-Hant/README.md) · [English](../i18n/en/README.md) · [日本語](../i18n/ja/README.md) · [한국어](../i18n/ko/README.md) · [Français](../i18n/fr/README.md) · [Deutsch](../i18n/de/README.md) · [Español](../i18n/es/README.md) · **Italiano** · [Português (Brasil)](../i18n/pt-BR/README.md) · [Русский](../i18n/ru/README.md) · [العربية](../i18n/ar/README.md) · [हिन्दी](../i18n/hi/README.md) · [Türkçe](../i18n/tr/README.md) · [Nederlands](../i18n/nl/README.md) · [Polski](../i18n/pl/README.md)
<!-- doc-navigation:end -->


**[Scarica l'app macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)** · [Versioni e note sulla versione](https://github.com/Uncas-X/LumaView/releases)

Richiede macOS 13+. Lo stesso pacchetto supporta Intel e Apple Silicon. Estrai lo ZIP scaricato e trascina `LumaView.app` in Applicazioni per installarlo.

Un visualizzatore multimediale nativo per macOS ispirato alle abitudini di visualizzazione rapida di Picasa Photo Viewer, con navigazione, zoom, panoramica, rotazione, sequenza di immagini, schermo intero e presentazioni nella stessa cartella. La versione 1.5 ha aggiunto copertine audio e forme d'onda reali, navigazione di documenti multipagina, una tela vettoriale ridisegnata con lo zoom corrente e impostazioni della lingua che seguono il sistema per impostazione predefinita. Utilizza un nome indipendente e un'icona originale e non pretende di riprodurre ogni funzionalità o interazione delle versioni storiche di Picasa.

La versione 1.7.2 unifica la trasparenza delle immagini: aree trasparenti di immagini raster come PNG, GIF e PSD / PSB rivelano lo sfondo di visualizzazione corrente. Le ombre seguono il contorno e l'opacità effettivi dell'immagine; non c'è scacchiera o ombra rettangolare attorno all'intera tela trasparente. Documenti come PDF mantengono uno sfondo di carta bianca.

Rimangono i miglioramenti dell'anteprima PSD / PSB rispetto a 1.7.1: la barra delle miniature preferisce un JPEG incorporato valido, mentre la vista principale decodifica l'effettivo composito di compatibilità. RLE utilizza letture in blocchi ed è stato risolto un problema che impediva la generazione di miniature per alcuni piccoli compositi con profili ICC.

## Utilizzo e installazione

Richiede macOS 13 o successivo, con supporto per Intel e Apple Silicon.

1. Scarica `LumaView-macOS.zip` da [Releases](https://github.com/Uncas-X/LumaView/releases), estrailo, trascina `LumaView.app` in Applicazioni e aprilo.
2. Rilascia un'immagine, un video, un file audio o una cartella sull'app oppure premi `⌘O` per selezionare i file. L'apertura di un file elenca i media nella stessa cartella; selezionando più file si sfoglia quella selezione. Le scansioni delle cartelle coprono solo il livello corrente e non si ripetono nelle sottocartelle.
3. Nel Finder, puoi anche fare clic con il pulsante destro del mouse su un file e scegliere Apri con → LumaView.

Le build locali utilizzano una firma ad hoc e non sono state autenticate da Apple. Se Gatekeeper blocca una copia scaricata su un altro Mac, verificane l'origine e utilizza l'opzione Privacy e sicurezza del sistema per consentirne l'apertura.

## Impostazioni dell’applicazione predefinita

Scegli **LumaView → Applicazione predefinita…**, premi `⌘,` o apri le impostazioni dal menu Altro. I formati sono raggruppati in immagini, vettori/documenti, video e audio. Cerca e seleziona i formati, quindi fai clic su Imposta come predefinito per i formati selezionati. Ogni volta che la finestra di dialogo si apre, l'app diventa nuovamente attiva o le modifiche terminano, legge le effettive associazioni di sistema: un segno di spunta significa che ogni tipo nel gruppo si apre con questa copia di LumaView; un trattino significa che solo alcuni tipi lo fanno, oppure puntano comunque a un'altra copia. Le associazioni di sistema persistono durante i riavvii; le selezioni non applicate non vengono presentate come impostazioni applicate correttamente. Seleziona Tutti i formati in alto copre tutte le immagini, i documenti vettoriali, i video e l'audio indipendentemente dal filtro di ricerca; le singole categorie possono ancora essere selezionate separatamente. Cancella cancella solo la selezione corrente e non rimuove le impostazioni predefinite del sistema esistenti.

Le impostazioni mostrano l'avanzamento e rileggono ogni risultato dal sistema. Annulla interrompe le modifiche successive; rimangono le modifiche completate. L'elenco dei formati rappresenta associazioni di file selezionabili, non un'affermazione che ogni codifica interna o file sia stato testato. Vedi [Formati e anteprime](../i18n/it/FORMATS.md) per i dettagli.

## Visualizzazione e riproduzione

L'apertura del primo file espande la finestra nell'area disponibile della schermata corrente. Premi `F` per la visualizzazione a schermo intero. Fare clic sulla barra delle miniature in basso per cambiare file. I controlli si nascondono dopo che il puntatore rimane per un po' nell'area di visualizzazione e riappaiono quando si sposta.

La versione 1.5.2 ha risolto il problema con le miniature vuote o che lampeggiavano ripetutamente durante la navigazione estesa di cartelle di grandi dimensioni: le miniature visibili vengono conservate in modo indipendente e il caricamento fuori schermo viene annullato immediatamente. I risultati della cartella precedente non possono essere inseriti nel nuovo elenco. I file non decodificabili mostrano un segnaposto stabile e possono essere riprovati quando il loro intervallo viene rivisitato.

Immagini e video supportano lo zoom, la panoramica, la rotazione e lo schermo intero. I cambi di finestra, i cambiamenti di immagine, lo zoom e la rotazione utilizzano transizioni brevi e fluide che ulteriori input possono interrompere. L'attivazione dell'impostazione Riduci movimento del sistema disabilita queste transizioni personalizzate mentre le immagini animate continuano la riproduzione. Lo sfondo predefinito è il vetro smerigliato traslucido; premi Spazio per scorrere sfondi smerigliati, scuri e chiari.

La trasparenza raster segue una regola: mostra lo sfondo corrente e proietta ombre solo dai pixel contenenti contenuto visibile, mantenendo l'opacità dei bordi traslucidi. Le ombre GIF / APNG cambiano con ogni fotogramma. La copia di un'immagine preserva i pixel trasparenti originali ed esclude lo sfondo e l'ombra del visualizzatore.

I controlli di riproduzione, arresto, posizione e volume audio/video vengono visualizzati sopra la barra delle miniature. Il contenuto multimediale viene riprodotto automaticamente quando viene aperto e rimane alla fine una volta terminato; premi `P` per riprodurre o `S` per interrompere e tornare all'inizio. Il pulsante della presentazione di seguito è indipendente dalla riproduzione multimediale: dopo che `⌘4` avvia la riproduzione continua, le immagini avanzano all'intervallo selezionato, mentre l'audio/video termina prima di avanzare. La riproduzione di un singolo file audio/video non passa automaticamente all'elemento successivo.

Per prima cosa viene tentata la riproduzione nativa di macOS. Se il sistema non è in grado di riprodurre il file direttamente, i bundle FFmpeg universali 9.0.2 e dav1d 1.5.3 preparano un file compatibile localmente, tentando prima una modifica del contenitore dove appropriato e quindi la transcodifica. Non è necessario alcun lettore separato, Homebrew o pacchetto di codec e non viene utilizzato l'accesso alla rete. La riproduzione della compatibilità attende la preparazione dell'intero file, mostrando l'avanzamento; il cambio di file o la chiusura della finestra annulla la preparazione. La preparazione di un video lungo per la prima volta può richiedere molto tempo e spazio su disco aggiuntivo.

Premi `C` o utilizza il menu Altro per configurare la ripetizione ciclica, il comportamento della rotellina, la chiusura con clic sullo sfondo, la sequenza, l'ordinamento e gli intervalli della presentazione (2, 3, 5, 8 o 10 secondi). La rotellina esegue lo zoom per impostazione predefinita; tieni premuto `Ctrl` per sfogliare temporaneamente i file. Se la rotellina è impostata per la navigazione, `Ctrl` esegue invece lo zoom temporaneamente. Facendo clic sullo sfondo all'esterno dell'immagine si chiude il visualizzatore per impostazione predefinita. Queste preferenze vengono memorizzate localmente.

## Menu contestuale e copia

Fare clic con il pulsante destro del mouse (o fare clic tenendo premuto il tasto Control) sulla vista principale per scegliere Apri con → Applicazione/Altra applicazione… o Mostra nel Finder. Apri con influisce solo su questa apertura e non modifica le associazioni predefinite. Entrambe le opzioni rimangono disponibili per i file non decodificabili.

- Immagini: scegli Copia immagine. Ciò preserva la rotazione della vista e i pixel trasparenti e copia l'intera immagine attualmente decodificata, senza acquisire le barre degli strumenti o solo la regione dello schermo ingrandita.
- Video: scegli Copia fotogramma corrente. Copia il fotogramma corrispondente al momento in cui si è aperto il menu contestuale, preservando l'orientamento del video e la rotazione della vista senza modificare la posizione o lo stato di riproduzione.
- PDF / AI compatibile con PDF: fare clic con il pulsante destro del mouse su una bitmap su una pagina per copiare questa immagine o scegliere Copia pagina corrente. Il rilevamento dell’immagine selezionata segue la posizione effettiva dopo lo zoom, la panoramica e la rotazione. Il testo normale e le regioni vettoriali non vengono trattati come immagini; maschere complesse o spazi colore utilizzano il risultato visibile dell'area dell'immagine, che può includere testo sovrapposto. Una pagina digitalizzata come immagine singola viene copiata come scansione completa.
- `⌘C` copia l'immagine, il fotogramma video o la pagina del documento corrente; l'audio non fornisce la copia delle immagini. Gli appunti ricevono PNG e TIFF. Il cambio di file/pagine o la chiusura del visualizzatore impedisce ai risultati della copia obsoleti di sovrascrivere gli appunti.

Le copie delle pagine dei documenti e delle immagini incorporate sono bitmap limitate a un lato più lungo di 8192 pixel e circa 32 megapixel; Le istruzioni vettoriali PDF/SVG non vengono inserite negli appunti. Se un'immagine di grandi dimensioni visualizza un'anteprima limitata, tale anteprima viene copiata. La scansione delle immagini PDF ha limiti di complessità: strutture speciali come le immagini all'interno dei riempimenti a motivo potrebbero non essere selezionabili individualmente, ma la pagina corrente può comunque essere copiata.

Le intestazioni standard SVG 1.0/1.1 vengono analizzate offline senza caricare DTD esterni. La versione 1.7 raggruppa Ghostscript 10.08.0 per convertire EPS/PostScript e AI basato su PostScript legacy in PDF mantenendo percorsi, testo e immagini incorporate. La vista principale ridisegna i vettori con lo zoom corrente; PS multipagina utilizza la navigazione della pagina esistente. Non è richiesta alcuna installazione aggiuntiva. Se la conversione fallisce ma l'EPS ha un TIFF incorporato valido, può ricorrere a quell'anteprima, chiaramente etichettata TIFF. Le immagini raster all'interno dell'originale non diventano vettori.

## Audio, documenti e lingue

L’audio mostra la copertina incorporata nella vista principale, quando disponibile. Altrimenti, i campioni effettivi vengono analizzati in modo asincrono per visualizzare una forma d'onda per l'intera traccia. Durante l'analisi viene visualizzato un segnaposto e non è necessario attendere la riproduzione. Le miniature audio e video utilizzano lo stesso badge `▶ durata` in basso a destra, con carattere, sfondo e posizione corrispondenti; prima che la durata sia disponibile, mostrano `▶ –:––`. La copertina proviene da metadati di file incorporati, senza effettuare ricerche nella rete o nei file vicini.

PDF, AI compatibile con PDF e TIFF multipagina supportano la navigazione tra le pagine. Sopra la barra delle miniature del file vengono visualizzate miniature di pagina più piccole, un cursore di avanzamento della pagina e i numeri di pagina corrente/totale. Premere `↑` per mettere a fuoco le pagine e `↓` per mettere a fuoco i file. La miniatura selezionata nella riga evidenziata ha un bordo arancione; l'altra riga mantiene la selezione con un bordo grigio. Non vengono visualizzate etichette aggiuntive di pagine/file. `←` / `→`, `J` / `K` e `Home` / `End` agiscono sul focus corrente. Anche facendo clic su una riga viene messa a fuoco. La navigazione tra le pagine si ferma alla prima e all'ultima pagina senza passare inaspettatamente a un altro file. I pulsanti inferiori del file precedente/successivo cambiano sempre i file. La navigazione tra le pagine rimane disponibile quando la barra delle miniature del file è nascosta.

PDF, SVG e AI compatibili con PDF disegnano la regione visibile dalle istruzioni vettoriali originali allo zoom corrente, invece di ingrandire un'anteprima fissa. Le aree dei documenti trasparenti utilizzano carta bianca comune, senza scacchiera. Il cambio di pagina prepara la nuova pagina completa e poi la mostra con una dissolvenza di entrata dell’intera pagina; il disegno dei dettagli vettoriali di sfondo non lascia i riquadri vuoti visualizzati uno alla volta. Le foto incorporate e altre bitmap rimangono limitate dalla loro risoluzione originale.

Scegli **LumaView → Lingua…**, disponibile anche nel menu Altro. L'impostazione predefinita segue il sistema, con supporto per cinese semplificato, cinese tradizionale, inglese, giapponese, coreano, francese, tedesco, spagnolo, italiano, portoghese, russo, arabo, hindi, turco, olandese e polacco. I menu delle app, le descrizioni comandi, l'impaginazione e le impostazioni si aggiornano immediatamente e la lingua selezionata viene salvata localmente. Le lingue di sistema non supportate ricadono nell'inglese; errori di decodifica non comuni possono apparire anche in inglese. I nomi dei file, i percorsi e il testo all'interno dei file rimangono invariati.

## Tastiera e mouse

| Azione | Scorciatoia/gesto |
| --- | --- |
| Elemento precedente/successivo (focus attuale) | `←` / `→`, o `J` / `K` |
| Mettere a fuoco pagine/file | `↑` / `↓` (documenti multipagina) |
| Primo/ultimo elemento | `Home` / `End` |
| Apri file o una cartella | `⌘O` |
| Impostazioni dell’applicazione predefinita | `⌘,` |
| Zoom | Rotella, pizzicamento del trackpad, `+` / `−`, `Page Up` / `Page Down` |
| Cambia temporaneamente il comportamento della rotellina | Tieni premuto `Ctrl` durante lo scorrimento |
| 100% / adatta alla finestra | Fare clic sull'immagine o `1` |
| Adatta alla finestra | `0` |
| Eseguire la panoramica di un'immagine o di un video ingrandito | Trascina la vista |
| Ruota la vista in senso orario | `⌘R` / `Ctrl+R`; aggiungere `Shift` per antiorario |
| Cambiare sfondo | Barra spaziatrice |
| Entra/esci dallo schermo intero | `F` / `⌃⌘F` / `F11` (quando non riservato dal sistema) |
| Riproduci/metti in pausa audio o video | `P` |
| Arresta i media e torna all'inizio | `S` |
| Avvia/arresta la presentazione e la riproduzione continua | `⌘4` |
| Tornare indietro / avanzare di 5 secondi nel contenuto | `Option + ←` / `Option + →` |
| Disattiva/attiva l'audio | `M` |
| Informazioni sul file | `I` / `⌘I` |
| Mostra/nascondi la barra delle miniature | `T` / `⌘T` |
| Più opzioni | `C` |
| Mostra il file corrente nel Finder | `⌘Return` |
| Metti in pausa la riproduzione, chiudi le informazioni, esci dallo schermo intero, chiudi la finestra | `Esc`, gestito in ordine in base allo stato corrente |
| Minimizza/chiudi/esci | `⌘M` / `⌘W` / `⌘Q` |

`P` controlla solo l'audio/video corrente, non le presentazioni di immagini. Aiuto → Tastiera e mouse fornisce anche una guida in-app.

## Copertura e limitazioni

- Le immagini utilizzano il sistema di decodifica ImageIO. Il supporto effettivo per JPEG, PNG, GIF, HEIC, TIFF, BMP, WebP, RAW e altri formati dipende dalla versione del sistema e dal contenuto del file.
- Le immagini molto grandi non vengono più rifiutate per il solo fatto di superare i 150 megapixel. Per limitare la memoria, è possibile eseguire il downsampling delle anteprime preservando le dimensioni originali e i metadati di orientamento. Lo zoom 100% viene comunque calcolato dalle dimensioni originali, ma non è possibile recuperare i dettagli dei pixel omessi dalla decodifica dell'anteprima.
- La visualizzazione vettoriale supporta SVG, PDF, AI compatibile con PDF ed EPS/PS/legacy AI elaborati dall'interprete in bundle. I file PDF / AI / PS multipagina supportano la navigazione; SVG rifiuta script e risorse esterne. Le bitmap incorporate mantengono i limiti di risoluzione originali e i caratteri non incorporati non disponibili potrebbero essere sostituiti.
- PostScript viene eseguito in un processo separato con SAFER e una sandbox di sistema, consentendo soltanto i file temporanei di ingresso e uscita predisposti e negando l'accesso alla rete. Un rapido cambio di file può annullare la conversione; le miniature e la vista principale condividono i risultati memorizzati nella cache completati. Ogni interpretazione è limitata a 90 secondi e 1 GB di output, con un obiettivo di pulizia della cache di 2 GB.
- Photoshop PSD / PSB mostra la composizione salvata nel file, senza modifica dei livelli. Le tele molto grandi utilizzano anteprime con budget di memoria e mantengono le dimensioni originali; vedere FORMATS.md per le modalità colore, la profondità di bit e la compressione supportate.
- La decodifica fallback in bundle espande la copertura audio/video, ma DRM, file danneggiati e codifiche proprietarie senza un decoder disponibile potrebbero comunque fallire. Un'estensione non garantisce che la codifica interna possa essere decodificata. Non tutti i formati, dispositivi o versioni di sistema sono stati testati individualmente.
- La cache di compatibilità ha una destinazione di pulizia 2 GB; i file attivi possono temporaneamente superarlo. Un singolo file preparato è limitato a 8 GB, con almeno 512 MB di spazio libero su disco riservato. La preparazione si interrompe e viene visualizzato un messaggio se lo spazio è insufficiente.
- TIFF supporta più pagine; altri formati di immagine composti senza impaginazione implementata mostrano la prima immagine. La rotazione della visualizzazione non riscrive mai gli originali. Non sono previste funzionalità di modifica, eliminazione, database di libreria, condivisione, sincronizzazione cloud e gestione dei sottotitoli esterni.
- L'app legge solo i media locali aperti dall'utente e la cartella che lo contiene. La riproduzione della compatibilità scrive su una cache locale; non invia contenuti multimediali a servizi online e non modifica gli originali.

Vedi [FORMATS.md](../i18n/it/FORMATS.md) per ulteriori esempi di formato e limiti di cache/anteprima.

## Compilare dal codice sorgente

Richiede Xcode o strumenti da riga di comando con il compilatore Swift. Il repository e il pacchetto sorgente includono strumenti multimediali universali Intel/Apple Silicon, quindi una build normale non richiede installazione o download separati di terze parti. Dopo la clonazione o il download, crea dalla root del repository contenente `build.sh`; il layout originale dell'area di lavoro di sviluppo non è richiesto.

```bash
cd /path/to/LumaView
./build.sh
open ../LumaView.app
```

L'impostazione predefinita produce un'app universale; `./build.sh --host` crea solo l'attuale architettura Mac. Per impostazione predefinita, l'app viene posizionata accanto alla directory di origine come `LumaView.app`; impostare `LUMAVIEW_APP_PATH` per un'altra destinazione. I file di lavoro per la compilazione e i test si trovano per impostazione predefinita in `.build/` all'interno del repository e possono essere riposizionati con `LUMAVIEW_WORK_ROOT`. Questi file generati sono esclusi da `.gitignore`.

Le build di test utilizzano `LUMAVIEW_TEST_BUILD=1 ./build.sh --host` per creare un'app LumaView Tests separata senza dichiarazioni di apertura dei file, impedendo alle copie di test di competere con l'app installata. Gli script di test dell'interfaccia utente utilizzano questa modalità per impostazione predefinita. Utilizza `LUMAVIEW_SKIP_TEST_BUILD=1` e `LUMAVIEW_TEST_APP_PATH` per selezionare un'app già creata.

FFmpeg è costruito sotto LGPL 2.1 o successivo e dav1d collegato staticamente utilizza BSD 2-Clause. Gli archivi sorgente, i checksum e le licenze corrispondenti accompagnano il pacchetto sorgente. La ricostruzione degli strumenti multimediali richiede Xcode Command Line Tools, Python 3, Meson 1.12.1 e Ninja 1.13.2; installa gli strumenti Python in un ambiente virtuale ed esegui `./tools/build-media-tools.sh`. Vedi [ThirdParty/README.md](../i18n/it/ThirdParty/README.md) per i passaggi e la configurazione della build. PostScript utilizza un eseguibile Ghostscript 10.08.0 separato (AGPL-3.0-or-later), con la sua licenza, il sorgente corrispondente completo e lo script di build inclusi. Le build di app normali utilizzano il componente universale in bundle; vedere la [guida Ghostscript](../i18n/it/ThirdParty/README-Ghostscript.md) per la ricostruzione.

## Fonte e validazione

- `Sources/`: interfaccia AppKit, canvas multimediale, caricamento raster e vettoriale, ciclo di vita audio/video, preparazione alla compatibilità e impostazioni predefinite dell'applicazione.
- `Resources/Localizations/`: stringhe della lingua e elenco delle chiavi di traduzione principali.
- `Resources/MediaFormats.json`: formato catalogo; `Resources/MediaTools/`: FFmpeg/ffprobe in bundle.
- `ThirdParty/sources/`, `Resources/ThirdPartyNotices/`: fonti e licenze corrispondenti dello strumento multimediale.
- `build.sh`: compilazione, creazione di pacchetti e firma locale di app universali; `tools/build-media-tools.sh`: ricostruzione degli strumenti multimediali.

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

I test delle unità di decodifica audio richiedono un FFmpeg di sviluppo con i relativi codificatori per generare campioni MP3 / FLAC / Opus. Imposta `LUMAVIEW_TEST_FFMPEG` sul suo percorso. I test dell'app e dell'interfaccia audio utilizzano solo componenti in bundle.

I controlli di integrazione dell'interfaccia utente richiedono una sessione attiva nel desktop grafico di macOS. Aprono l'app e controllano le interazioni utilizzando i media generati. I file di creazione e i rapporti di test salvati sono predefiniti su `.build/`; alcuni file di test utilizzati durante l’esecuzione utilizzano la directory temporanea del sistema. I test non leggono le foto personali per impostazione predefinita. I test di copia del menu contestuale utilizzano appunti con nome separato senza sostituire gli appunti correnti dell'utente. I test Apri con / Finder / applicazione predefinita utilizzano simulazioni e non modificano le associazioni di file. Vedere [TEST-RESULTS.txt](../i18n/it/TEST-RESULTS.md) per il record di convalida della versione consegnata.

I report salvati in `Tests/` sono record storici per le rispettive versioni, non prova che un nuovo checkout abbia superato automaticamente i test nell'ambiente corrente. I nomi dei campioni personali sono resi anonimi e i media originali non sono inclusi nel repository. I percorsi storici `work/` registrano le origini del test in quel momento e non sono directory richieste per le build correnti. Il repository conserva gli archivi di origine, i checksum e le licenze corrispondenti di terze parti, quindi il clone iniziale è relativamente grande.
