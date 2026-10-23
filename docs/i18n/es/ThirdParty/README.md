# Herramientas multimedia incluidas

<!-- doc-navigation:start -->
[Documentación](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · **Español** · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView invoca FFmpeg 9.0.2 y ffprobe no modificados como procesos locales separados. Estos están creados a partir de fuentes para Intel y Apple Silicon, dirigidos a macOS 13. Utilizan dav1d 1.5.3 vinculado estáticamente para la decodificación AV1 y solo bibliotecas dinámicas del sistema. Homebrew y VLC no son necesarios en tiempo de ejecución.

FFmpeg está configurado bajo LGPL 2.1 o posterior, sin `--enable-gpl` o `--enable-nonfree`. dav1d utiliza la licencia BSD 2-Clause. Los avisos de licencia completos se encuentran en `Resources/ThirdPartyNotices` y se copian en el paquete de la aplicación. Los archivos fuente correspondientes exactos y sin modificar se incluyen en `sources/`, con sumas de verificación SHA-256. Todos los indicadores de configuración y los pasos de compilación están en `tools/build-media-tools.sh`. LumaView no impone restricciones adicionales a la modificación o reemplazo de estas herramientas independientes, ni a la ingeniería inversa necesaria para depurar dichas modificaciones.

Fuentes oficiales:

- [Lanzamiento y firma de FFmpeg](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. Su firma separada se verificó con la clave de versión de FFmpeg `FCF986EA15E6E293A5644F10B4322F04D67658D8`.
- [Versión de dav1d](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [Información de licencia de FFmpeg](https://ffmpeg.org/legal.html).

## Volver a compilar

La compilación normal de la aplicación utiliza los binarios universales incluidos. Para reconstruir esas herramientas, instale Xcode Command Line Tools, Python 3, Meson 1.12.1 y Ninja 1.13.2. Por ejemplo, utilice un entorno virtual Python local e instale `meson==1.12.1 ninja==1.13.2` allí. Actívalo y luego ejecuta:

```sh
./tools/build-media-tools.sh
./build.sh
```

El primer comando verifica las sumas de verificación de origen, compila ambas arquitecturas y reemplaza `Resources/MediaTools/{ffmpeg,ffprobe}`. Utilice `LUMAVIEW_PYTHON` para seleccionar Python y `LUMAVIEW_MEDIA_BUILD` para seleccionar el directorio de compilación intermedio. Los argumentos `x86_64` o `arm64` compilan una única arquitectura; el `universal` predeterminado los combina. La compilación de la aplicación firma las herramientas y la aplicación anidadas con una firma ad hoc local.

Las redes, los dispositivos de captura, ffplay, los códecs externos distintos de dav1d y los codificadores GPL están deshabilitados. Se incluyen todos los decodificadores/demuxers internos disponibles para esta configuración. La salida de audio está preparada como AAC; el video usa remux siempre que sea posible, luego VideoToolbox H.264, MPEG-4 o salida de compatibilidad ProRes. Esta es una ruta de visualización, no una interfaz de usuario de exportación o transcodificación.

## Intérprete vectorial PostScript

La vista previa de EPS, PostScript e Illustrator heredado también utiliza el paquete Ghostscript 10.08.0 como un subproceso local restringido e independiente. Consulte [README-Ghostscript.md](README-Ghostscript.md) para obtener su licencia AGPL-3.0-or-later, el archivo fuente correspondiente completo, las sumas de verificación y la compilación universal reproducible. La compilación de la aplicación normal no necesita la instalación de Ghostscript en el sistema.
