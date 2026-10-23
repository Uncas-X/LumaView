# Record di convalida LumaView 1.7.2

<!-- doc-navigation:start -->
[Documentazione](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · [繁體中文](../zh-Hant/TEST-RESULTS.md) · [English](../en/TEST-RESULTS.md) · [日本語](../ja/TEST-RESULTS.md) · [한국어](../ko/TEST-RESULTS.md) · [Français](../fr/TEST-RESULTS.md) · [Deutsch](../de/TEST-RESULTS.md) · [Español](../es/TEST-RESULTS.md) · **Italiano** · [Português (Brasil)](../pt-BR/TEST-RESULTS.md) · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · [Türkçe](../tr/TEST-RESULTS.md) · [Nederlands](../nl/TEST-RESULTS.md) · [Polski](../pl/TEST-RESULTS.md)
<!-- doc-navigation:end -->


Versione 1.7.2, build 14. Testato su 2026-10-22 con macOS 15.7.9 / Intel. L'app e gli strumenti in bundle sono stati controllati come binari universali arm64 + x86_64 con firme locali. Questo round non è stato eseguito sull'hardware Apple Silicon.

## Correzione in questa versione

Le immagini raster ora mostrano le regioni trasparenti in modo coerente: PNG / GIF / PSD / PSB e altre non disegnano più una scacchiera grigio-bianca o un bordo di tela rettangolare. Le ombre di visualizzazione derivano dall'effettivo alfa composito dell'immagine corrente anziché dall'intera tela dell'immagine. I margini trasparenti quindi non hanno ombre rettangolari aggiuntive; fori, maschere morbide separate e regioni traslucide contribuiscono al contorno effettivo.

La vecchia implementazione considerava solo CGImage.alphaInfo quando si aggiungeva la scacchiera, mancando i file PSB con una maschera Quartz separata. Inoltre forzava un shadowPath rettangolare su ogni zoom e il bordo stesso produceva un'ombra rettangolare. Quelle sorgenti rettangolari sono state rimosse per le immagini raster; le ombre dei livelli ora seguono automaticamente l'alfa composito. Allo stesso modo, il disegno esportato proietta un'ombra dall'immagine stessa senza prima riempire un rettangolo. Le modifiche al fotogramma GIF / APNG sostituiscono la texture corrente e aggiornano l'ombra senza scansionare i pixel trasparenti di ogni fotogramma o creare un'immagine RGBA completamente extra.

Le pagine dei documenti mantengono il loro foglio bianco e le superfici video mantengono il rettangolo esistente. La copia delle immagini utilizza comunque i pixel dell'immagine originale senza lo sfondo del visualizzatore, la scacchiera o l'ombra del display. Il decoder PSB, lo scheduler delle miniature e il percorso di anteprima rapida della versione precedente non sono stati modificati.

## Convalida in questo round

| Verifica | Superato |
| --- | --- |
| Trasparenza, ombre di contorno e cambi di fotogramma | 133 / 133 |
| Geometria della tela, animazione e mouse | 66 / 66 |
| Analisi del documento e rendering della pagina completa | 56 / 56 |
| App di rilascio installata: documenti, zoom EPS/PS, navigazione pagina e messa a fuoco | 75 / 75 |
| App di rilascio installata: menu contestuali e copia | 28 / 28 |
| Totale | 358 / 358 |

I test di trasparenza hanno utilizzato un elemento grafico con un foro, sporgenze irregolari e ampi margini trasparenti, codificato separatamente come RGBA, una maschera Quartz separata e file PNG, GIF, PSD e PSB effettivi che sono stati codificati e decodificati. La composizione di CALayer e i pixel esportati da `draw` sono stati controllati per confermare l’assenza di uno sfondo o un’ombra rettangolare sui margini trasparenti e la presenza di ombre sui contorni interni ed esterni. Sono stati trattati anche immagini completamente trasparenti, cambi di fotogramma, rotazione e zoom, cambio rapido e uno sfondo del visualizzatore traslucido. I PNG esportati sono stati controllati visivamente.

Per questi sei input, il PNG SHA-256 dell'esportazione CALayer e l'esportazione PNG `draw` erano identici: `578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`. Il supporto di prova è stato generato dal codice; nessuna foto personale è stata aggiunta alla fonte.

Una sonda di rendering software delimitata ha inoltre confrontato le nuove e le vecchie ombre con adattamento alla finestra, 100% e 3200% su una bitmap da 32 MP con tele logiche di 16,384 × 7,812 e 300,000 × 128. Il picco RSS del processo di test era di circa 428 MiB; i tempi di rendering vecchi e nuovi erano simili. Ciò misura le istantanee del software tramite `CALayer.render(in:)`, non i frame rate della GPU. Di conseguenza, non è stata aggiunta alcuna cache raster di livello.

Gli elenchi completi dei file e gli hash della versione installata e di `outputs/LumaView.app` coincidono; entrambi hanno superato `codesign --verify --deep --strict`. È stato eseguito il backup dello ZIP precedente prima dell'installazione. Le associazioni di apertura predefinite sono state lette prima e dopo. Sono seguiti i controlli CRC e versione dello ZIP consegnato. I report storici rimangono in `Tests/Release-1.7.0.md` e `Tests/Release-1.7.1.md`; i controlli non rieseguiti da quelle versioni non entrano nel conteggio di questo round.

Eseguibile principale SHA-256: `b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`.

## Origini del registro

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
