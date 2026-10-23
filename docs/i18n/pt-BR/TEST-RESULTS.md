# Registro de validação LumaView 1.7.2

<!-- doc-navigation:start -->
[Documentação](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · [繁體中文](../zh-Hant/TEST-RESULTS.md) · [English](../en/TEST-RESULTS.md) · [日本語](../ja/TEST-RESULTS.md) · [한국어](../ko/TEST-RESULTS.md) · [Français](../fr/TEST-RESULTS.md) · [Deutsch](../de/TEST-RESULTS.md) · [Español](../es/TEST-RESULTS.md) · [Italiano](../it/TEST-RESULTS.md) · **Português (Brasil)** · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · [Türkçe](../tr/TEST-RESULTS.md) · [Nederlands](../nl/TEST-RESULTS.md) · [Polski](../pl/TEST-RESULTS.md)
<!-- doc-navigation:end -->


Versão 1.7.2, compilação 14. Testado em 2026-10-22 com macOS 15.7.9/Intel. O aplicativo e as ferramentas incluídas foram verificados como binários universais arm64 + x86_64 com assinaturas locais. Esta rodada não foi executada em hardware Apple Silicon.

## Correção nesta versão

Imagens raster agora mostram regiões transparentes de forma consistente: PNG / GIF / PSD / PSB e outros não desenham mais um tabuleiro de xadrez cinza-branco ou uma borda retangular de tela. As sombras de exibição derivam do alfa composto real da imagem atual, em vez de toda a tela da imagem. As margens transparentes, portanto, não possuem sombra retangular extra; buracos, máscaras suaves separadas e regiões translúcidas contribuem para o contorno real.

A implementação antiga apenas olhava para CGImage.alphaInfo ao adicionar o tabuleiro de damas, faltando arquivos PSB com uma máscara Quartz separada. Também forçou um shadowPath retangular em cada zoom, e a própria borda produziu uma sombra retangular. Essas fontes retangulares foram removidas para imagens rasterizadas; as sombras da camada agora seguem o alfa composto automaticamente. O desenho de exportação também projeta uma sombra da própria imagem sem preencher primeiro um retângulo. As alterações de quadro GIF / APNG substituem a textura atual e atualizam a sombra sem digitalizar os pixels transparentes de cada quadro ou construir uma imagem RGBA extra completa.

As páginas do documento mantêm o papel branco e as superfícies de vídeo mantêm o retângulo existente. A cópia de imagem ainda usa pixels da imagem original sem o fundo do visualizador, o tabuleiro de xadrez ou a sombra da tela. O decodificador PSB, o agendador de miniaturas e o caminho de visualização rápida da versão anterior não foram alterados.

## Validação nesta rodada

| Verificação | Aprovado |
| --- | --- |
| Transparência, sombras de contorno e trocas de quadro | 133 / 133 |
| Geometria da tela, animação e mouse | 66 / 66 |
| Análise de documentos e renderização de página completa | 56 / 56 |
| Aplicativo de lançamento instalado: documentos, zoom EPS/PS, navegação de página e foco | 75 / 75 |
| Aplicativo de lançamento instalado: menus de contexto e cópia | 28 / 28 |
| Total | 358 / 358 |

Os testes de transparência usaram um gráfico com furo, saliências irregulares e grandes margens transparentes, codificado separadamente como RGBA, uma máscara Quartz separada e arquivos PNG, GIF, PSD e PSB reais que foram codificados e decodificados. A composição de CALayer e os pixels exportados de `draw` foram verificados para confirmar a ausência de fundo ou sombra retangular nas bordas transparentes e a presença de sombras nos contornos internos e externos. Imagens totalmente transparentes, mudanças de quadro, rotação e zoom, troca rápida e um fundo translúcido do visualizador também foram abordados. PNGs exportados foram inspecionados visualmente.

Para essas seis entradas, o PNG SHA-256 da exportação CALayer e a exportação PNG `draw` eram idênticos: `578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`. A mídia de teste foi gerada por código; nenhuma foto pessoal foi adicionada à fonte.

Uma sonda de renderização de software limitada também comparou as sombras novas e antigas no ajuste à janela, 100% e 3200% em um bitmap de 32 MP com telas lógicas de 16,384 × 7,812 e 300,000 × 128. O pico de RSS do processo de teste foi de cerca de 428 MiB; os tempos de renderização antigos e novos eram semelhantes. Isso mede instantâneos de software por meio de `CALayer.render(in:)`, não de taxas de quadros de GPU. Como resultado, nenhum cache raster de camada foi adicionado.

As listas completas de arquivos e os hashes da versão instalada e de `outputs/LumaView.app` coincidem; ambos passaram em `codesign --verify --deep --strict`. O ZIP anterior foi copiado antes da instalação. As associações de abertura padrão foram lidas antes e depois. Seguiram-se verificações de CRC e versão do ZIP entregue. Os relatórios históricos permanecem em `Tests/Release-1.7.0.md` e `Tests/Release-1.7.1.md`; as verificações não executadas novamente desses lançamentos não entram na contagem desta rodada.

Executável principal SHA-256: `b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`.

## Fontes de registro

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
