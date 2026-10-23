> Nomes de arquivos de amostras pessoais em registros históricos de validação foram tornados anônimos. Os dados e resultados do teste permanecem inalterados.

<!-- doc-navigation:start -->
[Documentação](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · **Português (Brasil)** · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# Registro de validação LumaView 1.7.0

Data: 2026-10-22 (Asia/Shanghai). Ambiente de teste: macOS 15.7.9, x86_64. O aplicativo é direcionado ao macOS 13+ e todos os quatro executáveis ​​são binários universais Intel/Apple Silicon.

## Mudanças e resultados testados nesta rodada

- O Ghostscript 10.08.0 incluído converte em segundo plano todo o conteúdo dos arquivos EPS, PostScript e AI baseados em PostScript antigo abertos diretamente. O PDF mantém traçados vetoriais, texto e imagens incorporadas e é enviado à área de desenho existente. Os usuários não precisam de um intérprete separado nem de conversão manual; zoom, panorâmica, rotação e navegação em várias páginas seguem as interações atuais. O substituto TIFF incorporado ainda será usado se a conversão do vetor falhar e o arquivo fornecer uma visualização; o substituto raster não é rotulado como vetor.
- O anexo de amostra `sample-vector.eps` foi testado usando seu conteúdo PostScript completo. A verificação do PDF gerado encontrou operações relacionadas a **147,521 caminho/gradiente, operações de texto 59 e chamadas de XObject 160**. Os XObjects aqui são contados como operações PDF `Do` e podem incluir imagens ou XObjects Form; o número não é uma contagem de imagens distintas. Os testes confirmaram que o conteúdo real do vetor foi preservado. As comparações SHA-256 do EPS e `sample-vector.svg` antes e depois do teste mostraram originais inalterados.
- PostScript usa um processo cancelável separado, Ghostscript SAFER, e uma sandbox de processo do sistema. A entrada é copiada para um diretório temporário privado; o intérprete não pode ler outros arquivos do usuário, gravar em arquivos externos arbitrários ou usar pipes externos. Tempo limite, cancelamento, reutilização por vários consumidores, entrada corrompida e verificações de invalidação de cache aprovadas. Os resultados concluídos são publicados atomicamente, portanto, os PDFs parciais não preenchem as miniaturas. Os testes de visualizador real cobriram EPS com zoom vetorial de 3200%, foco para cima/para baixo e navegação de página esquerda/direita em PS de várias páginas e mudança para PNG durante a conversão sem um resultado tardio substituindo a visualização atual.
- `.psb` foi adicionado ao grupo Photoshop junto com `.psd` para descoberta, visualização principal, miniaturas e configurações padrão do aplicativo. Um composto de compatibilidade salvo é lido e as dimensões originais da tela são retidas; arquivos grandes obtêm visualizações limitadas de acordo com a necessidade de exibição. A validação cobriu **112 combinações de codificação, 128 arquivos estruturais com camadas e marcadores de transparência, 1 PSB grande e 13 arquivos de teste corrompidos**. A detecção de transparência composta usa contagem de camadas e marcadores Lr16/Lr32, Mtrn/Mt16/Mt32; canais Alpha extras comuns não são confundidos com transparência composta. Os testes cobriram valores de pixels transparentes, remoção de fundo branco, consistência de codificação, cancelamento em linhas longas e regressões de integração principal/miniatura.
- A caixa de diálogo de abertura padrão lê as associações reais do sistema quando é aberta, quando o aplicativo é reativado e após a conclusão das configurações em lote. As próprias associações persistem durante as reinicializações; rascunhos não aplicados não são exibidos como bem-sucedidos. Um formato verificado possui todos os tipos atribuídos a este aplicativo; um traço indica correspondências parciais ou outra cópia com o mesmo ID do pacote, explicado na dica de ferramenta. Limpar apenas altera o rascunho; ele não revoga os padrões do sistema.
- Selecionar todos os formatos na parte superior seleciona imagens, vetores/documentos, vídeo e áudio de uma só vez, incluindo formatos fora dos resultados da pesquisa. O botão Definir ainda deve ser clicado para escrever associações. Detecção, sucesso parcial, leitura de erros, reconstrução do controlador, diferenças entre o rascunho e o estado real e seleção total foram testados com um back-end simulado na memória. Os testes não alteraram os aplicativos padrão do sistema do usuário.
- Novas configurações, PostScript e strings do Photoshop desta rodada cobrem os 16 idiomas. Os espaços reservados de texto e formato principais foram aprovados na validação.

## Validação nesta rodada

Somente as verificações listadas abaixo com resumos completos de sucesso nos registros desta rodada são contadas; módulos históricos que não foram executados novamente são excluídos.

| Verificação | Aprovado |
| --- | --- |
| Conversão vetorial PostScript, cancelamento, isolamento e EPS real | 24 / 24 |
| SVG / Compatibilidade com EPS e verificação do anexo original | 64 / 64 |
| PSD / PSB compostos, canais transparentes, imagens grandes e dados danificados | 712 / 712 |
| Leitura do sistema real e configurações padrão de lote (simulado) | 101 / 101 |
| Caixa de diálogo de formato padrão, estado de reabertura e seleção de todos os formatos (simulação) | 34 / 34 |
| 16 idiomas e espaços reservados | 174 / 174 |
| Declarações de formatos do aplicativo publicado | 15 / 15 |
| Biblioteca de imagens e decodificação do sistema | 78 / 78 |
| Geometria da tela, animações e mouse | 66 / 66 |
| Análise de documentos e desenho de página completa | 56 / 56 |
| Foco do documento, zoom e paginação EPS/PS, cancelamento na alteração do arquivo | 75 / 75 |
| Clique em janela real e ciclo de vida | 65 / 65 |
| 443 miniaturas de arquivos, cache e retornos de chamada obsoletos | 37 / 37 |
| Cancelamento de solicitação de miniatura e isolamento do consumidor | 13 / 13 |
| Menu de contexto do aplicativo de lançamento instalado e área de transferência privada | 28 / 28 |
| **Total** | **1542 / 1542** |

O aplicativo de versão otimizada instalado passou por 28 verificações adicionais de menu de contexto por meio de menus reais e envio target/action, usando uma área de transferência nomeada separadamente. Eles verificaram a cópia de imagens, quadros de vídeo atuais, imagens PDF e páginas inteiras, rotação e resultados obsoletos ao alternar/fechar, sem tocar na área de transferência do sistema do usuário. Verificações de regressão existentes para cliques do mouse, ciclo de vida da janela, foco da página, apresentação de página completa, cache de miniaturas e cancelamento, todas aprovadas.

## Verificação do diretório de distribuição e do aplicativo instalado

Versão **1.7.0, compilação 12**. Antes de escrever este relatório, os IDs de pacote, versões, compilações, listas completas de arquivos e hashes SHA-256 de `outputs/LumaView.app` e `/Applications/LumaView.app` foram comparados e considerados idênticos. Todos os quatro executáveis ​​passaram na inspeção de arquitetura dupla, ambos os aplicativos passaram em `codesign --verify --deep --strict`, a versão relatada do Ghostscript agrupada 10.08.0, os recursos de localização/versão corresponderam à árvore de origem e o SHA-256 do arquivo de origem do Ghostscript correspondeu à lista de soma de verificação incluída. O intérprete é assinado novamente durante uma construção; o binário reassinado não precisa corresponder, byte por byte, à cópia do diretório-fonte que ainda não foi reassinada.

| Executável | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

Este relatório não substitui verificações subsequentes de integridade do ZIP nem afirma que houve notarização pela Apple. A assinatura é local e ad hoc. A compilação cruzada e as verificações de arquitetura para Apple Silicon foram concluídas, mas esta rodada não foi executada no hardware Apple Silicon. O arquivo fonte, a licença e as instruções de reconstrução do Ghostscript acompanham a distribuição fonte.

## Escopo e limites

Bitmaps já incorporados em EPS/PS mantêm seus limites de resolução de origem; fontes externas ou recursos de arquivo e PostScript incomum ou danificado podem não ser totalmente convertidos. As visualizações PSD / PSB dependem de composições de compatibilidade salvas e não editam camadas do Photoshop nem reconstroem composições ausentes; quando ausente, o aplicativo recomenda ativar Maximizar compatibilidade e salvar novamente. As dimensões originais da tela podem exceder o tamanho de visualização exibido; uma visualização limitada não é apresentada como se cada pixel de origem tivesse sido decodificado. Consulte [FORMATS.md](../FORMATS.md) para outros limites de formato.

## Fontes de log para esta rodada

Os arquivos a seguir foram copiados para `Tests/`. Os relatórios históricos não repetidos permanecem, mas são excluídos do total desta rodada:

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
