> Nomes de arquivos de amostras pessoais em registros históricos de validação foram tornados anônimos. Os dados e resultados do teste permanecem inalterados.

<!-- doc-navigation:start -->
[Documentação](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · **Português (Brasil)** · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# Registro de validação LumaView 1.7.1

Versão 1.7.1, compilação 13. 2026-10-22, macOS 15.7.9 /Intel. O aplicativo e as três ferramentas incluídas passaram nas verificações de arquitetura arm64 + x86_64 e assinatura local; esta rodada não foi executada em hardware Apple Silicon.

## Problemas localizados e corrigidos

Os três arquivos PSB do usuário eram arquivos RGB de 8 bits, RLE de quatro canais com transparência composta, cerca de 108–123 MiB cada. A maior parte de cada arquivo consiste em dados de camada que podem ser ignorados diretamente; as telas principais contêm cerca de 8.5–9.6 megapixels.

1. O antigo decodificador linha por linha chamava FileHandle para cada marcador e valor PackBits, produzindo muitas leituras minúsculas e deixando as filas de imagens principais e miniaturas ocupadas por muito tempo. Ele agora lê pedaços de até 64 KiB, preservando literal/run verificações de estado e limites entre pedaços. Os dados longos no-op permanecem canceláveis. ZIP reverte a previsão apenas para linhas de amostra enquanto ainda valida todo o fluxo compactado.
2. Todos os três arquivos possuem uma miniatura RGB JPEG válida no recurso 1036. A faixa de miniaturas agora prefere, verificando formato, dimensões, proporção e comprimento compactado; a imagem principal sempre decodifica a composição real. Visualizações inválidas, recursos BGR mais antigos ou visualizações ausentes retornam ao composto.
3. O sistema ImageIO rejeita alguns pequenos compostos PSD que carregam um RGB genérico ICC válido. O substituto anterior, portanto, retornou miniaturas vazias. Ele agora decodifica pixels separadamente e, em seguida, anexa o ICC original verificado se seu modelo de cores e contagem de componentes corresponderem, em vez de descartar o perfil. Os arquivos originais ICC correspondem ao padrão do sistema Generic RGB Profile. Arquivos de teste de regressão foram geradas a partir do perfil do sistema; as fotos do usuário não foram adicionadas à fonte.
4. A visualização principal PSB reutiliza informações de cabeçalho analisadas e evita uma verificação adicional da camada ImageIO para metadados. As dimensões originais, a transparência e a qualidade da imagem principal são mantidas.

## Testes nos três arquivos originais

Estas são medidas locais neste Mac, afetadas pela carga e pelo cache de arquivos, e não garantias de desempenho para todos os dispositivos. Tanto os decodificadores antigos quanto os novos usavam compilação otimizada.

| Arquivo | Dimensões originais | Decodificação da imagem principal antiga | Nova decodificação da imagem principal | Nova decodificação de miniaturas compostas (sem visualização incorporada) |
| --- | --- | --- | --- | --- |
| Amostra A | 2582 × 3318 | Teste cancelado após mais de 15 segundos | 0.68 segundos | 0.039 segundos |
| Amostra B | 2610 × 3307 | 14.35 segundos | 0.65 segundos | 0.028 segundos |
| Amostra C | 2843 × 3361 | Teste cancelado após mais de 15 segundos | 0.70 segundos | 0.028 segundos |

A solicitação de três miniaturas simultaneamente por meio do ImageLoader real foi concluída em cerca de 0.06 segundos. As imagens principais completas demoraram aproximadamente 0.90 / 0.65 / 0.74 segundos no carregador. A versão antiga relatava todas as três miniaturas compostas como unsupported; a nova versão teve sucesso em todos os três. Os valores SHA-256 dos originais correspondiam byte por byte antes e depois do teste; o aplicativo não modificou os arquivos originais.

## Verificações aprovadas nesta rodada

| Verificação | Resultado |
| --- | --- |
| Codificação PSD / PSB e composição transparente | 712 / 712 |
| Desempenho RLE, visualizações incorporadas, ICC, limites de blocos, cancelamento | 54 / 54 |
| Integração real ImageLoader para três PSBs originais | 21 / 21 |
| Faixa de miniaturas de 443 arquivos, cache, retornos de chamada invalidados | 37 / 37 |
| Solicitações e cancelamento independentes de miniaturas | 13 / 13 |
| Biblioteca de imagens e decodificação do sistema | 78 / 78 |
| Menu de contexto e cópia do aplicativo de versão otimizada instalado | 28 / 28 |
| Total | 943 / 943 |

Novos testes cobrem literais densos de um byte, limites de 64 KiB, cancelamento durante longas sequências no-op, dados truncados e fora dos limites, conteúdos corretos distintos para miniaturas incorporadas e imagens principais, ICC, transparência e pequenos fatores de zoom não inteiros. As combinações de codificação 112 existentes e 128 arquivos estruturais com marcadores de transparência de camadas continuam a passar. As verificações da faixa de miniaturas cobrem a troca rápida, o cancelamento fora da tela e a prevenção de retornos de chamada antigos que contaminam a lista atual.

Listas completas de arquivos e hashes do aplicativo instalado e `outputs/LumaView.app` corresponderam e ambos passaram por `codesign --verify --deep --strict`. Foi feito backup do ZIP antigo antes da instalação; associações de abertura padrão não foram modificadas. O ZIP entregue foi verificado separadamente para CRC e versão. O relatório histórico completo 1.7.0 permanece em `Tests/Release-1.7.0.md`; suas verificações que não foram executadas novamente não são incluídas nesta rodada.

Executável principal SHA-256: `cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`.

## Registros

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
