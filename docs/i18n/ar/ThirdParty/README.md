# أدوات الوسائط المضمّنة

<!-- doc-navigation:start -->
[فهرس الوثائق](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · **العربية** · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


يستدعي LumaView نسختي FFmpeg 9.0.2 وffprobe غير المعدلتين كعمليتين محليتين منفصلتين. بُنيتا من المصدر لـ Intel وApple Silicon باستهداف macOS 13. تستخدمان dav1d 1.5.3 المرتبط ساكنًا لفك AV1، ومكتبات النظام الديناميكية فقط. لا يلزم Homebrew أو VLC وقت التشغيل.

يُهيأ FFmpeg وفق LGPL 2.1 أو أحدث دون `--enable-gpl` أو `--enable-nonfree`. يستخدم dav1d رخصة BSD 2-Clause. توجد إشعارات الرخص الكاملة في `Resources/ThirdPartyNotices` وتُنسخ إلى حزمة التطبيق. تُضمّن أرشيفات المصدر المطابق الدقيقة غير المعدلة في `sources/` مع بصمات SHA-256. جميع خيارات التهيئة وخطوات البناء في `tools/build-media-tools.sh`. لا يفرض LumaView قيودًا إضافية على تعديل أو استبدال هذه الأدوات المستقلة أو الهندسة العكسية اللازمة لتصحيح تلك التعديلات.

المصادر الرسمية:

- [إصدار FFmpeg وتوقيعه](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. تم التحقق من التوقيع المنفصل بمفتاح إصدار FFmpeg ‏`FCF986EA15E6E293A5644F10B4322F04D67658D8`.
- [إصدار dav1d](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [معلومات ترخيص FFmpeg](https://ffmpeg.org/legal.html).

## إعادة البناء

يستخدم البناء المعتاد الثنائيات الشاملة المضمّنة. لإعادة بناء الأدوات ثبّت Xcode Command Line Tools وPython 3 وMeson 1.12.1 وNinja 1.13.2. مثلًا، أنشئ بيئة Python افتراضية محلية وثبّت فيها `meson==1.12.1 ninja==1.13.2`، ثم فعّلها وشغّل:

```sh
./tools/build-media-tools.sh
./build.sh
```

يتحقق الأمر الأول من بصمات المصدر ويجمع المعماريتين ويستبدل `Resources/MediaTools/{ffmpeg,ffprobe}`. استخدم `LUMAVIEW_PYTHON` لاختيار Python و`LUMAVIEW_MEDIA_BUILD` لاختيار مجلد البناء الوسيط. الوسيط `x86_64` أو `arm64` يبني معمارية واحدة، و`universal` الافتراضي يدمجهما. يوقّع بناء التطبيق الأدوات الداخلية والتطبيق بتوقيع ad-hoc محلي.

تُعطل الشبكة وأجهزة الالتقاط وffplay والمُرمّزات الخارجية غير dav1d ومرمّزات GPL. تُضمّن كل مفككات الترميز وفك التغليف الداخلية المتاحة في هذه التهيئة. يُعد الصوت بصيغة AAC؛ ويُعاد تغليف الفيديو عند الإمكان، ثم تُستخدم مخارج توافق VideoToolbox H.264 أو MPEG-4 أو ProRes. هذا مسار للعرض وليس واجهة تصدير أو تحويل ترميز.

## مفسّر PostScript المتجه

تستخدم معاينة EPS وPostScript وIllustrator القديم كذلك Ghostscript 10.08.0 المضمّن كعملية فرعية محلية مستقلة مقيدة. راجع [README-Ghostscript.md](README-Ghostscript.md) لرخصة AGPL-3.0-or-later وأرشيف المصدر المطابق الكامل والبصمات والبناء الشامل القابل لإعادة الإنتاج. لا يحتاج بناء التطبيق المعتاد إلى تثبيت Ghostscript في النظام.
