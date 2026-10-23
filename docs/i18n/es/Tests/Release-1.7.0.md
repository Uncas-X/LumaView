> Los nombres de archivos de muestras personales en los registros de validación históricos se han anonimizado. Los datos y resultados de las pruebas no cambian.

<!-- doc-navigation:start -->
[Documentación](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · **Español** · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# Registro de validación de LumaView 1.7.0

Fecha: 2026-10-22 (Asia/Shanghai). Entorno de prueba: macOS 15.7.9, x86_64. La aplicación está dirigida a macOS 13+ y los cuatro ejecutables son binarios universales de Intel/Apple Silicon.

## Cambios y resultados probados en esta ronda

- Ghostscript 10.08.0 integrado convierte en segundo plano todo el contenido de los archivos EPS, PostScript y AI basados en PostScript antiguo que se abren directamente. El PDF conserva trazados vectoriales, texto e imágenes incrustadas y se entrega al lienzo existente. Los usuarios no necesitan un intérprete independiente ni conversión manual; el zoom, la panorámica, la rotación y la navegación de varias páginas siguen las interacciones actuales. El respaldo TIFF incorporado todavía se utiliza si la conversión de vectores falla y el archivo proporciona una vista previa; el respaldo de ráster no está etiquetado como vector.
- El archivo adjunto de muestra `sample-vector.eps` se probó utilizando su contenido PostScript completo. Al escanear el PDF generado se encontraron **147,521 operaciones relacionadas con la ruta/gradiente, 59 operaciones de texto y 160 llamadas XObject**. Los XObjects aquí se cuentan como PDF `Do` operaciones y pueden incluir imágenes o XObjects Form; el número no es un recuento de imágenes distintas. Las pruebas confirmaron que se conservaron los contenidos reales del vector. Las comparaciones SHA-256 de EPS y `sample-vector.svg` antes y después de las pruebas mostraron originales sin cambios.
- PostScript utiliza un proceso cancelable independiente, Ghostscript SAFER, y un entorno limitado de procesos del sistema. La entrada se copia en un directorio temporal privado; el intérprete no puede leer otros archivos de usuario, escribir en archivos externos arbitrarios ni utilizar canalizaciones externas. Se pasaron las comprobaciones de tiempo de espera, cancelación, reutilización por parte de múltiples consumidores, entrada corrupta y invalidación de caché. Los resultados completos se publican de forma atómica, por lo que los PDF parciales no ocupan miniaturas. Las pruebas con visores reales cubrieron EPS con un 3200% de zoom vectorial, enfoque arriba/abajo y navegación de página izquierda/derecha en PS de varias páginas, y el cambio a PNG durante la conversión sin que un resultado tardío reemplace la vista actual.
- `.psb` se agregó al grupo de Photoshop junto con `.psd` para descubrimiento, vista principal, miniaturas y configuración predeterminada de la aplicación. Se lee un compuesto de compatibilidad guardado y se conservan las dimensiones originales del lienzo; Los archivos grandes obtienen vistas previas limitadas según las necesidades de visualización. La validación cubrió **112 combinaciones de codificación, 128 archivos estructurales con capas y marcas de transparencia, 1 PSB grande y 13 archivos de prueba dañados**. La detección de transparencia compuesta utiliza el recuento de capas y los marcadores Lr16/Lr32, Mtrn/Mt16/Mt32; Los canales Alpha adicionales ordinarios no se confunden con la transparencia compuesta. Las pruebas cubrieron valores de píxeles transparentes, eliminación del respaldo blanco, coherencia de codificación, cancelación en filas largas y regresiones de integración principal/miniatura.
- El cuadro de diálogo de apertura predeterminado lee las asociaciones reales del sistema cuando se abre, cuando la aplicación se reactiva y después de completar la configuración por lotes. Las propias asociaciones persisten durante los reinicios; Los borradores no aplicados no se muestran como exitosos. Un formato marcado tiene todos los tipos asignados a esta aplicación; un guión indica coincidencias parciales u otra copia con el mismo ID de paquete, como se explica en la información sobre herramientas. Borrar sólo cambia el borrador; no revoca los valores predeterminados del sistema.
- Seleccionar todos los formatos en la parte superior selecciona imágenes, vectores/documentos, videos y audio a la vez, incluidos formatos fuera de los resultados de búsqueda. Aún se debe hacer clic en el botón Establecer para escribir asociaciones. La detección, el éxito parcial, la lectura de errores, la reconstrucción del controlador, las diferencias entre el estado borrador y real y la selección total se probaron con un backend simulado en memoria. Las pruebas no cambiaron las aplicaciones predeterminadas del sistema del usuario.
- Las nuevas configuraciones, PostScript y cadenas de Photoshop de esta ronda cubren los 16 idiomas. Los marcadores de posición de formato y texto principal pasaron la validación.

## Validación en esta ronda

Sólo se cuentan las comprobaciones enumeradas a continuación con resúmenes completos exitosos en los registros de esta ronda; Se excluyen los módulos históricos que no se volvieron a ejecutar.

| Comprobación | Aprobado |
| --- | --- |
| Conversión, cancelación, aislamiento y EPS reales de vectores PostScript | 24 / 24 |
| SVG / Compatibilidad EPS y verificación del archivo adjunto original | 64 / 64 |
| PSD / PSB canales compuestos, transparentes, imágenes grandes y datos dañados | 712 / 712 |
| Configuración predeterminada por lotes y lectura posterior del sistema real (simulacro) | 101 / 101 |
| Cuadro de diálogo de formato predeterminado, estado de reapertura y selección de todos los formatos (simulado) | 34 / 34 |
| 16 idiomas y marcadores de posición | 174 / 174 |
| Declaraciones de formatos de la aplicación publicada | 15 / 15 |
| Biblioteca de imágenes y decodificación del sistema. | 78 / 78 |
| Geometría del lienzo, animaciones y mouse. | 66 / 66 |
| Análisis de documentos y dibujo de página completa. | 56 / 56 |
| Enfoque del documento, zoom y paginación EPS/PS, cancelación al cambiar de archivo | 75 / 75 |
| Clic en ventana real y ciclo de vida | 65 / 65 |
| 443: miniaturas de archivos, caché y devoluciones de llamadas obsoletas | 37 / 37 |
| Cancelación de solicitudes en miniatura y aislamiento del consumidor | 13 / 13 |
| Menú contextual de la aplicación de lanzamiento instalada y portapapeles privado | 28 / 28 |
| **Totales** | **1542 / 1542** |

La aplicación de versión optimizada instalada se sometió a 28 verificaciones adicionales del menú contextual a través de menús reales y distribución target/action, utilizando un portapapeles con nombre separado. Verificaron la copia de imágenes, cuadros de video actuales, imágenes PDF y páginas completas, rotación y resultados obsoletos al cambiar/cerrar, sin tocar el portapapeles del sistema del usuario. Se aprobaron las comprobaciones de regresión existentes para clics del mouse, ciclo de vida de la ventana, enfoque de página, presentación de página completa, caché de miniaturas y cancelación.

## Directorio de versiones y verificación de aplicaciones instaladas

Versión **1.7.0, compilación 12**. Antes de escribir este informe, se compararon los ID de paquete, las versiones, las compilaciones, las listas completas de archivos y los hashes SHA-256 de `outputs/LumaView.app` y `/Applications/LumaView.app` y se encontraron idénticos. Los cuatro ejecutables pasaron la inspección de arquitectura dual, ambas aplicaciones pasaron `codesign --verify --deep --strict`, Ghostscript incluido informó la versión 10.08.0, los recursos de localización/versión coincidieron con el árbol de fuentes y el SHA-256 del archivo fuente de Ghostscript coincidió con la lista de suma de verificación incluida. El intérprete se vuelve a firmar durante una compilación; No es necesario que su binario firmado coincida byte por byte con la copia del directorio fuente que aún no se ha vuelto a firmar.

| Ejecutable | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

Este informe no reemplaza las comprobaciones posteriores de integridad ZIP ni reclama la notarización de Apple. La firma es local y ad hoc. Se completaron la compilación cruzada y las comprobaciones de arquitectura para Apple Silicon, pero esta ronda no se ejecutó en el hardware de Apple Silicon. El archivo fuente de Ghostscript, la licencia y las instrucciones de reconstrucción acompañan a la distribución fuente.

## Alcance y límites

Los mapas de bits ya integrados en EPS/PS conservan sus límites de resolución de origen; Es posible que las fuentes externas o recursos de archivos y PostScript inusuales o dañados no se conviertan por completo. Las vistas previas de PSD / PSB dependen de los compuestos de compatibilidad guardados y no editan las capas de Photoshop ni reconstruyen los compuestos faltantes; cuando está ausente, la aplicación recomienda habilitar Maximizar compatibilidad y guardar nuevamente. Las dimensiones del lienzo original pueden exceder el tamaño de vista previa mostrado; no se presenta una vista previa limitada como si cada píxel de origen estuviera decodificado. Consulte [FORMATS.md](../FORMATS.md) para conocer otros límites de formato.

## Fuentes de registro para esta ronda

Los siguientes archivos se copiaron a `Tests/`. Los informes históricos que no se repiten permanecen pero se excluyen del total de esta ronda:

- `PostScript-test-results.txt` ← `work/postscript-17/postscript-test-results.txt`
- `vector-compatibility-test-results.txt` ← `work/vector-compatibility-1.7.0/vector-compatibility-test-results.txt`
- `Photoshop-test-results.txt` ← `work/psb-support/results.txt`
- `Default-application-test-results.txt` ← `work/default-application-1.7-results.txt`
- `Default-preferences-test-results.txt` ← `work/default-preferences-tests/default-preferences-test-results.txt`
- `Localization-test-results.txt` ← `work/localization-1.7-results.txt`
- `Media-declaration-test-results.txt` ← `work/media-declaration-1.7.0.txt`
- `Core-test-results.txt` ← `work/core-1.7.0-run.log`
- `Canvas-test-results.txt` ← `work/canvas-1.7.0-run.log`
- `Document-core-test-results.txt` ← `work/document-1.7.0/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-1.7.0/document-test-results.txt`
- `UI-test-results.txt` ← `work/ui-1.7.0/ui-test-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.0/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.0-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.0/context-menu-test-results.txt`
