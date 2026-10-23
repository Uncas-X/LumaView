> I nomi dei file dei campioni personali nei record storici di convalida sono stati resi anonimi. I dati e i risultati del test sono invariati.

<!-- doc-navigation:start -->
[Documentazione](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · **Italiano** · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# Record di convalida LumaView 1.7.0

Data: 2026-10-22 (Asia/Shanghai). Ambiente di prova: macOS 15.7.9, x86_64. L'app è destinata a macOS 13+ e tutti e quattro i file eseguibili sono binari universali Intel/Apple Silicon.

## Modifiche e risultati testati in questo round

- Ghostscript 10.08.0 incluso converte in background l’intero contenuto dei file EPS, PostScript e AI basati su PostScript legacy aperti direttamente. Il PDF conserva tracciati vettoriali, testo e immagini incorporate e viene passato all’area di disegno esistente. Gli utenti non necessitano né di un interprete separato né di una conversione manuale; lo zoom, la panoramica, la rotazione e la navigazione multipagina seguono le interazioni correnti. Il fallback TIFF incorporato viene ancora utilizzato se la conversione del vettore fallisce e il file fornisce un'anteprima; il fallback raster non è etichettato come vettore.
- L'allegato di esempio `sample-vector.eps` è stato testato utilizzando il suo contenuto PostScript completo. La scansione del PDF generato ha trovato **147,521 operazioni relative al percorso/gradiente, 59 operazioni di testo e 160 chiamate XObject**. Gli XObject qui vengono conteggiati come operazioni PDF `Do` e possono includere immagini o XObject Form; il numero non è un conteggio di immagini distinte. I test hanno confermato che i contenuti dei vettori reali sono stati preservati. I confronti SHA-256 tra EPS e `sample-vector.svg` prima e dopo i test hanno mostrato originali invariati.
- PostScript utilizza un processo annullabile separato, Ghostscript SAFER, e un sandbox del processo di sistema. L'input viene copiato in una directory temporanea privata; l'interprete non può leggere gli altri file dell’utente, scrivere su file esterni arbitrari o utilizzare pipe esterne. Superati i controlli di timeout, annullamento, riutilizzo da parte di più consumatori, input danneggiato e invalidamento della cache. I risultati completati vengono pubblicati in modo atomico, quindi i PDF parziali non riempiono le miniature. I test con visualizzatore reale hanno riguardato l'EPS con zoom vettoriale del 3200%, messa a fuoco su/giù e navigazione della pagina sinistra/destra in PS multipagina e il passaggio a PNG durante la conversione senza che un risultato tardivo sostituisse la visualizzazione corrente.
- `.psb` è stato aggiunto al gruppo Photoshop insieme a `.psd` per rilevamento, vista principale, miniature e impostazioni predefinite dell'applicazione. Viene letto un composito di compatibilità salvato e vengono mantenute le dimensioni originali della tela; i file di grandi dimensioni ricevono anteprime limitate in base alle esigenze di visualizzazione. La convalida ha riguardato **112 combinazioni di codifica, 128 file strutturali con livelli e marcatori di trasparenza, 1 grande PSB e 13 file di test danneggiati**. Il rilevamento della trasparenza composita utilizza il conteggio dei livelli e i marcatori Lr16/Lr32, Mtrn/Mt16/Mt32; i normali canali alfa extra non vengono confusi con la trasparenza composita. I test hanno riguardato valori di pixel trasparenti, rimozione dello sfondo bianco, coerenza della codifica, annullamento in righe lunghe e regressioni dell'integrazione principale/miniatura.
- La finestra di dialogo di apertura predefinita legge le associazioni di sistema effettive all'apertura, quando l'app si riattiva e dopo il completamento delle impostazioni batch. Le associazioni stesse persistono durante la ripartenza; le bozze non applicate non vengono visualizzate come riuscite. Un formato selezionato ha tutti i tipi assegnati a questa app; un trattino indica corrispondenze parziali o un'altra copia con lo stesso ID pacchetto, spiegato nel suggerimento. Cancella modifica solo la bozza; non revoca le impostazioni predefinite del sistema.
- Seleziona tutti i formati in alto seleziona immagini, vettori/documenti, video e audio contemporaneamente, inclusi i formati esterni ai risultati di ricerca. È comunque necessario fare clic sul pulsante Imposta per scrivere le associazioni. Il rilevamento, il successo parziale, la rilettura degli errori, la ricostruzione del controller, le differenze tra lo stato bozza e quello effettivo e la selezione totale sono stati testati con un backend simulato in memoria. I test non hanno modificato le applicazioni predefinite del sistema dell'utente.
- Le nuove impostazioni, PostScript e stringhe di Photoshop di questo round coprono tutte le 16 lingue. I segnaposto del testo principale e del formato hanno superato la convalida.

## Convalida in questo round

Vengono conteggiati solo i controlli elencati di seguito con riepiloghi completi di successo nei registri di questo round; sono esclusi i moduli storici che non sono stati rieseguiti.

| Verifica | Superato |
| --- | --- |
| Conversione vettoriale PostScript, annullamento, isolamento ed EPS effettivo | 24 / 24 |
| SVG / Compatibilità EPS e verifica dell'allegato originale | 64 / 64 |
| PSD / PSB composito, canali trasparenti, immagini di grandi dimensioni e dati danneggiati | 712 / 712 |
| Rilettura del sistema reale e impostazioni predefinite batch (fittizia) | 101 / 101 |
| Finestra di dialogo del formato predefinito, stato di riapertura e selezione di tutti i formati (fittizia) | 34 / 34 |
| 16 lingue e segnaposto | 174 / 174 |
| Dichiarazioni dei formati dell’app distribuita | 15 / 15 |
| Libreria di immagini e decodifica del sistema | 78 / 78 |
| Geometria della tela, animazioni e mouse | 66 / 66 |
| Analisi del documento e disegno della pagina completa | 56 / 56 |
| Messa a fuoco del documento, zoom e impaginazione EPS/PS, annullamento al cambio file | 75 / 75 |
| Clic e ciclo di vita reali delle finestre | 65 / 65 |
| 443-miniature dei file, cache e callback obsoleti | 37 / 37 |
| Annullamento della richiesta di miniatura e isolamento del consumatore | 13 / 13 |
| Menu contestuale dell'app di rilascio installato e appunti privati | 28 / 28 |
| **Totale** | **1542 / 1542** |

La versione ottimizzata dell'app installata è stata sottoposta a 28 controlli aggiuntivi del menu contestuale tramite menu reali e invio target/action, utilizzando appunti denominati separatamente. Hanno verificato la copia di immagini, fotogrammi video correnti, immagini PDF e pagine intere, rotazione e risultati obsoleti al passaggio/chiusura, senza toccare gli appunti di sistema dell'utente. I controlli di regressione esistenti relativi a clic del mouse, ciclo di vita delle finestre, messa a fuoco della pagina, presentazione della pagina completa, cache delle miniature e annullamento sono stati tutti superati.

## Directory di rilascio e verifica dell'app installata

Versione **1.7.0, build 12**. Prima di scrivere questo rapporto, gli ID bundle, le versioni, le build, gli elenchi completi di file e gli hash SHA-256 di `outputs/LumaView.app` e `/Applications/LumaView.app` sono stati confrontati e sono risultati identici. Tutti e quattro gli eseguibili hanno superato l'ispezione della doppia architettura, entrambe le app hanno superato `codesign --verify --deep --strict`, la versione segnalata da Ghostscript in bundle 10.08.0, le risorse di localizzazione/versione corrispondevano all'albero di origine e lo SHA-256 dell'archivio di origine di Ghostscript corrispondeva all'elenco di checksum incluso. L'interprete viene firmato nuovamente durante una compilazione; non è necessario che il suo binario firmato corrisponda alla copia nella directory sorgente non ancora rifirmata, byte per byte.

| Eseguibile | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

Questo rapporto non sostituisce i successivi controlli di integrità ZIP né dichiara una notarizzazione Apple. La firma è locale e ad hoc. La compilazione incrociata e i controlli dell’architettura Apple Silicon sono stati completati, ma questo round non è stato eseguito sull'hardware Apple Silicon. L'archivio dei sorgenti Ghostscript, la licenza e le istruzioni per la ricostruzione accompagnano la distribuzione dei sorgenti.

## Ambito e limiti

Le bitmap già incorporate in EPS/PS mantengono i limiti di risoluzione sorgente; i caratteri esterni o le risorse file e PostScript insoliti o danneggiati potrebbero non essere convertiti completamente. Le anteprime PSD / PSB dipendono dai compositi di compatibilità salvati e non modificano i livelli di Photoshop né ricostruiscono i compositi mancanti; quando assente, l'app consiglia di abilitare Massimizza compatibilità e di salvare nuovamente. Le dimensioni della tela originale potrebbero superare la dimensione dell'anteprima visualizzata; un'anteprima limitata non viene presentata come se ogni pixel sorgente fosse decodificato. Vedi [FORMATS.md](../FORMATS.md) per altri limiti di formato.

## Origini del registro per questo round

I seguenti file sono stati copiati in `Tests/`. I report storici non riprodotti rimangono ma sono esclusi dal totale di questo round:

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
