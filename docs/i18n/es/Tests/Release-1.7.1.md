> Los nombres de archivos de muestras personales en los registros de validación históricos se han anonimizado. Los datos y resultados de las pruebas no cambian.

<!-- doc-navigation:start -->
[Documentación](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · **Español** · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# Registro de validación de LumaView 1.7.1

Versión 1.7.1, compilación 13. 2026-10-22, MacOS 15.7.9 / Intel. La aplicación y las tres herramientas incluidas pasaron las comprobaciones de arquitectura y firma local arm64 + x86_64; Esta ronda no se ejecutó en hardware Apple Silicon.

## Problemas localizados y solucionados

Los tres archivos PSB del usuario eran archivos RLE de cuatro canales RGB de 8 bits con transparencia compuesta, aproximadamente 108–123 MiB cada uno. La mayor parte de cada archivo consta de datos de capas que se pueden omitir directamente; los lienzos principales contienen alrededor de 8.5–9.6 megapíxeles.

1. El antiguo decodificador fila por fila llamaba a FileHandle para cada marcador y valor de PackBits, producía muchas lecturas pequeñas y dejaba colas de imágenes principales y miniaturas ocupadas demasiado tiempo. Ahora lee fragmentos de hasta 64 KiB, preservando el estado literal/run y las comprobaciones de límites entre bloques. Los datos largos no-op siguen siendo cancelables. ZIP invierte la predicción solo para las filas muestreadas y al mismo tiempo valida todo el flujo comprimido.
2. Los tres archivos tienen una miniatura JPEG RGB válida en el recurso 1036. La tira de película ahora lo prefiere, verificando el formato, las dimensiones, la relación de aspecto y la longitud comprimida; la imagen principal siempre decodifica la composición real. Las vistas previas no válidas, los recursos BGR más antiguos o las vistas previas faltantes vuelven al compuesto.
3. El sistema ImageIO rechaza algunos compuestos pequeños PSD que llevan un RGB genérico ICC válido. Por lo tanto, la alternativa anterior devolvió miniaturas vacías. Ahora decodifica los píxeles por separado y luego adjunta el original verificado ICC si su modelo de color y el recuento de componentes coinciden, en lugar de descartar el perfil. El ICC de los archivos originales coincide con el estándar del sistema Generic RGB Profile. Los archivos de prueba de regresión se generaron a partir del perfil del sistema; Las fotos de los usuarios no se agregaron a la fuente.
4. La vista principal PSB reutiliza la información del encabezado analizada y evita un escaneo de capa ImageIO adicional en busca de metadatos. Se conservan las dimensiones originales, la transparencia y la calidad de la imagen principal.

## Pruebas sobre los tres archivos originales.

Estas son medidas locales en esta Mac, afectadas por la carga y el caché de archivos, no garantías de rendimiento para cada dispositivo. Tanto los decodificadores antiguos como los nuevos utilizaban una compilación optimizada.

| Archivo | Dimensiones originales | Antigua decodificación de la imagen principal | Nueva decodificación de la imagen principal | Nueva decodificación de miniaturas compuestas (sin vista previa integrada) |
| --- | --- | --- | --- | --- |
| Muestra A | 2582 × 3318 | Prueba cancelada después de más de 15 segundos | 0.68 segundos | 0.039 segundos |
| Muestra B | 2610 × 3307 | 14.35 segundos | 0.65 segundos | 0.028 segundos |
| Muestra C | 2843 × 3361 | Prueba cancelada después de más de 15 segundos | 0.70 segundos | 0.028 segundos |

La solicitud de tres miniaturas simultáneamente a través del ImageLoader real se completó en aproximadamente 0.06 segundos. Las imágenes principales completas tardaron aproximadamente 0.90 / 0.65 / 0.74 segundos en pasar por el cargador. La versión anterior reportaba las tres miniaturas compuestas como unsupported; la nueva versión tuvo éxito en los tres. Los valores SHA-256 de los originales coincidieron byte por byte antes y después de las pruebas; la aplicación no modificó los archivos originales.

## Comprobaciones superadas en esta ronda

| Comprobación | Resultado |
| --- | --- |
| PSD / PSB codificación y compuesto transparente | 712 / 712 |
| Rendimiento RLE, vistas previas integradas, ICC, límites de fragmentos, cancelación | 54 / 54 |
| Integración real ImageLoader para tres PSB originales | 21 / 21 |
| 443-archivo tira de película, caché, devoluciones de llamada invalidadas | 37 / 37 |
| Solicitudes y cancelación de miniaturas independientes | 13 / 13 |
| Biblioteca de imágenes y decodificación del sistema. | 78 / 78 |
| Menú contextual de la aplicación de versión optimizada instalada y copia | 28 / 28 |
| Total | 943 / 943 |

Las nuevas pruebas cubren literales densos de un byte, límites de 64 KiB, cancelación durante secuencias largas no-op, truncamiento y datos fuera de límites, contenidos correctos distintos para miniaturas incrustadas e imágenes principales, ICC, transparencia y pequeños factores de zoom no enteros. Las combinaciones de codificación 112 existentes y los 128 archivos estructurales con marcas de transparencia de capas continúan pasando. Las comprobaciones de tiras de película cubren el cambio rápido, la cancelación fuera de pantalla y la prevención de devoluciones de llamadas antiguas que contaminen la lista actual.

Las listas completas de archivos y los hashes de la aplicación instalada y `outputs/LumaView.app` coincidieron, y ambos pasaron `codesign --verify --deep --strict`. Se realizó una copia de seguridad del antiguo ZIP antes de la instalación; las asociaciones de apertura predeterminada no fueron modificadas. El ZIP entregado se comprobó por separado en cuanto a CRC y versión. El informe histórico completo 1.7.0 permanece en `Tests/Release-1.7.0.md`; sus controles que no se volvieron a ejecutar no se incluyen en esta ronda.

Ejecutable principal SHA-256: `cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`.

## Registros

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
