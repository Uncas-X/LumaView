# LumaView — Español

<!-- language-navigation:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · **Español** · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- language-navigation:end -->

Guía rápida de **LumaView 1.7.2 (compilación 14)**. Manual completo en [inglés](README.en.md) o [chino](../../README.md).

LumaView es un visor nativo de macOS para imágenes, vídeo, audio y documentos multipágina. Se inspira en Picasa Photo Viewer, con nombre propio, icono original y sin afiliación con Google. Está pensado para visualizar archivos, no para editar ni administrar una fototeca.

## Descarga e instalación

Descarga [LumaView para macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip) o consulta [todas las versiones](https://github.com/Uncas-X/LumaView/releases). Requiere **macOS 13 o posterior** y ofrece una aplicación universal para Intel y Apple Silicon.

Descomprime el archivo y arrastra `LumaView.app` a Aplicaciones. La aplicación utiliza una firma local ad hoc y no está notarizada por Apple. Si macOS impide abrirla, comprueba su procedencia y sigue las indicaciones de Privacidad y seguridad para autorizarla.

## Primeros pasos

Arrastra un archivo o una carpeta a la ventana, o pulsa `Cmd+O`. Al abrir un archivo puedes recorrer los archivos multimedia vecinos de la misma carpeta. Solo se examina el nivel actual de la carpeta, sin incluir subcarpetas.

- Tira de miniaturas, zoom, desplazamiento, rotación, pantalla completa, transiciones suaves y fondo translúcido con efecto de cristal esmerilado.
- Las zonas transparentes de las imágenes rasterizadas PNG, GIF, PSD y PSB se mantienen transparentes y las sombras siguen el contenido. Los documentos muestran páginas sobre papel blanco. PSD/PSB utilizan la imagen compuesta de compatibilidad guardada, sin editar capas.
- El vídeo y el audio usan primero la reproducción nativa; FFmpeg incluido ofrece una alternativa de compatibilidad. El audio muestra la portada integrada o, si no existe, una forma de onda.
- Navegación por páginas de PDF, AI compatibles con PDF y TIFF multipágina. Representación vectorial de SVG, EPS/PS compatibles y AI antiguos. EPS/PS se procesan con Ghostscript incluido; las imágenes de mapa de bits incrustadas conservan el límite de su resolución original.
- El clic derecho permite abrir con otra aplicación, mostrar en Finder y copiar una imagen, el fotograma actual, una página PDF o una imagen incrustada en el PDF cuando sea compatible.
- Los controles de reproducción/pausa y parada multimedia son independientes de la presentación de diapositivas. Puedes asociar formatos con LumaView y elegir entre 16 idiomas. De forma predeterminada se utiliza el idioma del sistema.

## Atajos

| Tecla | Acción |
|---|---|
| `Cmd+O` | Abrir un archivo o una carpeta |
| `←` / `→` | Archivo o página anterior/siguiente según el foco |
| `↑` / `↓` | En documentos multipágina, enfocar páginas/archivos |
| Rueda, gesto de pellizco, `+` / `-` | Acercar/alejar |
| `0`; `1` | Ajustar a la ventana; alternar 100 %/ajuste |
| `Cmd+R`; `F` | Girar; pantalla completa |
| `P`; `S` | Reproducir/pausar el contenido multimedia; detener |
| `Cmd+4` | Controlar la presentación de diapositivas |
| `Cmd+C` | Copiar la imagen, el fotograma actual o la página |

**Espacio cambia el fondo**, no controla la reproducción.

## Compilar

Instala Xcode o las herramientas de línea de comandos de Swift. Desde la raíz del repositorio, ejecuta:

```bash
./build.sh
open ../LumaView.app
```

`./build.sh --host` compila únicamente para la arquitectura del Mac actual. Los archivos intermedios se guardan en `.build/`. `LUMAVIEW_WORK_ROOT` cambia ese directorio y `LUMAVIEW_APP_PATH` la ruta de salida de la aplicación. Las rutas parten de la raíz del repositorio, no del directorio de esta guía. Se incluyen las herramientas multimedia necesarias y sus archivos de código fuente y licencias.

## Limitaciones y privacidad

LumaView lee archivos locales, sin subirlos a la nube ni modificar los originales. No incluye editor, edición de capas, base de datos de fototeca ni sincronización en la nube. Las imágenes grandes pueden usar una vista previa reducida; ampliarla no recupera los detalles omitidos. Algunas conversiones deben terminar de procesar el archivo completo antes de reproducirlo y requieren tiempo y caché local. No se garantiza todo códec: los archivos con DRM, dañados o incompatibles pueden no abrirse.

Consulta los [formatos compatibles, en chino](../../FORMATS.md), los [avisos de terceros](../../ThirdParty/README.md) y los [avisos de Ghostscript](../../ThirdParty/README-Ghostscript.md).
