# Lingue dell'interfaccia LumaView

<!-- doc-navigation:start -->
[Documentazione](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · **Italiano** · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


L'app inizia con **Segui il sistema**. Sceglie la prima lingua supportata nell'elenco delle lingue preferite di macOS, quindi l'inglese se nessuna è supportata. Una lingua selezionata in **LumaView → Lingua…** ha effetto immediato e viene ricordata solo per questa app.

Scelte supportate: cinese semplificato, cinese tradizionale, inglese, giapponese, coreano, francese, tedesco, spagnolo, italiano, portoghese, russo, arabo, hindi, turco, olandese e polacco. Le varianti portoghesi attualmente utilizzano il catalogo portoghese brasiliano. I nomi nativi nel selettore sono intenzionali, quindi un utente può ritrovare la propria lingua anche da un’interfaccia non familiare.

`catalog.json` associa le chiavi di origine leggibili del cinese semplificato a stringhe localizzate. `core-keys.json` definisce i controlli comuni, i menu, le impostazioni, la navigazione nei documenti, le etichette dei metadati e le stringhe di aiuto della tastiera richieste in ogni catalogo. I messaggi diagnostici a bassa frequenza utilizzano il fallback inglese quando una lingua non dispone di una propria voce. I nomi di file, directory, codec, formati e metadati della fotocamera incorporata rimangono invariati. Il sistema operativo fornisce il testo della finestra di dialogo del sistema nativo nella propria lingua.

Utilizzare `L10n.tr("source key")` per il testo statico. Per il testo dinamico, utilizzare `L10n.format("第 %d / %d 页", current, total)`, anziché interpolare una stringa cinese prima della traduzione. Mantieni i tipi e i conteggi dei segnaposto coerenti tra le traduzioni. Osserva `L10n.languageDidChange` per aggiornare le interfacce esistenti e ridisegnare il testo renderizzato. I test utilizzano `useLanguageForTesting` per evitare di modificare la lingua persistente dell'utente.

Esegui `Tests/run-localization-tests.sh` per la risoluzione della lingua, la copertura principale completa, la coerenza del formato-segnaposto, il comportamento di fallback e la direzione del testo in arabo. Il testo tradotto non è stato sottoposto a revisione linguistica professionale.
