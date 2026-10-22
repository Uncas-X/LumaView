# LumaView — Português (Brasil)

<!-- language-navigation:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · **Português (Brasil)** · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- language-navigation:end -->

Este é um guia rápido. Consulte os manuais completos em [inglês](README.en.md) ou [chinês](../../README.md).

O LumaView é um visualizador nativo para macOS de imagens, vídeos, áudio e documentos multipágina. A navegação se inspira no Picasa Photo Viewer, mas o aplicativo tem nome e ícone próprios, sem vínculo com o Google. O foco é visualizar arquivos, sem editar fotos ou administrar bibliotecas.

## Download e instalação

**Versão 1.7.2, compilação 14.** Requer macOS 13 ou posterior. O aplicativo universal funciona em Macs com processadores Intel e Apple Silicon.

1. Baixe o [LumaView para macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip). As versões anteriores estão em [Releases](https://github.com/Uncas-X/LumaView/releases).
2. Descompacte o arquivo e arraste `LumaView.app` para a pasta Aplicativos.
3. Abra o aplicativo. Ele usa assinatura ad hoc local, sem notarização da Apple. Após verificar a origem, talvez precise permitir a abertura em **Privacidade e Segurança** nas configurações do macOS.

## Navegação e recursos

Arraste um arquivo ou pasta para a janela, ou pressione **Cmd+O**. Abrir um arquivo permite navegar pela mídia da mesma pasta. A busca considera apenas o nível atual, sem percorrer subpastas.

- A faixa de miniaturas facilita a navegação. Há zoom, deslocamento, rotação, tela cheia, transições suaves e fundo translúcido com efeito de vidro fosco.
- A transparência de PNG, GIF, PSD e PSB permanece transparente; as sombras acompanham o conteúdo. Páginas de documentos usam papel branco. PSD e PSB exibem a composição de compatibilidade salva, não suas camadas.
- Vídeo e áudio usam primeiro a reprodução nativa. O FFmpeg incluído atende a formatos adicionais, mas pode precisar preparar o arquivo inteiro localmente antes da reprodução. Áudio mostra a capa incorporada ou, na ausência dela, a forma de onda. Seus controles de reproduzir/pausar e parar são independentes da apresentação de slides.
- PDF, AI compatível com PDF e TIFF multipágina permitem navegar entre páginas. SVG, EPS/PS compatíveis e AI antigo têm renderização vetorial. EPS/PS usam o Ghostscript incluído; imagens bitmap incorporadas continuam limitadas à resolução original.
- O menu do botão direito permite abrir em outro aplicativo, mostrar no Finder e copiar uma imagem, o quadro atual de um vídeo, uma página de PDF ou uma imagem incorporada em PDF quando compatível.

Nas configurações, escolha os formatos associados ao LumaView e o idioma. Há 16 idiomas; por padrão, o aplicativo acompanha o sistema.

## Atalhos

| Tecla | Ação |
| --- | --- |
| Cmd+O | Abrir arquivo ou pasta |
| ← / → | Arquivo ou página anterior/seguinte, conforme o foco |
| ↑ / ↓ | Alternar o foco entre páginas e arquivos em documentos multipágina |
| Roda do mouse / gesto de pinça / + / − | Ajustar o zoom |
| 0 / 1 | Ajustar à janela / alternar entre 100% e ajuste à janela |
| Cmd+R | Girar |
| F | Alternar tela cheia |
| P / S | Reproduzir ou pausar mídia / parar |
| Cmd+4 | Controlar a apresentação de slides |
| Cmd+C | Copiar imagem, quadro ou página |

**Espaço muda o fundo; não controla a reprodução.**

## Compilar

Instale o Xcode ou as ferramentas de linha de comando do Swift. O repositório inclui ferramentas de mídia, arquivos de código-fonte e licenças correspondentes. Execute na raiz do repositório:

```bash
./build.sh
open ../LumaView.app
```

`./build.sh --host` compila somente para a arquitetura do Mac atual. Os arquivos gerados ficam em `.build/`; `LUMAVIEW_WORK_ROOT` altera essa pasta e `LUMAVIEW_APP_PATH` altera o caminho do aplicativo de saída.

## Limitações e privacidade

O aplicativo lê arquivos locais, não envia conteúdo à nuvem e não modifica os originais. Não oferece edição, edição de camadas, banco de dados de biblioteca ou sincronização na nuvem. Imagens grandes podem usar prévias reduzidas: ampliar não recupera detalhes removidos dessa prévia. Não há garantia de todos os codecs; arquivos com DRM, corrompidos ou incompatíveis podem falhar. Conversões usam cache no disco local e podem demorar.

Veja a [cobertura técnica de formatos](../../FORMATS.md), em chinês, e os avisos de terceiros para [ferramentas de mídia](../../ThirdParty/README.md) e [Ghostscript](../../ThirdParty/README-Ghostscript.md).
