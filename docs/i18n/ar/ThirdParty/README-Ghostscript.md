# أداة Ghostscript لتحويل المستندات

<!-- doc-navigation:start -->
[فهرس الوثائق](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · **العربية** · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


يستدعي LumaView برنامج Ghostscript **10.08.0** الذي أصدرته Artifex في 2026-09-08 كملف تنفيذي محلي مستقل لتحويل EPS وPostScript إلى PDF مؤقت. يحتفظ الناتج بالمسارات المتجهة والنصوص والتدرجات المدعومة. تبقى الصور المضمّنة أصلًا كبكسلات صورًا نقطية. لا يُربط Ghostscript بتطبيق Swift ولا يحتاج تشغيل النسخة المضمّنة إلى Homebrew.

## الرخصة والمصدر المطابق

يوزّع Ghostscript بموجب **رخصة GNU Affero General Public License الإصدار 3 أو أحدث** كما يحدد ملف `LICENSE` الأصلي لهذا الإصدار. نُسخت الرخصة الكاملة وإشعار حقوق Ghostscript واستثناء تضمين الخطوط وإشعارات Adobe CMap واعتمادياته دون تغيير إلى `Resources/ThirdPartyNotices/Ghostscript/`. تتوفر رخصة تجارية منفصلة من Artifex؛ ولا تشمل هذه الحزمة رخصة تجارية. راجع [صفحة الترخيص الرسمية](https://www.ghostscript.com/licensing/index.html).

يوجد إصدار المصدر المطابق الدقيق غير المعدل، بما فيه مصادر الاعتماديات والخطوط المضمّنة، في `ThirdParty/sources/ghostscript-10.08.0.tar.xz`. سُجلت SHA-256 في `ThirdParty/sources/SHA256SUMS-Ghostscript`:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

منشأ المصدر: [صفحة الإصدار الرسمية](https://www.ghostscript.com/releases/index.html) و[ملفات إصدار Artifex 10.08.0](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). تطابق البصمة القيمة المنشورة لملف `.tar.xz`. ترافق حزمة المصدر وبرنامج البناء توزيع مصدر LumaView. لا يفرض LumaView قيودًا إضافية على تعديل أو استبدال الأداة المستقلة أو الهندسة العكسية اللازمة لتصحيح التعديلات. تصف هذه الإشعارات مكوّن الطرف الثالث المضمّن ولا تعيد ترخيص مصدر التطبيق.

## إعادة البناء

المتطلبات: macOS وXcode Command Line Tools وأرشيف المصدر المضمّن وأدوات بناء macOS القياسية. لا تُستخدم مكتبات Homebrew. من مجلد مصدر LumaView:

```sh
./tools/build-document-tools.sh
./build.sh
```

يتحقق البرنامج من الأرشيف ويبني شريحتي Intel وApple Silicon من مجلدات مصدر منفصلة، ويحذف الرموز المحلية ويدمجهما في `Resources/DocumentTools/gs`. تستهدفان macOS 13.0 أو أحدث. لا ينفذ `make install` ولا يكتب في مدير حزم النظام. يختار `LUMAVIEW_DOCUMENT_BUILD` مجلد البناء الوسيط ويضبط `LUMAVIEW_DOCUMENT_JOBS` توازي make (الافتراضي 4). يبني الوسيط الاختياري `x86_64` أو `arm64` معمارية واحدة. يوقّع بناء التطبيق الملف التنفيذي المنسوخ مع التطبيق.

يضم نظام الملفات الداخلي `%rom%` شيفرة التهيئة والخطوط المضمّنة وAdobe CMaps وملفات ICC. مسارات البحث الخارجية الافتراضية فارغة. لا يُفعّل سوى جهاز الإخراج `pdfwrite`. تُعطل الطباعة/CUPS وX11 وGTK وfontconfig وD-Bus وTesseract/OCR والمشغّلات الديناميكية وIJS الخارجي وأدوات استخراج المستندات. تُجمع جميع مكتبات الفك واللون والخطوط المضمّنة من الأرشيف المطابق؛ ويقتصر الربط الديناميكي على مكتبات Apple النظامية. راجع [وثائق البناء الرسمية](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html) لآليات ROM والبناء المتقاطع.

يشغّل LumaView المفسّر بـ `-dSAFER` وملفي إدخال وإخراج محددين ومجلد عمل مؤقت خاص وإلغاء ومهلة زمنية. يجب ألا ترث بيئة العملية خيارات Ghostscript أو مسارات المكتبات التي يحددها المستخدم. مثال لمواد اختبار مولّدة موثوقة:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

جميع خيارات البناء في `tools/build-document-tools.sh`؛ ولا تُطبّق رقع على أرشيف المصدر. يمكن اختبار التنفيذ الأصلي فقط للمعماريات التي يدعمها مضيف البناء. تفحص مراجعات الإصدار شريحتي Mach-O وتشغّل EPS مولّدًا يحوي مسارات ونصوصًا بالشريحة الموافقة للمضيف، لتأكيد بقاء أوامر رسم المتجهات والنصوص في PDF الناتج.
