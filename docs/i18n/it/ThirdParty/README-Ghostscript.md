# Strumento di conversione dei documenti Ghostscript

<!-- doc-navigation:start -->
[Documentazione](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · **Italiano** · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView richiama Ghostscript **10.08.0**, rilasciato da Artifex il 2026-09-08, come eseguibile locale separato per convertire EPS e PostScript in un PDF temporaneo. L'output PDF mantiene i tracciati vettoriali, il testo e le sfumature supportati. Le immagini già incorporate come pixel raster rimangono immagini raster. Ghostscript non è collegato all'applicazione Swift e non è richiesta l'installazione di Homebrew per eseguire questo eseguibile in bundle.

## Licenza e fonte corrispondente

Ghostscript è distribuito sotto la **GNU Affero General Public License versione 3 o successiva**, come specificato dal file originale `LICENSE` in questa versione. La licenza completa, l'avviso sul copyright di Ghostscript, l'eccezione di incorporamento dei caratteri, gli avvisi di Adobe CMap e gli avvisi sulle dipendenze inclusi vengono copiati senza modifiche in `Resources/ThirdPartyNotices/Ghostscript/`. Una licenza commerciale separata è disponibile anche da Artifex; questo pacchetto non include una licenza commerciale. Consulta la [pagina delle licenze ufficiali](https://www.ghostscript.com/licensing/index.html).

La versione sorgente corrispondente esatta e non modificata, inclusi i sorgenti delle dipendenze e dei caratteri tipografici incorporati, è inclusa in `ThirdParty/sources/ghostscript-10.08.0.tar.xz`. Il suo SHA-256 è registrato in `ThirdParty/sources/SHA256SUMS-Ghostscript`:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

Provenienza della fonte: [pagina della versione ufficiale](https://www.ghostscript.com/releases/index.html) e [risorse della versione 10.08.0 di Artifex](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). Il checksum corrisponde al checksum pubblicato per la risorsa `.tar.xz`. Il pacchetto sorgente e questo script di build accompagnano la distribuzione sorgente LumaView. LumaView non impone alcuna restrizione aggiuntiva alla modifica o alla sostituzione di questo strumento separato o al reverse engineering necessario per eseguire il debug di tali modifiche. Questi avvisi descrivono il componente di terze parti in bundle; non intendono concedere una nuova licenza alla fonte dell'applicazione.

## Ricompilare

Requisiti: macOS, strumenti da riga di comando Xcode, archivio sorgente incluso e strumenti di creazione macOS standard. Non vengono utilizzate librerie Homebrew. Dalla directory di origine di LumaView:

```sh
./tools/build-document-tools.sh
./build.sh
```

Lo script verifica l'archivio di origine, crea sezioni Intel e Apple Silicon da directory di origine separate, rimuove i simboli locali e combina le sezioni in `Resources/DocumentTools/gs`. Entrambe le sezioni sono destinate a macOS 13.0 o versione successiva. Non esegue `make install` né scrive su un gestore di pacchetti di sistema. `LUMAVIEW_DOCUMENT_BUILD` seleziona la directory di build intermedia; `LUMAVIEW_DOCUMENT_JOBS` controlla il parallelismo di make (valore predefinito: 4). L'argomento facoltativo `x86_64` o `arm64` crea solo un'architettura. La build dell'applicazione firma l'eseguibile copiato insieme all'app.

L'eseguibile include codice di inizializzazione, caratteri in bundle, Adobe CMaps e profili ICC nel file system interno `%rom%`. I percorsi di ricerca predefiniti esterni sono vuoti. È abilitato solo il dispositivo di output `pdfwrite`. Stampa/CUPS, X11, GTK, fontconfig, D-Bus, Tesseract/OCR, driver dinamici, IJS esterno e strumenti di estrazione documenti sono disabilitati. Tutte le librerie di decodificatori/colori/caratteri incluse sono compilate dal corrispondente archivio sorgente; il collegamento dinamico è limitato alle librerie di sistema Apple. Consulta la [documentazione ufficiale della build](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html) per il filesystem ROM e i meccanismi di compilazione incrociata.

LumaView esegue l'interprete con `-dSAFER`, un file di input e output specifico, una directory di lavoro temporanea privata, annullamento e timeout. L'ambiente del processo non deve ereditare le opzioni Ghostscript specificate dall'utente o i percorsi delle librerie. Esempio di file di test affidabili generati:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

Le opzioni di compilazione complete sono in `tools/build-document-tools.sh`; l'archivio di origine non è patchato. L'esecuzione nativa può essere testata solo per le architetture supportate dall'host di compilazione. I controlli di rilascio ispezionano entrambe le sezioni Mach-O ed eseguono un EPS generato contenente percorsi e testo attraverso la sezione compatibile con l'host, confermando che l'output PDF contiene ancora operatori di disegno vettoriale e testo.
