# LumaView 1.7.2

<!-- doc-navigation:start -->
[Documentação](../i18n/pt-BR/INDEX.md) · [简体中文](../i18n/zh-Hans/README.md) · [繁體中文](../i18n/zh-Hant/README.md) · [English](../i18n/en/README.md) · [日本語](../i18n/ja/README.md) · [한국어](../i18n/ko/README.md) · [Français](../i18n/fr/README.md) · [Deutsch](../i18n/de/README.md) · [Español](../i18n/es/README.md) · [Italiano](../i18n/it/README.md) · **Português (Brasil)** · [Русский](../i18n/ru/README.md) · [العربية](../i18n/ar/README.md) · [हिन्दी](../i18n/hi/README.md) · [Türkçe](../i18n/tr/README.md) · [Nederlands](../i18n/nl/README.md) · [Polski](../i18n/pl/README.md)
<!-- doc-navigation:end -->


**[Baixe o aplicativo macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)** · [Versões e notas de versão](https://github.com/Uncas-X/LumaView/releases)

Requer macOS 13+. O mesmo pacote suporta Intel e Apple Silicon. Extraia o ZIP baixado e arraste `LumaView.app` para Aplicativos para instalá-lo.

Um visualizador de mídia nativo do macOS inspirado nos hábitos de visualização rápida do Picasa Photo Viewer, com navegação na mesma pasta, zoom, movimento panorâmico, rotação, faixa de miniaturas, tela inteira e apresentações de slides. A versão 1.5 adicionou capas de áudio e formas de onda reais, navegação em documentos de várias páginas, uma tela vetorial redesenhada no zoom atual e configurações de idioma que seguem o sistema por padrão. Ele usa um nome independente e um ícone original e não pretende reproduzir todos os recursos ou interações de lançamentos históricos do Picasa.

A versão 1.7.2 unifica a transparência da imagem: áreas transparentes de imagens raster como PNG, GIF e PSD / PSB revelam o plano de fundo da visualização atual. As sombras seguem o contorno e a opacidade reais da imagem; não há tabuleiro de xadrez ou sombra retangular ao redor de toda a tela transparente. Documentos como PDF mantêm um fundo de papel branco.

As melhorias de visualização de PSD / PSB de 1.7.1 permanecem: a faixa de miniaturas prefere um JPEG incorporado válido, enquanto a visualização principal decodifica o composto de compatibilidade real. RLE usa leituras fragmentadas e um problema que impedia a geração de miniaturas para alguns compostos pequenos com perfis ICC foi corrigido.

## Uso e instalação

Requer macOS 13 ou posterior, com suporte para Intel e Apple Silicon.

1. Baixe `LumaView-macOS.zip` de [Releases](https://github.com/Uncas-X/LumaView/releases), extraia-o, arraste `LumaView.app` para Aplicativos e abra-o.
2. Solte uma imagem, vídeo, arquivo de áudio ou pasta no aplicativo ou pressione `⌘O` para selecionar os arquivos. Abrir um arquivo lista a mídia na mesma pasta; selecionar vários arquivos navega nessa seleção. As verificações de pastas cobrem apenas o nível atual e não recorrem a subpastas.
3. No Finder, você também pode clicar com o botão direito em um arquivo e escolher Abrir com → LumaView.

As compilações locais usam uma assinatura ad hoc e não foram autenticadas pela Apple. Se o Gatekeeper bloquear uma cópia baixada em outro Mac, verifique sua origem e use a opção Privacidade e Segurança do sistema para permitir sua abertura.

## Configurações do aplicativo padrão

Escolha **LumaView → Aplicativo padrão…**, pressione `⌘,` ou abra as configurações no menu Mais. Os formatos são agrupados em imagens, vetores/documentos, vídeo e áudio. Pesquise e selecione formatos e clique em Definir como padrão para formatos selecionados. Sempre que a caixa de diálogo é aberta, o aplicativo fica ativo novamente ou as alterações são concluídas, ele lê as associações reais do sistema: uma marca de seleção significa que todos os tipos do grupo são abertos com esta cópia do LumaView; um travessão significa que apenas alguns tipos o fazem ou ainda apontam para outra cópia. As associações do sistema persistem durante as reinicializações; as seleções não aplicadas não são apresentadas como configurações aplicadas com êxito. Selecionar Todos os Formatos na parte superior abrange todas as imagens, documentos vetoriais, vídeo e áudio, independentemente do filtro de pesquisa; categorias individuais ainda podem ser selecionadas separadamente. Limpar apenas limpa a seleção atual e não remove os padrões existentes do sistema.

As configurações exibem o progresso e leem cada resultado do sistema. Cancelar interrompe alterações subsequentes; as alterações concluídas permanecem. A lista de formatos representa associações de arquivos selecionáveis, e não uma afirmação de que cada codificação interna ou arquivo foi testado. Consulte [Formatos e visualizações](../i18n/pt-BR/FORMATS.md) para obter detalhes.

## Visualização e reprodução

Abrir o primeiro arquivo expande a janela para a área disponível da tela atual. Pressione `F` para tela cheia. Clique na faixa de miniaturas inferior para alterar os arquivos. Os controles ficam ocultos depois que o ponteiro permanece na área de visualização por um tempo e reaparecem quando ele se move.

A versão 1.5.2 corrigiu miniaturas em branco ou piscando repetidamente durante a navegação estendida em pastas grandes: as miniaturas visíveis são retidas de forma independente e o carregamento fora da tela é cancelado imediatamente. Os resultados da pasta anterior não podem entrar na nova lista. Arquivos não decodificáveis ​​exibem um espaço reservado estável e podem ser repetidos quando seu intervalo for revisitado.

Imagens e vídeos suportam zoom, panorâmica, rotação e tela cheia. Mudanças de janela, mudanças de imagem, zoom e rotação usam transições curtas e suaves que entradas adicionais podem interromper. Ativar a configuração Reduzir movimento do sistema desativa essas transições personalizadas enquanto as imagens animadas continuam sendo reproduzidas. O fundo padrão é vidro fosco translúcido; pressione Espaço para percorrer fundos foscos, escuros e claros.

A transparência raster segue uma regra: mostra o plano de fundo atual e projeta sombras apenas nos pixels que contêm conteúdo visível, mantendo a opacidade das bordas translúcidas. GIF / APNG as sombras mudam a cada quadro. Copiar uma imagem preserva seus pixels transparentes originais e exclui o fundo e a sombra do visualizador.

Os controles de reprodução de áudio/vídeo, parada, posição e volume aparecem acima da faixa de miniaturas. A mídia é reproduzida automaticamente quando aberta e permanece no final quando finalizada; pressione `P` para repetir ou `S` para parar e retornar ao início. O botão de apresentação de slides abaixo é independente da reprodução de mídia: após `⌘4` iniciar a reprodução contínua, as imagens avançam no intervalo selecionado, enquanto o áudio/vídeo termina antes de avançar. A reprodução de um arquivo de áudio/vídeo individual não passa automaticamente para o próximo item.

A reprodução nativa do macOS é tentada primeiro. Se o sistema não puder reproduzir o arquivo diretamente, FFmpeg 9.0.2 e dav1d 1.5.3 universais agrupados preparam um arquivo compatível localmente, tentando primeiro uma alteração no contêiner quando apropriado e depois transcodificando. Nenhum player separado, Homebrew ou pacote de codecs é necessário e nenhum acesso à rede é usado. A reprodução de compatibilidade aguarda a preparação de todo o arquivo, mostrando o progresso; alterar arquivos ou fechar a janela cancela a preparação. Preparar um vídeo longo pela primeira vez pode consumir muito tempo e espaço extra em disco.

Pressione `C` ou use o menu Mais para configurar o loop, o comportamento da roda, o fechamento ao clicar no fundo, a faixa de miniaturas, a classificação e os intervalos da apresentação de slides (2, 3, 5, 8 ou 10 segundos). A roda amplia por padrão; segure `Ctrl` para navegar pelos arquivos temporariamente. Se a roda estiver configurada para navegar, `Ctrl` aplica zoom temporariamente. Clicar no plano de fundo fora da imagem fecha o visualizador por padrão. Essas preferências são armazenadas localmente.

## Menu de contexto e cópia

Clique com o botão direito (ou clique com a tecla Control pressionada) na visualização principal para escolher Abrir com → Aplicativo / Outro aplicativo… ou Mostrar no Finder. Abrir com afeta apenas esta abertura e não altera as associações padrão. Ambas as opções permanecem disponíveis para arquivos não decodificáveis.

- Imagens: escolha Copiar imagem. Isso preserva a rotação da visualização e os pixels transparentes e copia toda a imagem atualmente decodificada, sem capturar barras de ferramentas ou apenas a região ampliada da tela.
- Vídeo: escolha Copiar quadro atual. Isso copia o quadro correspondente ao momento em que o menu de contexto foi aberto, preservando a orientação do vídeo e a rotação da visualização sem alterar a posição ou o estado da reprodução.
- PDF / AI compatível com PDF: clique com o botão direito em um bitmap em uma página para Copiar esta imagem ou escolha Copiar página atual. A identificação da imagem clicada segue a posição real após zoom, panorâmica e rotação. Texto comum e regiões vetoriais não são tratadas como imagens; máscaras complexas ou espaços de cores usam o resultado visível da região da imagem, que pode incluir texto sobreposto. Uma página digitalizada como uma imagem é copiada como a digitalização inteira.
- `⌘C` copia a imagem, quadro de vídeo ou página do documento atual; o áudio não fornece cópia de imagem. A área de transferência recebe PNG e TIFF. Alterar arquivos/páginas ou fechar o visualizador evita que resultados de cópias obsoletos substituam a área de transferência.

Cópias de páginas de documentos e imagens incorporadas são bitmaps limitados a um lado maior de 8192 pixels e aproximadamente 32 megapixels; As instruções do vetor PDF/SVG não são colocadas na área de transferência. Se uma imagem grande estiver exibindo uma visualização limitada, essa visualização será copiada. A análise de imagens PDF tem limites de complexidade: estruturas especiais, como imagens dentro de preenchimentos de padrão, podem não ser selecionáveis ​​individualmente, mas a página atual ainda pode ser copiada.

Os cabeçalhos padrão SVG 1.0/1.1 são analisados offline sem carregar DTDs externos. A versão 1.7 agrupa Ghostscript 10.08.0 para converter EPS/PostScript e AI baseado em PostScript antigo em PDF, mantendo caminhos, texto e imagens incorporadas. A visualização principal redesenha vetores no zoom atual; PS de várias páginas usa a navegação de página existente. Nenhuma instalação adicional é necessária. Se a conversão falhar, mas o EPS tiver um TIFF incorporado válido, ele poderá retornar a essa visualização, claramente identificada como TIFF. Imagens raster dentro do original não se tornam vetores.

## Áudio, documentos e idiomas

O áudio mostra a capa incorporada na visualização principal, quando disponível. Caso contrário, as amostras reais serão analisadas de forma assíncrona para exibir uma forma de onda para a trilha completa. Um espaço reservado aparece durante a análise e a reprodução não precisa esperar. As miniaturas de áudio e vídeo usam o mesmo emblema `▶ duração` no canto inferior direito, com fonte, plano de fundo e posição correspondentes; antes que a duração esteja disponível, eles mostram `▶ –:––`. A capa vem de metadados de arquivo incorporados, sem pesquisar na rede ou em arquivos vizinhos.

PDF, AI compatível com PDF e TIFF de várias páginas permitem navegar pelas páginas. Miniaturas de páginas menores, um controle deslizante de progresso da página e números de páginas atuais/totais aparecem acima da faixa de miniaturas do arquivo. Pressione `↑` para focar nas páginas e `↓` para focar nos arquivos. A miniatura selecionada na linha em foco possui uma borda laranja; a outra linha mantém sua seleção com uma borda cinza. Nenhum rótulo extra de páginas/arquivos é mostrado. `←` / `→`, `J` / `K` e `Home` / `End` atuam no foco atual. Clicar em uma linha também a focaliza. A navegação da página para na primeira e na última página sem passar inesperadamente para outro arquivo. Os botões inferiores de arquivo anterior/seguinte sempre alteram os arquivos. A navegação de página permanece disponível quando a faixa de miniaturas do arquivo está oculta.

PDF, SVG e AI compatível com PDF desenham a região visível das instruções do vetor original no zoom atual, em vez de ampliar uma visualização fixa. As regiões de documentos transparentes usam papel branco comum, sem tabuleiro de xadrez. Ao trocar de página, a nova página é preparada por inteiro e então aparece com uma transição suave de entrada; o desenho de detalhes vetoriais de fundo não deixa blocos em branco aparecendo um de cada vez. As fotos incorporadas e outros bitmaps permanecem limitados pela resolução original.

Escolha **LumaView → Idioma…**, também disponível no menu Mais. O padrão segue o sistema, com suporte para Chinês Simplificado, Chinês Tradicional, Inglês, Japonês, Coreano, Francês, Alemão, Espanhol, Italiano, Português, Russo, Árabe, Hindi, Turco, Holandês e Polonês. Menus de aplicativos, dicas de ferramentas, paginação e configurações são atualizados imediatamente e o idioma selecionado é salvo localmente. Os idiomas do sistema não suportados voltam para o inglês; erros incomuns de decodificação também podem aparecer em inglês. Nomes de arquivos, caminhos e texto dentro dos arquivos permanecem inalterados.

## Teclado e mouse

| Ação | Atalho / gesto |
| --- | --- |
| Item anterior/próximo (foco atual) | `←` / `→` ou `J` / `K` |
| Focar páginas/arquivos | `↑` / `↓` (documentos de várias páginas) |
| Primeiro/último item | `Home` / `End` |
| Abra arquivos ou uma pasta | `⌘O` |
| Configurações do aplicativo padrão | `⌘,` |
| Zoom | Roda, gesto de pinça no trackpad, `+` / `−`, `Page Up` / `Page Down` |
| Alterar temporariamente o comportamento da roda | Segure `Ctrl` enquanto rola |
| 100% / ajustar à janela | Clique na imagem ou `1` |
| Ajustar à janela | `0` |
| Panorâmica de uma imagem ou vídeo ampliado | Arraste a visualização |
| Girar visualização no sentido horário | `⌘R` / `Ctrl+R`; adicione `Shift` para sentido anti-horário |
| Alternar o fundo | Barra de espaço |
| Entrar/sair da tela cheia | `F` / `⌃⌘F` / `F11` (quando não reservado pelo sistema) |
| Reproduzir/pausar áudio ou vídeo | `P` |
| Pare a mídia e retorne ao início | `S` |
| Iniciar/parar apresentação de slides e reprodução contínua | `⌘4` |
| Retroceder / avançar 5 segundos na mídia | `Option + ←` / `Option + →` |
| Ativar/desativar som | `M` |
| Informações do arquivo | `I` / `⌘I` |
| Mostrar/ocultar faixa de miniaturas | `T` / `⌘T` |
| Mais opções | `C` |
| Mostrar o arquivo atual no Finder | `⌘Return` |
| Pausar a reprodução, fechar informações, sair da tela cheia, fechar a janela | `Esc`, tratado em ordem de acordo com o estado atual |
| Minimizar / fechar / sair | `⌘M` / `⌘W` / `⌘Q` |

`P` controla apenas o áudio/vídeo atual, não as apresentações de slides de imagens. Ajuda → Teclado e Mouse também fornece um guia no aplicativo.

## Cobertura e limitações

- As imagens usam decodificação do sistema ImageIO. O suporte real para JPEG, PNG, GIF, HEIC, TIFF, BMP, WebP, RAW e outros formatos depende da versão do sistema e do conteúdo do arquivo.
- Imagens muito grandes não são mais rejeitadas apenas por excederem 150 megapixels. Para limitar a memória, as visualizações podem ser reduzidas, preservando as dimensões originais e os metadados de orientação. 100% zoom ainda é calculado a partir das dimensões originais, mas não pode recuperar detalhes de pixels omitidos na decodificação de visualização.
- A exibição vetorial suporta SVG, PDF, AI compatível com PDF e EPS / PS / AI antigo processado pelo interpretador incluído. PDF / AI / PS de várias páginas suporta navegação; SVG rejeita scripts e recursos externos. Os bitmaps incorporados mantêm seus limites de resolução originais e fontes não incorporadas indisponíveis podem ser substituídas.
- PostScript é executado em um processo separado com SAFER e uma sandbox do sistema, permitindo apenas a entrada e saída preparadas e negando o acesso à rede. Mudanças rápidas de arquivo podem cancelá-lo; miniaturas e a visualização principal compartilham resultados armazenados em cache concluídos. Cada interpretação é limitada a 90 segundos e 1 GB de saída, com um destino de limpeza de cache de 2 GB.
- Photoshop PSD / PSB mostra a composição salva no arquivo, sem edição de camadas. Telas muito grandes usam visualizações com orçamento de memória e mantêm as dimensões originais; consulte FORMATS.md para modos de cores, profundidades de bits e compactação suportados.
- A decodificação alternativa integrada expande a cobertura de áudio/vídeo, mas DRM, arquivos danificados e codificações proprietárias sem um decodificador disponível ainda podem falhar. Uma extensão não garante que a codificação interna possa ser decodificada. Nem todos os formatos, dispositivos ou versões de sistema foram testados individualmente.
- O cache de compatibilidade possui um destino de limpeza de 2 GB; arquivos ativos podem excedê-lo temporariamente. Um único arquivo preparado é limitado a 8 GB, com pelo menos 512 MB de espaço livre em disco reservado. A preparação é interrompida e exibe uma mensagem se o espaço for insuficiente.
- TIFF suporta múltiplas páginas; outros formatos de imagem compostos sem paginação implementada mostram a primeira imagem. A rotação da visualização nunca é gravada nos arquivos originais. Edição, exclusão, banco de dados de biblioteca, compartilhamento, sincronização em nuvem e gerenciamento externo de legendas não são fornecidos.
- O aplicativo lê apenas a mídia local aberta pelo usuário e a pasta que a contém. A reprodução de compatibilidade grava em um cache local; ele não envia mídia nem modifica originais.

Consulte [FORMATS.md](../i18n/pt-BR/FORMATS.md) para obter mais exemplos de formato e limites de cache/visualização.

## Compilar a partir do código-fonte

Requer Xcode ou ferramentas de linha de comando com o compilador Swift. O repositório e o pacote fonte incluem ferramentas universais de mídia Intel/Apple Silicon, portanto, uma compilação normal não requer instalação ou download separado de terceiros. Após clonar ou baixar, construa a partir da raiz do repositório contendo `build.sh`; o layout original do espaço de trabalho de desenvolvimento não é necessário.

```bash
cd /path/to/LumaView
./build.sh
open ../LumaView.app
```

O padrão produz um aplicativo universal; `./build.sh --host` cria apenas a arquitetura Mac atual. O aplicativo é colocado ao lado do diretório de origem como `LumaView.app` por padrão; defina `LUMAVIEW_APP_PATH` para outro destino. Os arquivos de trabalho de compilação e teste são padronizados como `.build/` dentro do repositório e podem ser realocados com `LUMAVIEW_WORK_ROOT`. Esses arquivos gerados são excluídos por `.gitignore`.

As compilações de teste usam `LUMAVIEW_TEST_BUILD=1 ./build.sh --host` para criar um aplicativo LumaView Tests separado sem declarações de abertura de arquivo, evitando que cópias de teste concorram com o aplicativo instalado. Os scripts de teste de UI usam esse modo por padrão. Use `LUMAVIEW_SKIP_TEST_BUILD=1` e `LUMAVIEW_TEST_APP_PATH` para selecionar um aplicativo já criado.

FFmpeg é construído sob LGPL 2.1 ou posterior, e dav1d vinculado estaticamente usa BSD 2-Clause. Arquivos de origem, somas de verificação e licenças correspondentes acompanham o pacote de origem. A reconstrução das ferramentas de mídia requer ferramentas de linha de comando Xcode, Python 3, Meson 1.12.1 e Ninja 1.13.2; instale as ferramentas Python em um ambiente virtual e execute `./tools/build-media-tools.sh`. Consulte [ThirdParty/README.md](../i18n/pt-BR/ThirdParty/README.md) para etapas e configuração de compilação. PostScript usa um executável Ghostscript 10.08.0 separado (AGPL-3.0-or-later), com sua licença, fonte completa correspondente e script de construção incluídos. As compilações normais de aplicativos usam o componente universal incluído; consulte o [guia Ghostscript](../i18n/pt-BR/ThirdParty/README-Ghostscript.md) para reconstrução.

## Fonte e validação

- `Sources/`: Interface AppKit, tela de mídia, carregamento raster e vetorial, ciclo de vida de áudio/vídeo, preparação de compatibilidade e configurações padrão do aplicativo.
- `Resources/Localizations/`: strings de idiomas e a lista principal de chaves de tradução.
- `Resources/MediaFormats.json`: catálogo de formatos; `Resources/MediaTools/`: FFmpeg/ffprobe incluído.
- `ThirdParty/sources/`, `Resources/ThirdPartyNotices/`: fontes e licenças de ferramentas de mídia correspondentes.
- `build.sh`: compilação, empacotamento e assinatura local de aplicativos universais; `tools/build-media-tools.sh`: reconstruindo ferramentas de mídia.

```bash
./Tests/run-core-tests.sh
./Tests/run-thumbnail-tests.sh
./Tests/run-thumbnail-request-tests.sh
./Tests/run-canvas-tests.sh
./Tests/run-ui-tests.sh
./Tests/run-video-tests.sh
./Tests/run-default-application-tests.sh
./Tests/run-default-preferences-tests.sh
./Tests/run-media-declaration-tests.sh
./Tests/run-document-tests.sh
./Tests/run-vector-compatibility-tests.sh
./Tests/run-postscript-tests.sh
./Tests/run-photoshop-tests.sh
./Tests/run-pdf-image-copy-tests.sh
./Tests/run-media-copy-tests.sh
./Tests/run-context-menu-tests.sh
./Tests/run-large-document-tests.sh
./Tests/run-audio-waveform-tests.sh
./Tests/run-audio-visual-tests.sh
./Tests/run-localization-tests.sh
```

Os testes unitários de decodificação de áudio precisam de um FFmpeg de desenvolvimento com os codificadores relevantes para gerar amostras MP3 / FLAC / Opus. Defina `LUMAVIEW_TEST_FFMPEG` como seu caminho. Os testes de aplicativo e interface de áudio usam apenas componentes agrupados.

As verificações de integração da IU exigem uma sessão iniciada na área de trabalho gráfica do macOS. Eles abrem o aplicativo e verificam as interações usando a mídia gerada. Os arquivos de construção e os relatórios de teste salvos são padronizados como `.build/`; alguns arquivos de teste usados durante a execução usam o diretório temporário do sistema. Os testes não leem fotos pessoais por padrão. Os testes de cópia do menu de contexto usam uma área de transferência nomeada separada sem substituir a área de transferência atual do usuário. Os testes Abrir com / Finder / aplicativo padrão usam simulações e não alteram associações de arquivos. Consulte [TEST-RESULTS.txt](../i18n/pt-BR/TEST-RESULTS.md) para obter o registro de validação da versão entregue.

Os relatórios salvos em `Tests/` são registros históricos de suas respectivas versões e não são evidências de que um novo check-out passou automaticamente nos testes no ambiente atual. Os nomes de amostras pessoais são anonimizados e a mídia original não é incluída no repositório. Os caminhos históricos `work/` registram as fontes de teste naquele momento e não são diretórios necessários para compilações atuais. O repositório preserva arquivos de origem, somas de verificação e licenças de terceiros correspondentes, de modo que o clone inicial é relativamente grande.
