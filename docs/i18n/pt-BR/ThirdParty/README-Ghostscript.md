# Ferramenta de conversão de documentos Ghostscript

<!-- doc-navigation:start -->
[Documentação](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · **Português (Brasil)** · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView invoca Ghostscript **10.08.0**, lançado pela Artifex em 2026-09-08, como um executável local separado para converter EPS e PostScript em um PDF temporário. A saída PDF retém traçados vetoriais, texto e gradientes suportados. As imagens já incorporadas como pixels raster permanecem imagens raster. O Ghostscript não está vinculado ao aplicativo Swift e nenhuma instalação do Homebrew é necessária para executar este executável incluído.

## Licença e fonte correspondente

Ghostscript é distribuído sob a **Licença Pública Geral GNU Affero versão 3 ou posterior**, conforme especificado pelo arquivo `LICENSE` original nesta versão. A licença completa, o aviso de direitos autorais do Ghostscript, a exceção de incorporação de fontes, os avisos do Adobe CMap e os avisos de dependência incluídos são copiados sem alterações para `Resources/ThirdPartyNotices/Ghostscript/`. Uma licença comercial separada também está disponível na Artifex; este pacote não inclui uma licença comercial. Consulte a [página oficial de licenciamento](https://www.ghostscript.com/licensing/index.html).

A versão exata e não modificada da fonte correspondente, incluindo os códigos-fonte das dependências e das fontes tipográficas incorporadas, está incluída em `ThirdParty/sources/ghostscript-10.08.0.tar.xz`. Seu SHA-256 está registrado em `ThirdParty/sources/SHA256SUMS-Ghostscript`:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

Proveniência da fonte: [página de lançamento oficial](https://www.ghostscript.com/releases/index.html) e [ativos de lançamento 10.08.0 da Artifex](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). A soma de verificação corresponde à soma de verificação publicada para o ativo `.tar.xz`. O pacote fonte e este script de construção acompanham a distribuição fonte do LumaView. O LumaView não impõe nenhuma restrição adicional à modificação ou substituição desta ferramenta separada, ou à engenharia reversa necessária para depurar tais modificações. Esses avisos descrevem o componente de terceiros incluído; eles não pretendem licenciar novamente a fonte do aplicativo.

## Recompilar

Requisitos: macOS, ferramentas de linha de comando Xcode, arquivo de origem incluído e ferramentas de compilação padrão do macOS. Nenhuma biblioteca Homebrew é usada. No diretório de origem do LumaView:

```sh
./tools/build-document-tools.sh
./build.sh
```

O script verifica o arquivo de origem, cria fatias Intel e Apple Silicon a partir de diretórios de origem separados, remove símbolos locais e combina as fatias em `Resources/DocumentTools/gs`. Ambas as fatias são direcionadas ao macOS 13.0 ou posterior. Ele não executa `make install` nem grava em um gerenciador de pacotes do sistema. `LUMAVIEW_DOCUMENT_BUILD` seleciona o diretório de compilação intermediário; `LUMAVIEW_DOCUMENT_JOBS` controla o paralelismo de make (padrão: 4). O argumento opcional `x86_64` ou `arm64` constrói apenas uma arquitetura. A construção do aplicativo assina o executável copiado junto com o aplicativo.

O executável inclui código de inicialização, fontes agrupadas, Adobe CMaps e perfis ICC em seu sistema de arquivos interno `%rom%`. Os caminhos de pesquisa padrão externos estão vazios. Somente o dispositivo de saída `pdfwrite` está habilitado. Impressão/CUPS, X11, GTK, fontconfig, D-Bus, Tesseract/OCR, drivers dinâmicos, IJS externo e ferramentas de extração de documentos estão desabilitados. Todas as bibliotecas de decodificadores/cores/fontes incluídas são compiladas a partir do arquivo fonte correspondente; a ligação dinâmica é limitada às bibliotecas do sistema Apple. Consulte a [documentação oficial de compilação](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html) para o sistema de arquivos ROM e mecanismos de compilação cruzada.

LumaView executa o interpretador com `-dSAFER`, um arquivo específico de entrada e saída, um diretório de trabalho temporário privado, cancelamento e tempo limite. O ambiente do processo não deve herdar opções do Ghostscript ou caminhos de biblioteca especificados pelo usuário. Exemplo de arquivos de teste confiáveis gerados:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

As opções completas de construção estão em `tools/build-document-tools.sh`; nenhum patch foi aplicado ao arquivo de código-fonte. A execução nativa pode ser testada apenas para arquiteturas suportadas pelo host de construção. As verificações de liberação inspecionam ambas as fatias Mach-O e executam um EPS gerado contendo caminhos e texto através da fatia compatível com host, confirmando que a saída PDF ainda contém desenho vetorial e operadores de texto.
