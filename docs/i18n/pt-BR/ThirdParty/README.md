# Ferramentas de mídia incluídas

<!-- doc-navigation:start -->
[Documentação](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · **Português (Brasil)** · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView invoca FFmpeg 9.0.2 e ffprobe não modificados como processos locais separados. Eles são criados a partir do código-fonte para Intel e Apple Silicon, direcionados ao macOS 13. Eles usam dav1d 1.5.3 estaticamente vinculado para decodificação AV1 e apenas bibliotecas dinâmicas do sistema. Homebrew e VLC não são necessários em tempo de execução.

O FFmpeg está configurado em LGPL 2.1 ou posterior, sem `--enable-gpl` ou `--enable-nonfree`. dav1d usa a licença BSD 2-Clause. Os avisos de licença completos estão em `Resources/ThirdPartyNotices` e são copiados no pacote de aplicativos. Os arquivos de origem correspondentes exatos e não modificados estão incluídos em `sources/`, com somas de verificação SHA-256. Todos os sinalizadores de configuração e etapas de construção estão em `tools/build-media-tools.sh`. O LumaView não impõe nenhuma restrição adicional à modificação ou substituição dessas ferramentas separadas, ou à engenharia reversa necessária para depurar tais modificações.

Fontes oficiais:

- [Lançamento e assinatura do FFmpeg](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. Sua assinatura desanexada foi verificada em relação à chave de lançamento do FFmpeg `FCF986EA15E6E293A5644F10B4322F04D67658D8`.
- [Versão do dav1d](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [Informações sobre licença FFmpeg](https://ffmpeg.org/legal.html).

## Recompilar

A construção normal do aplicativo usa os binários universais incluídos. Para reconstruir essas ferramentas, instale ferramentas de linha de comando Xcode, Python 3, Meson 1.12.1 e Ninja 1.13.2. Por exemplo, use um ambiente virtual Python local e instale `meson==1.12.1 ninja==1.13.2` lá. Ative-o e execute:

```sh
./tools/build-media-tools.sh
./build.sh
```

O primeiro comando verifica as somas de verificação de origem, compila ambas as arquiteturas e substitui `Resources/MediaTools/{ffmpeg,ffprobe}`. Use `LUMAVIEW_PYTHON` para selecionar Python e `LUMAVIEW_MEDIA_BUILD` para selecionar o diretório de construção intermediário. Os argumentos `x86_64` ou `arm64` compilam uma única arquitetura; o padrão `universal` os combina. A compilação do aplicativo assina as ferramentas aninhadas e o aplicativo com uma assinatura ad hoc local.

Rede, dispositivos de captura, ffplay, codecs externos diferentes de dav1d e codificadores GPL estão desabilitados. Todos os decodificadores/demuxers internos disponíveis para esta configuração estão incluídos. A saída de áudio é preparada como AAC; o vídeo usa remux sempre que possível e, em seguida, VideoToolbox H.264, MPEG-4 ou saída de compatibilidade ProRes. Este é um caminho de visualização, não uma interface de exportação ou transcodificação.

## Intérprete vetorial PostScript

EPS, PostScript e visualização legada do Illustrator também usam Ghostscript 10.08.0 agrupado como um subprocesso local restrito e separado. Consulte [README-Ghostscript.md](README-Ghostscript.md) para obter sua licença AGPL-3.0-or-later, arquivo fonte correspondente completo, somas de verificação e compilação universal reproduzível. A construção comum do aplicativo não precisa de instalação do sistema Ghostscript.
