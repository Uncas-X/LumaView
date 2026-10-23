# Idiomas de la interfaz de LumaView

<!-- doc-navigation:start -->
[Documentación](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · **Español** · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


La aplicación comienza con **Seguir sistema**. Elige el primer idioma admitido en la lista de idiomas preferidos de macOS y luego el inglés si no hay ninguno compatible. Un idioma seleccionado en **LumaView → Idioma…** entra en vigor inmediatamente y se recuerda solo para esta aplicación.

Opciones admitidas: chino simplificado, chino tradicional, inglés, japonés, coreano, francés, alemán, español, italiano, portugués, ruso, árabe, hindi, turco, holandés y polaco. Las variantes portuguesas utilizan actualmente el catálogo de portugués brasileño. Los nombres nativos en el selector son intencionales, por lo que un usuario puede volver a su idioma desde una interfaz que no entiende.

`catalog.json` asigna claves fuente legibles en chino simplificado a cadenas localizadas. `core-keys.json` define los controles, menús, configuraciones, navegación de documentos, etiquetas de metadatos y cadenas de ayuda del teclado comunes necesarios en cada catálogo. Los mensajes de diagnóstico de baja frecuencia utilizan el idioma alternativo en inglés cuando un idioma no tiene su propia entrada. Los nombres de archivos, directorios, códecs, formatos y metadatos de cámara integrados permanecen sin cambios. El sistema operativo proporciona texto de diálogo del sistema nativo en su propio idioma.

Utilice `L10n.tr("source key")` para texto estático. Para texto dinámico, utilice `L10n.format("第 %d / %d 页", current, total)`, en lugar de interpolar una cadena china antes de la traducción. Mantenga los tipos de marcadores de posición y los recuentos consistentes en todas las traducciones. Observe `L10n.languageDidChange` para actualizar las interfaces existentes y volver a dibujar el texto representado. Las pruebas utilizan `useLanguageForTesting` para evitar modificar el idioma persistente del usuario.

Ejecute `Tests/run-localization-tests.sh` para resolución del idioma, cobertura principal completa, coherencia de formato y marcador de posición, comportamiento alternativo y dirección del texto en árabe. El texto traducido no ha sido sometido a revisión lingüística profesional.
