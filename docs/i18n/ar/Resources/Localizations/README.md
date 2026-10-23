# لغات واجهة LumaView

<!-- doc-navigation:start -->
[فهرس الوثائق](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · **العربية** · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


يبدأ التطبيق على **اتباع النظام**. يختار أول لغة مدعومة من قائمة macOS المفضلة، ثم الإنجليزية إذا لم توجد لغة مدعومة. يسري اختيار **LumaView → اللغة…** فورًا ويُحفظ لهذا التطبيق فقط.

الخيارات المدعومة: الصينية المبسطة والتقليدية والإنجليزية واليابانية والكورية والفرنسية والألمانية والإسبانية والإيطالية والبرتغالية والروسية والعربية والهندية والتركية والهولندية والبولندية. تستخدم متغيرات البرتغالية حاليًا كتالوج البرتغالية البرازيلية. عرض الأسماء بلغاتها الأصلية مقصود، كي يتمكن المستخدم من العودة من واجهة بلغة لا يعرفها.

يربط `catalog.json` مفاتيح المصدر المقروءة بالصينية المبسطة بالنصوص المترجمة. يحدد `core-keys.json` عناصر التحكم والقوائم والإعدادات وتنقل المستندات وتسميات البيانات الوصفية ومساعدة لوحة المفاتيح المطلوبة في كل كتالوج. تستخدم الرسائل التشخيصية النادرة البديل الإنجليزي إذا غابت ترجمتها. تبقى أسماء الملفات والمجلدات والترميزات والصيغ وبيانات الكاميرا المضمّنة كما هي. يوفّر النظام نصوص حواراته بلغته الخاصة.

استخدم `L10n.tr("source key")` للنص الثابت. وللنص الديناميكي استخدم `L10n.format("第 %d / %d 页", current, total)` بدل إدخال القيم في نص صيني قبل ترجمته. حافظ على أنواع مواضع القيم وأعدادها بين الترجمات. راقب `L10n.languageDidChange` لتحديث الواجهات القائمة وإعادة رسم النص. تستخدم الاختبارات `useLanguageForTesting` لتجنب تغيير لغة المستخدم المحفوظة.

شغّل `Tests/run-localization-tests.sh` لاختبار اختيار اللغة وتغطية المفاتيح الأساسية وتوافق مواضع التنسيق وسلوك البدائل واتجاه العربية. لم تخضع الترجمة لمراجعة لغوية احترافية.
