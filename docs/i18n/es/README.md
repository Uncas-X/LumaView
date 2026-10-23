# LumaView 1.7.2

<!-- doc-navigation:start -->
[Documentación](INDEX.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [English](../en/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md) · [Français](../fr/README.md) · [Deutsch](../de/README.md) · **Español** · [Italiano](../it/README.md) · [Português (Brasil)](../pt-BR/README.md) · [Русский](../ru/README.md) · [العربية](../ar/README.md) · [हिन्दी](../hi/README.md) · [Türkçe](../tr/README.md) · [Nederlands](../nl/README.md) · [Polski](../pl/README.md)
<!-- doc-navigation:end -->


**[Descargar la aplicación macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)** · [Versiones y notas de la versión](https://github.com/Uncas-X/LumaView/releases)

Requiere macOS 13+. El mismo paquete es compatible con Intel y Apple Silicon. Extraiga el ZIP descargado y arrastre `LumaView.app` a Aplicaciones para instalarlo.

Un visor multimedia nativo de macOS inspirado en los hábitos de visualización rápida de Picasa Photo Viewer, con navegación en la misma carpeta, zoom, desplazamiento, rotación, tira de película, pantalla completa y presentaciones de diapositivas. La versión 1.5 agregó carátulas de audio y formas de onda reales, navegación de documentos de varias páginas, un lienzo vectorial redibujado con el zoom actual y configuraciones de idioma que siguen el sistema de forma predeterminada. Utiliza un nombre independiente y un icono original y no pretende reproducir todas las funciones o interacciones de las versiones históricas de Picasa.

La versión 1.7.2 unifica la transparencia de la imagen: las áreas transparentes de imágenes rasterizadas como PNG, GIF y PSD/PSB revelan el fondo de visualización actual. Las sombras siguen el contorno y la opacidad de la imagen real; no hay ningún tablero de ajedrez ni sombra rectangular alrededor de todo el lienzo transparente. Documentos como PDF conservan un fondo de papel blanco.

Las mejoras de vista previa PSD / PSB de 1.7.1 permanecen: la tira de película prefiere un JPEG incrustado válido, mientras que la vista principal decodifica el compuesto de compatibilidad real. RLE utiliza lecturas fragmentadas y se ha solucionado un problema que impedía la generación de miniaturas para algunos compuestos pequeños con perfiles ICC.

## Uso e instalación

Requiere macOS 13 o posterior, con soporte para Intel y Apple Silicon.

1. Descargue `LumaView-macOS.zip` de [Versiones](https://github.com/Uncas-X/LumaView/releases), extráigalo, arrastre `LumaView.app` a Aplicaciones y ábralo.
2. Suelte una imagen, video, archivo de audio o carpeta en la aplicación, o presione `⌘O` para seleccionar archivos. Al abrir un archivo, se enumeran los medios en la misma carpeta; Al seleccionar varios archivos se explora esa selección. Los análisis de carpetas cubren únicamente el nivel actual y no recurren a subcarpetas.
3. En Finder, también puede hacer clic derecho en un archivo y elegir Abrir con → LumaView.

Las compilaciones locales utilizan una firma ad hoc y no han sido notarizadas por Apple. Si Gatekeeper bloquea una copia descargada en otra Mac, verifique su fuente y use la opción Privacidad y seguridad del sistema para permitir que se abra.

## Configuración de la aplicación predeterminada

Elija **LumaView → Aplicación predeterminada…**, presione `⌘,` o abra la configuración desde el menú Más. Los formatos se agrupan en imágenes, vectores/documentos, vídeo y audio. Busque y seleccione formatos, luego haga clic en Establecer como predeterminado para formatos seleccionados. Cada vez que se abre el cuadro de diálogo, la aplicación vuelve a activarse o finalizan los cambios, lee las asociaciones reales del sistema: una marca de verificación significa que todos los tipos del grupo se abren con esta copia de LumaView; un guión significa que solo algunos tipos lo hacen, o que aún apuntan a otra copia. Las asociaciones del sistema persisten tras los reinicios; Las selecciones no aplicadas no se presentan como configuraciones aplicadas correctamente. Seleccionar todos los formatos en la parte superior cubre todas las imágenes, documentos vectoriales, videos y audio, independientemente del filtro de búsqueda; Las categorías individuales aún se pueden seleccionar por separado. Borrar solo borra la selección actual y no elimina los valores predeterminados existentes del sistema.

La configuración muestra el progreso y lee cada resultado del sistema. Cancelar detiene los cambios posteriores; los cambios completados permanecen. La lista de formatos representa asociaciones de archivos seleccionables, no una afirmación de que se haya probado cada codificación o archivo interno. Consulte [Formatos y vistas previas](FORMATS.md) para obtener más detalles.

## Visualización y reproducción

Al abrir el primer archivo, se expande la ventana al área disponible de la pantalla actual. Presione `F` para pantalla completa. Haga clic en la tira de película inferior para cambiar archivos. Los controles se ocultan después de que el puntero permanece en el área de visualización por un tiempo y reaparecen cuando se mueve.

La versión 1.5.2 corrigió miniaturas en blanco o que parpadeaban repetidamente durante la navegación prolongada de carpetas grandes: las miniaturas visibles se conservan de forma independiente y la carga fuera de la pantalla se cancela rápidamente. Los resultados de la carpeta anterior no pueden ingresar a la nueva lista. Los archivos no decodificables muestran un marcador de posición estable y se pueden volver a intentar cuando se revisa su rango.

Las imágenes y los vídeos admiten zoom, panorámica, rotación y pantalla completa. Los cambios de ventana, los cambios de imagen, el zoom y la rotación utilizan transiciones breves y suaves que más entradas pueden interrumpir. Habilitar la configuración Reducir movimiento del sistema deshabilita estas transiciones personalizadas mientras las imágenes animadas continúan reproduciéndose. El fondo predeterminado es vidrio esmerilado translúcido; presione la barra espaciadora para alternar entre fondos esmerilados, oscuros y claros.

La transparencia rasterizada sigue una regla: mostrar el fondo actual y proyectar sombras solo desde píxeles que contienen contenido visible, conservando la opacidad de los bordes translúcidos. Las sombras GIF / APNG cambian con cada fotograma. Copiar una imagen conserva sus píxeles transparentes originales y excluye el fondo y la sombra del visor.

Los controles de reproducción, parada, posición y volumen de audio/vídeo aparecen encima de la tira de película. Los medios se reproducen automáticamente cuando se abren y permanecen al final cuando terminan; presione `P` para reproducir o `S` para detener y regresar al principio. El botón de presentación de diapositivas a continuación es independiente de la reproducción multimedia: después de que `⌘4` inicia la reproducción continua, las imágenes avanzan en el intervalo seleccionado, mientras que el audio/video finaliza antes de avanzar. La reproducción de un archivo de audio/vídeo individual no pasa automáticamente al siguiente elemento.

Primero se intenta la reproducción nativa de macOS. Si el sistema no puede reproducir el archivo directamente, los FFmpeg universales 9.0.2 y dav1d 1.5.3 incluidos preparan un archivo compatible localmente, intentando primero un cambio de contenedor cuando corresponda y luego transcodificando. No se necesita ningún reproductor, Homebrew o paquete de códecs por separado, y no se utiliza acceso a la red. La reproducción de compatibilidad espera a que se prepare todo el archivo y muestra el progreso; cambiar archivos o cerrar la ventana cancela la preparación. La preparación de un vídeo largo por primera vez puede llevar mucho tiempo y espacio adicional en el disco.

Presione `C` o use el menú Más para configurar el bucle, el comportamiento de la rueda, el cierre al hacer clic en el fondo, la tira de película, la clasificación y los intervalos de presentación de diapositivas (2, 3, 5, 8 o 10 segundos). La rueda hace zoom de forma predeterminada; mantenga presionado `Ctrl` para navegar temporalmente entre archivos. Si la rueda está configurada para explorar, `Ctrl` hace zoom temporalmente. Al hacer clic en el fondo fuera de la imagen, se cierra el visor de forma predeterminada. Estas preferencias se almacenan localmente.

## Menú contextual y copia

Haga clic derecho (o presione Control y haga clic) en la vista principal para elegir Abrir con → Aplicación / Otra aplicación… o Mostrar en Finder. Abrir con afecta únicamente a esta apertura y no cambia las asociaciones predeterminadas. Ambas opciones siguen estando disponibles para archivos no decodificables.

- Imágenes: elija Copiar imagen. Esto conserva la rotación de la vista y los píxeles transparentes y copia toda la imagen actualmente decodificada, sin capturar barras de herramientas o solo la región ampliada de la pantalla.
- Vídeo: elija Copiar fotograma actual. Esto copia el cuadro correspondiente al momento en que se abrió el menú contextual, preservando la orientación del video y la rotación de la vista sin cambiar la posición o el estado de la reproducción.
- PDF / AI compatible con PDF: haga clic derecho en un mapa de bits en una página para copiar esta imagen, o elija Copiar página actual. La detección de impactos sigue la posición real después de hacer zoom, desplazarse y rotar. El texto ordinario y las regiones vectoriales no se tratan como imágenes; máscaras complejas o espacios de color utilizan el resultado visible de la región de la imagen, que puede incluir texto superpuesto. Una página escaneada como una imagen se copia como el escaneo completo.
- `⌘C` copia la imagen actual, el fotograma de vídeo o la página del documento; El audio no proporciona copia de imágenes. El portapapeles recibe PNG y TIFF. Cambiar archivos/páginas o cerrar el visor evita que los resultados de la copia obsoletos sobrescriban el portapapeles.

Las copias de páginas de documentos e imágenes incrustadas son mapas de bits limitados a un lado más largo de 8192 píxeles y aproximadamente 32 megapíxeles; Las instrucciones vectoriales PDF/SVG no se colocan en el portapapeles. Si una imagen grande muestra una vista previa limitada, esa vista previa se copia. El análisis de imágenes PDF tiene límites de complejidad: es posible que las estructuras especiales, como imágenes dentro de rellenos de patrón, no se puedan seleccionar individualmente, pero la página actual aún se puede copiar.

Los encabezados estándar SVG 1.0/1.1 se analizan sin conexión sin cargar DTD externos. La versión 1.7 incluye Ghostscript 10.08.0 para convertir EPS/PostScript y AI basado en PostScript antiguo a PDF conservando rutas, texto e imágenes incrustadas. La vista principal vuelve a dibujar los vectores con el zoom actual; PS de varias páginas utiliza la navegación de páginas existente. No se requiere instalación adicional. Si la conversión falla pero el EPS tiene un TIFF integrado válido, puede recurrir a esa vista previa, claramente etiquetada como TIFF. Las imágenes rasterizadas dentro del original no se convierten en vectores.

## Audio, documentos e idiomas.

El audio utiliza carátulas incrustadas en la vista principal cuando está disponible. De lo contrario, las muestras reales se analizan de forma asincrónica para mostrar una forma de onda para la pista completa. Aparece un marcador de posición durante el análisis y no es necesario esperar la reproducción. Las miniaturas de audio y vídeo utilizan la misma insignia `▶ duración` en la parte inferior derecha, con fuente, fondo y posición coincidentes; antes de que la duración esté disponible, muestran `▶ –:––`. Las carátulas provienen de metadatos de archivos incrustados, sin buscar en la red ni en archivos vecinos.

PDF, AI compatible con PDF y TIFF multipágina permiten navegar por sus páginas. Miniaturas de páginas más pequeñas, un control deslizante de progreso de página y números de páginas actuales/totales aparecen encima de la tira de película del archivo. Presione `↑` para enfocar páginas y `↓` para enfocar archivos. La miniatura seleccionada en la fila enfocada tiene un borde naranja; la otra fila conserva su selección con un borde gris. No se muestran etiquetas de páginas/archivos adicionales. `←` / `→`, `J` / `K` y `Home` / `End` actúan sobre el foco actual. Al hacer clic en una fila también se enfoca. La navegación de páginas se detiene en la primera y la última página sin pasar inesperadamente a otro archivo. Los botones inferiores de archivo anterior/siguiente siempre cambian de archivo. La navegación de páginas permanece disponible cuando la tira de película del archivo está oculta.

PDF, SVG y AI compatibles con PDF, dibujan la región visible a partir de instrucciones vectoriales originales con el zoom actual, en lugar de ampliar una vista previa fija. Las regiones de documentos transparentes utilizan papel blanco normal, sin tablero de ajedrez. Al cambiar de página, se prepara primero la nueva página completa y después se muestra con una transición suave de entrada; El dibujo de detalle vectorial de fondo no deja mosaicos en blanco que aparecen uno a la vez. Las fotografías incrustadas y otros mapas de bits siguen estando limitados por su resolución original.

Elija **LumaView → Idioma…**, también disponible en el menú Más. El valor predeterminado sigue el sistema, con soporte para chino simplificado, chino tradicional, inglés, japonés, coreano, francés, alemán, español, italiano, portugués, ruso, árabe, hindi, turco, holandés y polaco. Los menús de la aplicación, la información sobre herramientas, la paginación y la configuración se actualizan inmediatamente y el idioma seleccionado se guarda localmente. Los idiomas del sistema no admitidos vuelven al inglés; También pueden aparecer errores de decodificación poco comunes en inglés. Los nombres de archivos, las rutas y el texto dentro de los archivos permanecen sin cambios.

## Teclado y ratón

| Acción | Atajo/gesto |
| --- | --- |
| Elemento anterior/siguiente (enfoque actual) | `←` / `→`, o `J` / `K` |
| Enfocar páginas / archivos | `↑` / `↓` (documentos de varias páginas) |
| Primer/último elemento | `Home` / `End` |
| Abrir archivos o una carpeta | `⌘O` |
| Configuración de la aplicación predeterminada | `⌘,` |
| Ampliar | Rueda, pellizco del panel táctil, `+` / `−`, `Page Up` / `Page Down` |
| Cambiar temporalmente el comportamiento de la rueda | Mantenga presionado `Ctrl` mientras se desplaza |
| 100% / ajustar a ventana | Haga clic en la imagen o `1` |
| Ajustar a la ventana | `0` |
| Panorámica de una imagen o vídeo ampliado | Arrastra la vista |
| Girar la vista en el sentido de las agujas del reloj | `⌘R` / `Ctrl+R`; agregue `Shift` para el sentido contrario a las agujas del reloj |
| Cambiar el fondo | Barra espaciadora |
| Entrar/salir de pantalla completa | `F` / `⌃⌘F` / `F11` (cuando no está reservado por el sistema) |
| Reproducir/pausar audio o vídeo | `P` |
| Detener los medios y volver al inicio. | `S` |
| Iniciar/detener presentación de diapositivas y reproducción continua | `⌘4` |
| Retroceder / avanzar 5 segundos en el medio | `Option + ←` / `Option + →` |
| Silenciar / restablecer sonido | `M` |
| Información del archivo | `I` / `⌘I` |
| Mostrar/ocultar tira de película | `T` / `⌘T` |
| Más opciones | `C` |
| Mostrar el archivo actual en Finder | `⌘Return` |
| Pausar la reproducción, cerrar información, salir de pantalla completa, cerrar la ventana | `Esc`, manejado en orden según el estado actual |
| Minimizar / cerrar / salir | `⌘M` / `⌘W` / `⌘Q` |

`P` controla sólo el audio/vídeo actual, no las presentaciones de diapositivas de imágenes. Ayuda → Teclado y mouse también proporciona una guía dentro de la aplicación.

## Cobertura y limitaciones

- Las imágenes utilizan el sistema de decodificación ImageIO. La compatibilidad real con JPEG, PNG, GIF, HEIC, TIFF, BMP, WebP, RAW y otros formatos depende de la versión del sistema y del contenido del archivo.
- Las imágenes muy grandes ya no se rechazan únicamente por exceder 150 megapíxeles. Para limitar la memoria, las vistas previas pueden reducirse mientras se conservan las dimensiones originales y los metadatos de orientación. El 100% de zoom todavía se calcula a partir de las dimensiones originales, pero no puede recuperar los detalles de píxeles omitidos en la decodificación de vista previa.
- La visualización vectorial admite SVG, PDF, AI compatible con PDF y EPS/PS/AI antiguo procesado por el intérprete incluido. Los archivos PDF / AI / PS multipágina permiten navegar entre páginas; SVG rechaza scripts y recursos externos. Los mapas de bits incrustados conservan sus límites de resolución originales; las fuentes tipográficas no incrustadas y no disponibles pueden sustituirse.
- PostScript se ejecuta en un proceso separado con SAFER y un entorno limitado del sistema, que permite únicamente los archivos temporales de entrada y salida preparados y deniega el acceso a la red. Los cambios rápidos de archivos pueden cancelarlo; Las miniaturas y la vista principal comparten resultados almacenados en caché completos. Cada interpretación está limitada a 90 segundos y 1 GB de salida, con un objetivo de limpieza de caché de 2 GB.
- Photoshop PSD / PSB muestra la composición guardada en el archivo, sin edición de capas. Los lienzos muy grandes utilizan vistas previas presupuestadas en memoria y conservan las dimensiones originales; consulte FORMATS.md para conocer los modos de color, profundidades de bits y compresión admitidos.
- La decodificación alternativa incluida amplía la cobertura de audio/video, pero DRM, archivos dañados y codificaciones propietarias sin un decodificador disponible aún pueden fallar. Una extensión no garantiza que la codificación interna pueda decodificarse. No todos los formatos, dispositivos o versiones del sistema han sido probados individualmente.
- La caché de compatibilidad tiene un objetivo de limpieza de 2 GB; los archivos activos pueden superarlo temporalmente. Un único archivo preparado está limitado a 8 GB, con al menos 512 MB de espacio libre en disco reservado. La preparación se detiene y muestra un mensaje si el espacio es insuficiente.
- TIFF admite varias páginas; otros formatos de imágenes compuestas sin paginación implementada muestran la primera imagen. La rotación de visualización nunca vuelve a escribir en los originales. No se proporcionan edición, eliminación, base de datos de la biblioteca, uso compartido, sincronización en la nube ni administración de subtítulos externos.
- La aplicación solo lee los medios locales abiertos por el usuario y la carpeta que los contiene. La reproducción de compatibilidad escribe en un caché local; no sube archivos multimedia ni modifica los originales.

Consulte [FORMATS.md](FORMATS.md) para obtener más ejemplos de formato y límites de caché/vista previa.

## Compilar desde el código fuente

Requiere Xcode o herramientas de línea de comandos con el compilador Swift. El repositorio y el paquete fuente incluyen herramientas multimedia universales Intel/Apple Silicon, por lo que una compilación normal no requiere instalar ni descargar dependencias adicionales de terceros. Después de clonar o descargar, compila desde la raíz del repositorio que contiene `build.sh`; No se requiere el diseño del espacio de trabajo de desarrollo original.

```bash
cd /path/to/LumaView
./build.sh
open ../LumaView.app
```

El valor predeterminado produce una aplicación universal; `./build.sh --host` construye solo la arquitectura Mac actual. La aplicación se coloca al lado del directorio de origen como `LumaView.app` de forma predeterminada; establezca `LUMAVIEW_APP_PATH` para otro destino. Los archivos de trabajo de compilación y prueba están predeterminados en `.build/` dentro del repositorio y se pueden reubicar con `LUMAVIEW_WORK_ROOT`. Estos archivos generados están excluidos por `.gitignore`.

Las compilaciones de prueba utilizan `LUMAVIEW_TEST_BUILD=1 ./build.sh --host` para crear una aplicación LumaView Tests separada sin declaraciones de apertura de archivos, lo que evita que las copias de prueba compitan con la aplicación instalada. Los scripts de prueba de UI utilizan este modo de forma predeterminada. Utilice `LUMAVIEW_SKIP_TEST_BUILD=1` y `LUMAVIEW_TEST_APP_PATH` para seleccionar una aplicación ya creada.

FFmpeg está construido bajo LGPL 2.1 o posterior, y dav1d vinculado estáticamente usa BSD 2-Clause. Los archivos fuente correspondientes, sumas de verificación y licencias acompañan al paquete fuente. La reconstrucción de las herramientas multimedia requiere herramientas de línea de comandos Xcode, Python 3, Meson 1.12.1 y Ninja 1.13.2; Instale las herramientas de Python en un entorno virtual y ejecute `./tools/build-media-tools.sh`. Consulte [ThirdParty/README.md](ThirdParty/README.md) para conocer los pasos y la configuración de compilación. PostScript utiliza un ejecutable Ghostscript 10.08.0 independiente (AGPL-3.0-or-later), con su licencia, el código fuente completo correspondiente y el script de compilación incluidos. Las compilaciones de aplicaciones normales utilizan el componente universal incluido; consulte la [guía Ghostscript](ThirdParty/README-Ghostscript.md) para la reconstrucción.

## Fuente y validación

- `Sources/`: interfaz de AppKit, lienzo multimedia, carga ráster y vectorial, ciclo de vida de audio/vídeo, preparación de compatibilidad y configuración predeterminada de la aplicación.
- `Resources/Localizations/`: cadenas de idioma y lista de claves de traducción principales.
- `Resources/MediaFormats.json`: catálogo de formato; `Resources/MediaTools/`: FFmpeg/ffprobe incluido.
- `ThirdParty/sources/`, `Resources/ThirdPartyNotices/`: fuentes y licencias de herramientas multimedia correspondientes.
- `build.sh`: compilación, empaquetado y firma local de aplicaciones universales; `tools/build-media-tools.sh`: reconstrucción de herramientas multimedia.

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

Las pruebas unitarias de decodificación de audio necesitan un FFmpeg de desarrollo con los codificadores relevantes para generar muestras MP3 / FLAC / Opus. Establezca `LUMAVIEW_TEST_FFMPEG` en su ruta. Las pruebas de la aplicación y la interfaz de audio utilizan únicamente componentes incluidos.

Las comprobaciones de integración de la interfaz de usuario requieren una sesión iniciada en el escritorio gráfico de macOS. Abren la aplicación y verifican las interacciones utilizando los medios generados. Los archivos de compilación y los informes de prueba guardados tienen el valor predeterminado `.build/`; Algunos archivos de prueba usados durante la ejecución utilizan el directorio temporal del sistema. Las pruebas no leen fotografías personales de forma predeterminada. Las pruebas de copia del menú contextual utilizan un portapapeles con nombre independiente sin reemplazar el portapapeles actual del usuario. Las pruebas Abrir con / Finder / aplicación predeterminada utilizan simulacros y no cambian las asociaciones de archivos. Consulte [TEST-RESULTS.txt](TEST-RESULTS.md) para conocer el registro de validación de la versión entregada.

Los informes guardados en `Tests/` son registros históricos para sus respectivas versiones, no evidencia de que una copia recién clonada haya pasado automáticamente las pruebas en el entorno actual. Los nombres de las muestras personales son anónimos y los medios originales no se incluyen en el repositorio. Las rutas históricas `work/` registran las fuentes de prueba en ese momento y no son directorios necesarios para las compilaciones actuales. El repositorio conserva los archivos fuente, las sumas de comprobación y las licencias correspondientes de terceros, por lo que el clon inicial es relativamente grande.
