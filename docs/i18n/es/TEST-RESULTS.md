# Registro de validación de LumaView 1.7.2

<!-- doc-navigation:start -->
[Documentación](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · [繁體中文](../zh-Hant/TEST-RESULTS.md) · [English](../en/TEST-RESULTS.md) · [日本語](../ja/TEST-RESULTS.md) · [한국어](../ko/TEST-RESULTS.md) · [Français](../fr/TEST-RESULTS.md) · [Deutsch](../de/TEST-RESULTS.md) · **Español** · [Italiano](../it/TEST-RESULTS.md) · [Português (Brasil)](../pt-BR/TEST-RESULTS.md) · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · [Türkçe](../tr/TEST-RESULTS.md) · [Nederlands](../nl/TEST-RESULTS.md) · [Polski](../pl/TEST-RESULTS.md)
<!-- doc-navigation:end -->


Versión 1.7.2, compilación 14. Probado en 2026-10-22 con macOS 15.7.9/Intel. La aplicación y las herramientas incluidas se verificaron como binarios universal arm64 + x86_64 con firmas locales. Esta ronda no se ejecutó en hardware Apple Silicon.

## Corrección en esta versión

Las imágenes rasterizadas ahora muestran regiones transparentes de manera consistente: PNG / GIF / PSD / PSB y otras ya no dibujan un tablero de ajedrez blanco grisáceo o un borde de lienzo rectangular. Las sombras de visualización se derivan del alfa compuesto real de la imagen actual en lugar del lienzo completo de la imagen. Por lo tanto, los márgenes transparentes no tienen sombra rectangular adicional; Los agujeros, las máscaras suaves separadas y las regiones translúcidas contribuyen al contorno real.

La implementación anterior solo miraba CGImage.alphaInfo al agregar el tablero de ajedrez, faltaban archivos PSB con una máscara Quartz separada. También forzó un shadowPath rectangular en cada zoom, y el borde mismo produjo una sombra rectangular. Esas fuentes rectangulares se han eliminado para imágenes rasterizadas; Las sombras de las capas ahora siguen el alfa compuesto automáticamente. El dibujo exportado también proyecta una sombra desde la propia imagen sin rellenar primero un rectángulo. Los cambios de fotograma GIF / APNG reemplazan la textura actual y actualizan la sombra sin escanear los píxeles transparentes de cada fotograma ni crear una imagen RGBA adicional completa.

Las páginas de documentos conservan su papel blanco y las superficies de vídeo conservan su rectángulo existente. La copia de imágenes sigue utilizando los píxeles de la imagen original sin el fondo del visor, el tablero de ajedrez ni la sombra de visualización. El decodificador PSB, el programador de miniaturas y la ruta de vista previa rápida de la versión anterior no se modificaron.

## Validación en esta ronda

| Comprobación | Aprobado |
| --- | --- |
| Transparencia, sombras de contorno y cambios de fotograma. | 133 / 133 |
| Geometría del lienzo, animación y mouse. | 66 / 66 |
| Análisis de documentos y representación de página completa. | 56 / 56 |
| Aplicación de lanzamiento instalada: documentos, zoom EPS/PS, navegación de páginas y enfoque | 75 / 75 |
| Aplicación de lanzamiento instalada: menús contextuales y copia | 28 / 28 |
| Total | 358 / 358 |

Las pruebas de transparencia utilizaron un gráfico con un agujero, protuberancias irregulares y grandes márgenes transparentes, codificados por separado como RGBA, una máscara de Quartz separada y archivos PNG, GIF, PSD y PSB reales que fueron codificados y decodificados. Se verificaron los píxeles compuestos y exportados de CALayer de `draw` para confirmar que los bordes transparentes no tienen un fondo ni una sombra rectangular, y que los contornos internos y externos sí proyectan sombras. También se cubrieron imágenes totalmente transparentes, cambios de fotograma, rotación y zoom, cambio rápido y un fondo de visor translúcido. Los PNG exportados fueron inspeccionados visualmente.

Para estas seis entradas, el PNG SHA-256 de la exportación CALayer y el PNG `draw` de exportación eran idénticos: `578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`. Los medios de prueba se generaron mediante código; no se agregaron fotos personales a la fuente.

Una sonda de renderizado de software limitada también comparó las sombras nuevas y antiguas en ajuste a la ventana, 100% y 3200% en un mapa de bits de 32 MP con lienzos lógicos de 16,384 × 7,812 y 300,000 × 128. El RSS máximo del proceso de prueba fue de aproximadamente 428 MiB; Los tiempos de renderizado antiguos y nuevos eran similares. Eso mide las instantáneas del software a través de `CALayer.render(in:)`, no las velocidades de fotogramas de la GPU. Como resultado, no se agregó ninguna capa de caché ráster.

Las listas completas de archivos y los hashes de la versión instalada y de `outputs/LumaView.app` coinciden; ambos pasaron `codesign --verify --deep --strict`. Se realizó una copia de seguridad del ZIP anterior antes de la instalación. Las asociaciones de apertura predeterminada se leyeron antes y después. Siguieron comprobaciones de versión y CRC del ZIP entregado. Los informes históricos permanecen en `Tests/Release-1.7.0.md` y `Tests/Release-1.7.1.md`; Las comprobaciones que no se vuelvan a ejecutar de esas liberaciones no entran en el recuento de esta ronda.

Ejecutable principal SHA-256: `b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`.

## Fuentes de registro

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
