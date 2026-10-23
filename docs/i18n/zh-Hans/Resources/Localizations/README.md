# LumaView 界面语言

<!-- doc-navigation:start -->
[文档目录](../../INDEX.md) · **简体中文** · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


应用启动时默认选择**跟随系统**。它从 macOS 的首选语言列表中选取第一个支持的语言；如果没有匹配项，则使用英语。在 **LumaView → 语言…** 中选择的语言立即生效，只为此应用保存。

支持简体中文、繁体中文、英语、日语、韩语、法语、德语、西班牙语、意大利语、葡萄牙语、俄语、阿拉伯语、印地语、土耳其语、荷兰语和波兰语。葡萄牙语变体目前使用巴西葡萄牙语词条。选择器特意显示各语言的本地名称，便于用户从不熟悉的界面语言中切换回来。

`catalog.json` 将可读的简体中文源键映射为各语言的文字。`core-keys.json` 列出每种语言词条必须具备的常用控件、菜单、设置、文档导航、元数据标签和键盘帮助文字。某种语言缺少的低频诊断信息使用英语回退。文件名、目录名、编解码器、格式名称和内嵌相机元数据保持原样。系统原生对话框文字由操作系统按其语言提供。

静态文字使用 `L10n.tr("source key")`。动态文字使用 `L10n.format("第 %d / %d 页", current, total)`，不要先插值中文字符串再翻译。所有翻译必须保持占位符的类型和数量一致。监听 `L10n.languageDidChange` 以刷新已打开的界面并重新绘制文字。测试调用 `useLanguageForTesting`，不会修改用户保存的语言选择。

运行 `Tests/run-localization-tests.sh` 可检查语言解析、核心词条完整性、格式占位符一致性、回退行为和阿拉伯语文字方向。翻译文字尚未经过专业语言校对。
