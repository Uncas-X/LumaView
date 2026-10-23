> I nomi dei file dei campioni personali nei record storici di convalida sono stati resi anonimi. I dati e i risultati del test sono invariati.

<!-- doc-navigation:start -->
[Documentazione](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · **Italiano** · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# Record di convalida LumaView 1.7.1

Versione 1.7.1, build 13. 2026-10-22, macOS 15.7.9 / Intel. L'app e i tre strumenti in bundle hanno superato i controlli dell'architettura arm64 + x86_64 e della firma locale; questo round non è stato eseguito sull'hardware Apple Silicon.

## Problemi individuati e risolti

I tre file PSB dell’utente erano 8-bit RGB, file RLE a quattro canali con trasparenza composita, circa 108–123 MiB ciascuno. La maggior parte di ciascun file è costituita da dati di livello che possono essere saltati direttamente; le tele principali contengono circa 8.5–9.6 megapixel.

1. Il vecchio decodificatore riga per riga chiamava FileHandle per ciascun marcatore e valore PackBits, producendo molte piccole letture e lasciando le code dell'immagine principale e delle miniature occupate troppo a lungo. Ora legge blocchi fino a 64 KiB, preservando lo stato literal/run e i controlli dei limiti tra i blocchi. I dati lunghi no-op rimangono annullabili. ZIP inverte la previsione solo per le righe campionate, convalidando comunque l'intero flusso compresso.
2. Tutti e tre i file hanno una miniatura JPEG RGB valida nella risorsa 1036. La barra delle miniature ora lo preferisce, verificando formato, dimensioni, proporzioni e lunghezza compressa; l'immagine principale decodifica sempre il vero composito. Anteprime non valide, risorse BGR meno recenti o anteprime mancanti ricadono nel composito.
3. Il sistema ImageIO rifiuta alcuni piccoli compositi PSD che trasportano un RGB generico valido ICC. Il precedente fallback ha quindi restituito miniature vuote. Ora decodifica i pixel separatamente e quindi allega l'originale verificato ICC se il modello di colore e il conteggio dei componenti corrispondono, anziché scartare il profilo. I file originali ICC corrispondono allo standard di sistema Generic RGB Profile. I file di test di regressione sono stati generati dal profilo del sistema; le foto degli utenti non sono state aggiunte alla fonte.
4. La vista principale PSB riutilizza le informazioni dell'intestazione analizzate ed evita un'ulteriore scansione del livello ImageIO per i metadati. Le dimensioni originali, la trasparenza e la qualità dell'immagine principale vengono mantenute.

## Test sui tre file originali

Queste sono misurazioni locali su questo Mac, influenzate dal carico del sistema e dalla cache dei file, non garanzie di prestazioni per ogni dispositivo. Sia i vecchi che i nuovi decoder utilizzavano una compilazione ottimizzata.

| File | Dimensioni originali | Vecchia decodifica dell'immagine principale | Nuova decodifica dell'immagine principale | Nuova decodifica miniatura composita (senza anteprima incorporata) |
| --- | --- | --- | --- | --- |
| Campione A | 2582 × 3318 | Test annullato dopo più di 15 secondi | 0.68 secondi | 0.039 secondi |
| Campione B | 2610 × 3307 | 14.35 secondi | 0.65 secondi | 0.028 secondi |
| Campione C | 2843 × 3361 | Test annullato dopo più di 15 secondi | 0.70 secondi | 0.028 secondi |

Richiesta di tre miniature contemporaneamente tramite il vero ImageLoader completata in circa 0.06 secondi. Le immagini principali complete hanno impiegato circa 0.90 / 0.65 / 0.74 secondi attraverso il caricatore. La vecchia versione riportava tutte e tre le miniature composite come unsupported; la nuova versione è riuscita su tutti e tre. I valori SHA-256 degli originali corrispondevano byte per byte prima e dopo il test; l’app non ha modificato i file originali.

## I controlli sono stati superati in questo round

| Verifica | Risultato |
| --- | --- |
| Codifica PSD / PSB e composito trasparente | 712 / 712 |
| Prestazioni RLE, anteprime incorporate, ICC, limiti dei blocchi, annullamento | 54 / 54 |
| Integrazione reale ImageLoader per tre PSB originali | 21 / 21 |
| 443-file pellicola, cache, callback non validi | 37 / 37 |
| Richieste e annullamento di miniature indipendenti | 13 / 13 |
| Libreria di immagini e decodifica del sistema | 78 / 78 |
| Menu contestuale e copia dell'app di rilascio ottimizzati installati | 28 / 28 |
| Totale | 943 / 943 |

I nuovi test coprono valori letterali densi di un byte, limiti 64 KiB, annullamento durante lunghe sequenze no-op, dati di troncamento e fuori limite, contenuti corretti distinti per miniature incorporate e immagini principali, ICC, trasparenza e piccoli fattori di zoom non interi. Le combinazioni di codifica 112 esistenti e i 128 file strutturali con marcatori di trasparenza dei livelli continuano a passare. I controlli della barra delle miniature coprono il passaggio rapido, l’annullamento fuori schermo e la prevenzione di vecchi callback che contaminano l'elenco corrente.

Gli elenchi completi di file e gli hash dell'app installata e di `outputs/LumaView.app` corrispondevano ed entrambi hanno superato `codesign --verify --deep --strict`. È stato eseguito il backup del vecchio ZIP prima dell'installazione; le associazioni di apertura predefinite non sono state modificate. Il ZIP consegnato è stato controllato separatamente per CRC e versione. Il report storico completo 1.7.0 rimane in `Tests/Release-1.7.0.md`; i suoi controlli che non sono stati rieseguiti non sono inclusi in questo round.

Eseguibile principale SHA-256: `cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`.

## Registri

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
