# Idiomas da interface LumaView

<!-- doc-navigation:start -->
[Documentação](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · **Português (Brasil)** · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


O aplicativo começa com **Seguir o sistema**. Ele escolhe o primeiro idioma compatível na lista de idiomas preferidos do macOS e, em seguida, o inglês, se nenhum for compatível. Um idioma selecionado em **LumaView → Idioma…** entra em vigor imediatamente e é lembrado apenas para este aplicativo.

Opções suportadas: Chinês Simplificado, Chinês Tradicional, Inglês, Japonês, Coreano, Francês, Alemão, Espanhol, Italiano, Português, Russo, Árabe, Hindi, Turco, Holandês e Polonês. As variantes portuguesas utilizam atualmente o catálogo do português brasileiro. Os nomes nativos no seletor são intencionais, para que um usuário possa voltar ao seu idioma mesmo a partir de uma interface desconhecida.

`catalog.json` mapeia chaves de origem em chinês simplificado legíveis para strings localizadas. `core-keys.json` define os controles comuns, menus, configurações, navegação de documentos, rótulos de metadados e strings de ajuda do teclado necessários em cada catálogo. As mensagens de diagnóstico de baixa frequência usam o substituto em inglês quando um idioma não possui sua própria entrada. Nomes de arquivos, diretórios, codecs, formatos e metadados de câmeras incorporados permanecem inalterados. O sistema operacional fornece texto de diálogo nativo do sistema em seu próprio idioma.

Use `L10n.tr("source key")` para texto estático. Para texto dinâmico, use `L10n.format("第 %d / %d 页", current, total)`, em vez de interpolar uma string chinesa antes da tradução. Mantenha os tipos e contagens de espaços reservados consistentes nas traduções. Observe `L10n.languageDidChange` para atualizar as interfaces existentes e redesenhar o texto renderizado. Os testes usam `useLanguageForTesting` para evitar a modificação do idioma persistente do usuário.

Execute `Tests/run-localization-tests.sh` para resolução de localidade, cobertura completa do núcleo, consistência de espaço reservado de formato, comportamento de fallback e direção de texto em árabe. O texto traduzido não foi submetido a revisão linguística profissional.
