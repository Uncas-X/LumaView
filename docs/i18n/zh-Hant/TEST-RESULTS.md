# LumaView 1.7.2 驗證記錄

<!-- doc-navigation:start -->
[文件目錄](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · **繁體中文** · [English](../en/TEST-RESULTS.md) · [日本語](../ja/TEST-RESULTS.md) · [한국어](../ko/TEST-RESULTS.md) · [Français](../fr/TEST-RESULTS.md) · [Deutsch](../de/TEST-RESULTS.md) · [Español](../es/TEST-RESULTS.md) · [Italiano](../it/TEST-RESULTS.md) · [Português (Brasil)](../pt-BR/TEST-RESULTS.md) · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · [Türkçe](../tr/TEST-RESULTS.md) · [Nederlands](../nl/TEST-RESULTS.md) · [Polski](../pl/TEST-RESULTS.md)
<!-- doc-navigation:end -->


版本 1.7.2，build 14。2026-10-22，macOS 15.7.9 / Intel。應用與內置工具通過 arm64 + x86_64 通用架構與本地簽名核驗；本輪未在 Apple Silicon 硬體運行。

## 本次修復

柵格圖片統一直接顯示透明區域：PNG / GIF / PSD / PSB 等不再疊加灰白棋盤或畫布矩形邊框。顯示陰影來自當前畫面實際合成透明度，而不是整張圖片畫布；因此透明邊距沒有額外矩形陰影，鏤空、獨立軟蒙版和半透明區域參與實際輪廓。

原實現僅根據 CGImage.alphaInfo 添加棋盤，遺漏帶獨立 Quartz mask 的 PSB；且每次縮放都強制安裝矩形 shadowPath，邊框本身也會形成矩形陰影。現在柵格圖去掉這些矩形來源，圖層陰影由合成 alpha 自動形成。繪圖導出路徑同樣對圖片本身投影，不預先填充矩形。GIF / APNG 換幀繼續替換當前紋理，陰影隨幀更新；無需每幀掃描透明像素或額外構造整幅 RGBA 圖。

文檔頁面的白色紙面與影片矩形表面仍保留其現有顯示方式；複製圖片繼續使用原圖像素，不帶查看背景、棋盤或顯示陰影。沒有更改 PSB 解碼器、縮略圖調度或上版的快速預覽實現。

## 本輪驗證

| 項目 | 通過 |
| --- | --- |
| 透明區域、輪廓陰影與換幀 | 133 / 133 |
| 畫布幾何、動畫與滑鼠 | 66 / 66 |
| 文檔解析與完整頁繪制 | 56 / 56 |
| 正式安裝版文檔、EPS / PS 縮放翻頁與焦點 | 75 / 75 |
| 正式安裝版右鍵選單與複製 | 28 / 28 |
| 合計 | 358 / 358 |

透明測試為同一帶鏤空、不規則突出部分和較大透明邊距的圖形，分別使用 RGBA、獨立 Quartz mask、真實編碼並解碼的 PNG、GIF、PSD、PSB。檢查 CALayer 合成與 draw 導出像素，驗證透明邊緣無矩形底板/陰影、內外輪廓有陰影；還覆蓋全透明圖片、換幀、旋轉縮放、快速切換及半透明查看背景。已人工查看導出 PNG。

上述六種輸入的 CALayer 導出和 PNG draw 導出的 PNG SHA-256 完全一致：`578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`。測試素材由代碼生成，未把使用者照片加入原始碼。

額外進行了有界軟體繪制探針：32 MP 位圖，邏輯畫布包含 16,384 × 7,812 和 300,000 × 128，分別在適合窗口、100%、3200% 下比較新舊陰影。測試進程峰值 RSS 約 428 MiB，新舊繪制耗時相近；這是 CALayer.render(in:) 的軟體快照開銷，不是 GPU 幀率結論。沒有因此加入圖層柵格快取。

正式安裝版與 outputs/LumaView.app 完整檔案清單和哈希一致，均通過 codesign --verify --deep --strict。安裝前保留舊版 ZIP 備份；預設打開關聯經前後讀回核對。ZIP 交付包隨後執行 CRC 和版本校驗。歷史報告保留在 Tests/Release-1.7.0.md 與 Tests/Release-1.7.1.md；舊版未重跑的檢查不加入本輪數量。

主程序 SHA-256：`b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`。

## 日誌來源

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
