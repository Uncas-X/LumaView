# Strumenti multimediali in bundle

<!-- doc-navigation:start -->
[Documentazione](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · **Italiano** · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView richiama FFmpeg 9.0.2 e ffprobe non modificati come processi locali separati. Questi sono creati dal codice sorgente per Intel e Apple Silicon, destinati a macOS 13. Usano dav1d 1.5.3 collegato staticamente per la decodifica AV1 e solo librerie dinamiche di sistema. Homebrew e VLC non sono richiesti in fase di runtime.

FFmpeg è configurato sotto LGPL 2.1 o successivo, senza `--enable-gpl` o `--enable-nonfree`. dav1d utilizza la licenza BSD 2-Clause. Gli avvisi completi sulla licenza si trovano in `Resources/ThirdPartyNotices` e vengono copiati nel bundle dell'applicazione. Gli archivi sorgente corrispondenti esatti e non modificati sono inclusi in `sources/`, con checksum SHA-256. Tutti i flag di configurazione e i passaggi di creazione si trovano in `tools/build-media-tools.sh`. LumaView non pone alcuna restrizione aggiuntiva sulla modifica o sostituzione di questi strumenti separati o sul reverse engineering necessario per eseguire il debug di tali modifiche.

Fonti ufficiali:

- [Rilascio e firma di FFmpeg](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. La sua firma separata è stata verificata rispetto alla chiave di rilascio di FFmpeg `FCF986EA15E6E293A5644F10B4322F04D67658D8`.
- [Versione di dav1d](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [Informazioni sulla licenza FFmpeg](https://ffmpeg.org/legal.html).

## Ricompilare

La normale build dell'applicazione utilizza i binari universali inclusi. Per ricostruire questi strumenti, installa Xcode Command Line Tools, Python 3, Meson 1.12.1 e Ninja 1.13.2. Ad esempio, utilizza un ambiente virtuale Python locale e installa lì `meson==1.12.1 ninja==1.13.2`. Attivalo, quindi esegui:

```sh
./tools/build-media-tools.sh
./build.sh
```

Il primo comando verifica i checksum dei sorgenti, compila entrambe le architetture e sostituisce `Resources/MediaTools/{ffmpeg,ffprobe}`. Utilizzare `LUMAVIEW_PYTHON` per selezionare Python e `LUMAVIEW_MEDIA_BUILD` per selezionare la directory di build intermedia. Gli argomenti `x86_64` o `arm64` compilano un'unica architettura; il valore predefinito `universal` li combina. La build dell'app firma gli strumenti annidati e l'app con una firma locale ad hoc.

Rete, dispositivi di acquisizione, ffplay, codec esterni diversi da dav1d e codificatori GPL sono disabilitati. Sono inclusi tutti i decoder/demuxer interni disponibili per questa configurazione. L'uscita audio è preparata come AAC; il video utilizza remux ove possibile, quindi VideoToolbox H.264, MPEG-4 o output di compatibilità ProRes. Questo è un percorso di visualizzazione, non un'interfaccia utente di esportazione o transcodifica.

## Interprete vettoriale PostScript

L'anteprima EPS, PostScript e Illustrator legacy utilizza inoltre Ghostscript 10.08.0 in bundle come sottoprocesso locale separato e limitato. Vedere [README-Ghostscript.md](README-Ghostscript.md) per la sua licenza AGPL-3.0-or-later, l'archivio sorgente completo corrispondente, i checksum e la build universale riproducibile. La build ordinaria dell'app non richiede l'installazione di Ghostscript nel sistema.
