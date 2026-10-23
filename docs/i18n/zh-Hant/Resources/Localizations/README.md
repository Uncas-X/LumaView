# LumaView 介面語言

<!-- doc-navigation:start -->
[文件目錄](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · **繁體中文** · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


應用程式初始使用**跟隨系統**。它會選擇 macOS 偏好語言清單中第一個受支援的語言；若皆不受支援，則使用英語。在 **LumaView → 語言…** 選擇的語言立即生效，並僅為此應用程式記住該設定。

支援的選項：簡體中文、繁體中文、英語、日語、韓語、法語、德語、西班牙語、義大利語、葡萄牙語、俄語、阿拉伯語、印地語、土耳其語、荷蘭語與波蘭語。葡萄牙語變體目前使用巴西葡萄牙語詞庫。選擇器刻意顯示各語言自己的名稱，方便使用者從不熟悉的介面語言切換回來。

`catalog.json` 將可讀的簡體中文來源鍵對應至本地化字串。`core-keys.json` 定義每份詞庫必須包含的常用控制項、選單、設定、文件導覽、中繼資料標籤及鍵盤說明字串。某個語言缺少低頻診斷訊息時，會回退至英語。檔名、目錄、編解碼器、格式及內嵌相機中繼資料的名稱保持不變。系統原生對話框文字由作業系統以其自身語言提供。

靜態文字使用 `L10n.tr("source key")`。動態文字使用 `L10n.format("第 %d / %d 页", current, total)`，不要先對中文字串插值再翻譯。各語言的預留位置型別與數量須保持一致。觀察 `L10n.languageDidChange` 以更新現有介面並重新繪製文字。測試使用 `useLanguageForTesting`，避免修改使用者持續保存的語言設定。

執行 `Tests/run-localization-tests.sh`，檢查語系解析、完整核心鍵覆蓋、格式預留位置一致性、回退行為及阿拉伯語文字方向。翻譯文案尚未經專業語言審校。
