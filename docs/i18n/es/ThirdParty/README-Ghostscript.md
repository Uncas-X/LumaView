# Herramienta de conversión de documentos Ghostscript

<!-- doc-navigation:start -->
[Documentación](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · **Español** · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView invoca Ghostscript **10.08.0**, lanzado por Artifex el 2026-09-08, como un ejecutable local separado para convertir EPS y PostScript en un PDF temporal. La salida PDF conserva los trazados vectoriales, el texto y los degradados admitidos. Las imágenes ya incrustadas como píxeles rasterizados siguen siendo imágenes rasterizadas. Ghostscript no está vinculado a la aplicación Swift y no se requiere instalación de Homebrew para ejecutar este ejecutable incluido.

## Licencia y fuente correspondiente

Ghostscript se distribuye bajo la **Licencia pública general GNU Affero versión 3 o posterior**, como se especifica en el archivo `LICENSE` original de esta versión. La licencia completa, el aviso de copyright de Ghostscript, la excepción de incrustación de fuentes, los avisos de Adobe CMap y los avisos de dependencia incluidos se copian sin cambios en `Resources/ThirdPartyNotices/Ghostscript/`. Artifex también ofrece una licencia comercial independiente; Este paquete no incluye una licencia comercial. Consulte la [página oficial de licencias](https://www.ghostscript.com/licensing/index.html).

La versión fuente correspondiente exacta y sin modificaciones, incluidos los códigos fuente de las dependencias y las fuentes tipográficas incluidas, se incluye en `ThirdParty/sources/ghostscript-10.08.0.tar.xz`. Su SHA-256 está registrado en `ThirdParty/sources/SHA256SUMS-Ghostscript`:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

Procedencia de la fuente: [página de lanzamiento oficial](https://www.ghostscript.com/releases/index.html) y [activos de lanzamiento 10.08.0 de Artifex](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). La suma de verificación coincide con la suma de verificación publicada para el activo `.tar.xz`. El paquete fuente y este script de compilación acompañan a la distribución fuente de LumaView. LumaView no impone ninguna restricción adicional sobre la modificación o reemplazo de esta herramienta independiente, ni sobre la ingeniería inversa necesaria para depurar dichas modificaciones. Estos avisos describen el componente de terceros incluido; no pretenden volver a otorgar la licencia de la fuente de la aplicación.

## Volver a compilar

Requisitos: macOS, herramientas de línea de comandos de Xcode, el archivo fuente incluido y herramientas de compilación estándar de macOS. No se utilizan bibliotecas Homebrew. Desde el directorio fuente de LumaView:

```sh
./tools/build-document-tools.sh
./build.sh
```

El script verifica el archivo fuente, crea segmentos Intel y Apple Silicon a partir de directorios fuente separados, elimina los símbolos locales y combina los segmentos en `Resources/DocumentTools/gs`. Ambos sectores están destinados a macOS 13.0 o posterior. No ejecuta `make install` ni escribe en un administrador de paquetes del sistema. `LUMAVIEW_DOCUMENT_BUILD` selecciona el directorio de compilación intermedio; `LUMAVIEW_DOCUMENT_JOBS` controla el paralelismo de make (valor predeterminado: 4). El argumento opcional `x86_64` o `arm64` construye solo una arquitectura. La compilación de la aplicación firma el ejecutable copiado junto con la aplicación.

El ejecutable incluye código de inicialización, fuentes empaquetadas, Adobe CMaps y perfiles ICC en su sistema de archivos interno `%rom%`. Las rutas de búsqueda externas predeterminadas están vacías. Sólo está habilitado el dispositivo de salida `pdfwrite`. La impresión/CUPS, X11, GTK, fontconfig, D-Bus, Tesseract/OCR, controladores dinámicos, IJS externo y herramientas de extracción de documentos están deshabilitados. Todas las bibliotecas de decodificadores/colores/fuentes incluidas se compilan a partir del archivo fuente correspondiente; El enlace dinámico está limitado a las bibliotecas del sistema Apple. Consulte la [documentación oficial de compilación](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html) para conocer el sistema de archivos ROM y los mecanismos de compilación cruzada.

LumaView ejecuta el intérprete con `-dSAFER`, un archivo de entrada y salida específico, un directorio de trabajo temporal privado, cancelación y tiempo de espera. El entorno del proceso no debe heredar las opciones de Ghostscript ni las rutas de biblioteca especificadas por el usuario. Ejemplo de archivos de prueba fiables generados:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

Las opciones de compilación completas están en `tools/build-document-tools.sh`; el archivo fuente no está parcheado. La ejecución nativa solo se puede probar para arquitecturas admitidas por el host de compilación. Las comprobaciones de lanzamiento inspeccionan ambos sectores Mach-O y ejecutan un EPS generado que contiene rutas y texto a través del segmento compatible con el host, lo que confirma que la salida PDF todavía contiene operadores de dibujo vectorial y texto.
