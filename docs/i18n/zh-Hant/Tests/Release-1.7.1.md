> 歷史驗證記錄中的個人樣本檔案名已匿名化；測試資料與結果保持原樣。

<!-- doc-navigation:start -->
[文件目錄](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · **繁體中文** · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# LumaView 1.7.1 驗證記錄

版本 1.7.1，build 13。2026-10-22，macOS 15.7.9 / Intel。應用及三個內置工具通過 arm64 + x86_64 架構與本地簽名核驗；本輪未在 Apple Silicon 硬體運行。

## 已定位並修復

使用者的三個 PSB 均為 8 位 RGB、4 通道、帶合成透明的 RLE 檔案，約 108–123 MiB。大部分檔案體積屬於可直接跳過的圖層資料；主畫布約 850–960 萬像素。

1. 舊逐行解碼器為每個 PackBits 標記和值調用 FileHandle 讀取，產生大量小讀取，令主圖和縮略圖隊列停留過久。改為最多 64 KiB 分塊讀取，保留跨塊 literal/run 狀態及邊界檢查，長 no-op 資料仍可取消。ZIP 僅對採樣到的行恢復預測，仍完整校驗壓縮流。
2. 三個檔案都帶有資源 1036 的有效 RGB JPEG 縮略圖。現在膠片帶優先使用它，校驗格式、尺寸、長寬比及壓縮長度；主圖始終解碼真正的合成圖。無效預覽、舊式 BGR 資源或無預覽時回退到合成圖。
3. 系統 ImageIO 會拒絕部分帶有效 Generic RGB ICC 的小尺寸 PSD 合成資料，舊版因而返回空縮略圖。回退時分開解碼像素，再附加經驗證且色彩模型、分量一致的原 ICC，不直接丟棄配置。原檔案 ICC 與系統標準 Generic RGB Profile 相同，新增回歸使用系統配置生成測試資料，未將使用者照片寫入原始碼。
4. PSB 主圖復用已經解析的頭資訊，並避免額外調用 ImageIO 掃描圖層取元資料。原始尺寸、透明度和主圖品質保留。

## 三個原檔案實測

以下為這台 Mac 的本地測試，受系統負載與檔案快取影響，不是所有設備的性能保證。舊解碼與新解碼均使用優化編譯。

| 檔案 | 原始尺寸 | 舊主圖解碼 | 新主圖解碼 | 新合成圖縮略解碼（無內嵌預覽路徑） |
| --- | --- | --- | --- | --- |
| Sample A | 2582 × 3318 | 超過 15 秒後測試主動取消 | 0.68 秒 | 0.039 秒 |
| Sample B | 2610 × 3307 | 14.35 秒 | 0.65 秒 | 0.028 秒 |
| Sample C | 2843 × 3361 | 超過 15 秒後測試主動取消 | 0.70 秒 | 0.028 秒 |

通過真實 ImageLoader 同時請求三張縮略圖，約 0.06 秒全部完成。完整主圖經加載器分別約 0.90 / 0.65 / 0.74 秒。舊版三張合成縮略圖均報 unsupported；新版本均成功。原件在測試前後逐位元組 SHA-256 一致，應用沒有寫入原檔案。

## 本輪通過的檢查

| 項目 | 結果 |
| --- | --- |
| PSD / PSB 編碼與透明合成 | 712 / 712 |
| RLE 性能、內嵌預覽、ICC、跨塊與取消 | 54 / 54 |
| 三個原始 PSB 的真實 ImageLoader 集成 | 21 / 21 |
| 443 檔案膠片帶、快取、失效回調 | 37 / 37 |
| 獨立縮略圖請求與取消 | 13 / 13 |
| 圖片庫與系統解碼 | 78 / 78 |
| 已安裝優化發佈版右鍵選單與複製 | 28 / 28 |
| 合計 | 943 / 943 |

新增測試覆蓋密集單位元組 literal、64 KiB 邊界、長 no-op 取消、截斷與越界、內嵌縮略圖與主圖各自正確內容、ICC、透明度、小尺寸非整數縮放。既有 112 個編碼組合、128 個帶圖層透明標誌的結構樣例繼續通過。縮略圖條檢查覆蓋快速切換、離屏取消和舊回調不污染當前列表。

正式安裝版與 outputs/LumaView.app 完整檔案清單和哈希一致，均通過 codesign --verify --deep --strict。安裝前保留舊版 ZIP 備份；未修改預設打開關聯。ZIP 交付包另行執行 CRC 和版本校驗。歷史 1.7.0 完整報告保留在 Tests/Release-1.7.0.md，其未重跑檢查不計入本輪。

主程序 SHA-256：`cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`。

## 日誌

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
