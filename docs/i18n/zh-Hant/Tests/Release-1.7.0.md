> 歷史驗證記錄中的個人樣本檔案名已匿名化；測試資料與結果保持原樣。

<!-- doc-navigation:start -->
[文件目錄](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · **繁體中文** · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# LumaView 1.7.0 驗證記錄

日期：2026-10-22（Asia/Shanghai）。本輪運行環境：macOS 15.7.9、x86_64。應用目標為 macOS 13+，四個可執行檔案均為 Intel / Apple Silicon 通用版。

## 本次改動與實測結果

- 應用內置 Ghostscript 10.08.0，直接打開 EPS、PostScript 和舊式 PostScript AI 時，在後台生成保留矢量路徑、文字及原嵌入圖像的 PDF，再交給現有畫布。無需使用者另裝解釋器或手動轉換；縮放、拖動、旋轉和多頁導航沿用當前交互。內嵌 TIFF 回退仍用於無法完成矢量轉換而檔案提供預覽的情況，不將位圖回退標記為矢量。
- 實測原附件 `sample-vector.eps` 已使用完整 PostScript 內容。生成 PDF 掃描得到 **147,521 次路徑/漸變相關操作、59 次文字操作、160 次 XObject 調用**。這裡 XObject 數量按 PDF `Do` 操作統計，可能包含圖像或 Form，不能等同為獨立圖片張數。測試確認保留真實矢量內容；原 EPS 與 `sample-vector.svg` 均經過測試前後 SHA-256 比較，原件未改變。
- PostScript 使用獨立可取消進程、Ghostscript SAFER 和系統進程沙盒；輸入複製到專用臨時目錄，解釋器不能讀取使用者其他檔案、任意寫入外部檔案或使用外部管道。通過超時、取消、多消費者復用、損壞輸入及快取失效檢查；完成結果原子發佈，不用部分 PDF 填充縮略圖。真實查看器檢查 EPS 3200% 矢量縮放、多頁 PS 的上下焦點及左右翻頁，以及轉換中切換 PNG 後舊結果不會覆蓋當前畫面。
- Photoshop 格式組新增 `.psb`，與 `.psd` 一同參與檔案發現、主圖、縮略圖及預設打開設定。讀取兼容合成圖，保留原始畫布尺寸；大檔案按顯示需求生成有界預覽。完成 **112 組編碼組合、128 組帶圖層透明標記的結構樣例、1 份大幅 PSB、13 份損壞樣例**驗證。透明合成依據圖層計數及 Lr16/Lr32、Mtrn/Mt16/Mt32 標記識別；普通額外 Alpha 通道不會被誤當作合成透明度。包含透明像素數值、白色底色去除、編碼一致性、大行取消及主圖/縮略圖集成回歸。
- 預設打開彈窗每次打開、應用重新激活、批量設定完成後讀取系統實際關聯；系統關聯本身跨重啓保存，不使用未應用草稿冒充成功結果。當前格式全部類型對應當前應用時勾選；僅部分類型命中或指向同 bundle ID 的其他副本時顯示橫線，並在提示中解釋。清空只改變草稿，不撤銷系統預設關聯。
- 頂部“全選所有格式”一次選中圖片、矢量/文檔、影片和音訊，包含搜索結果之外的格式；仍需點擊設定按鈕後才寫入關聯。檢測、部分成功、失敗讀回、重建控制器、草稿與實際狀態區別、全量選擇均使用記憶體 mock 後端驗證，測試未改變使用者系統預設應用。
- 本輪新增設定、PostScript 與 Photoshop 文案覆蓋全部 16 種語言，核心文案與格式佔位符驗證通過。

## 本輪驗證

僅計入下面列明且具有完整成功匯總的本輪日誌；未重跑的歷史模塊不加入數量。

| 檢查 | 通過 |
| --- | --- |
| PostScript 矢量轉換、取消、隔離與實際 EPS | 24 / 24 |
| SVG / EPS 兼容與原附件校驗 | 64 / 64 |
| PSD / PSB 合成圖、透明通道、大圖與損壞資料 | 712 / 712 |
| 預設應用系統讀回與批量設定（mock） | 101 / 101 |
| 預設格式彈窗、重開狀態與全部格式選擇（mock） | 34 / 34 |
| 16 種語言與佔位符 | 174 / 174 |
| 發佈應用格式聲明 | 15 / 15 |
| 圖片庫與系統解碼 | 78 / 78 |
| 畫布幾何、動畫與滑鼠 | 66 / 66 |
| 文檔解析與完整頁繪制 | 56 / 56 |
| 文檔焦點、EPS / PS 縮放翻頁與取消切檔案 | 75 / 75 |
| 真實窗口點擊與生命週期 | 65 / 65 |
| 443 檔案縮略圖、快取與過期回調 | 37 / 37 |
| 縮略圖請求取消與消費者隔離 | 13 / 13 |
| 正式安裝發佈版右鍵選單與私有剪貼簿 | 28 / 28 |
| **合計** | **1542 / 1542** |

正式安裝的優化發佈版另執行 28 項右鍵選單檢查，通過真實選單與 target/action 分發，並使用獨立命名剪貼簿。驗證複製圖片、影片當前幀、PDF 圖片及整頁、旋轉、切換/關閉時的過期結果處理；測試未覆蓋使用者系統剪貼簿。原有滑鼠點擊、窗口生命週期、頁面焦點、完整頁呈現、縮略圖快取與取消回歸均通過。

## 發佈目錄與安裝版核驗

版本 **1.7.0，build 12**。報告生成前已核對 `outputs/LumaView.app` 和 `/Applications/LumaView.app` 的 bundle ID、版本、build、完整檔案清單和 SHA-256；兩處應用內容一致。四個可執行檔案均通過雙架構檢查，兩處應用通過 `codesign --verify --deep --strict` 驗證；內置 Ghostscript 自報版本為 10.08.0，本地化和版本資源與原始碼目錄一致，Ghostscript 原始碼歸檔 SHA-256 與附帶清單一致。構建時會重新簽名解釋器，因此不要求籤名後的二進制與原始碼目錄內的未重簽名副本逐位元組相同。

| 可執行檔案 | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

本報告不代替隨後生成的 ZIP 完整性檢查，也不聲稱進行 Apple 公證。簽名為本地臨時簽名；Apple Silicon 完成交叉編譯與架構檢查，本輪未在 Apple Silicon 硬體運行。Ghostscript 原始碼壓縮包、許可證與重建說明隨原始碼交付。

## 範圍與邊界

EPS / PS 中原本嵌入的位圖仍受其自身分辨率限制；外部字體或檔案資源、特殊或損壞 PostScript 內容不保證能夠完整轉換。PSD / PSB 預覽依賴檔案中的兼容合成圖，不執行 Photoshop 圖層編輯或重建缺失合成圖；缺失時提示啓用“最大兼容性”後重新保存。原始畫布尺寸可大於實際顯示預覽尺寸，不將有界預覽宣稱為所有源像素都已完整解碼。其他格式邊界見 [FORMATS.md](../FORMATS.md)。

## 本輪日誌來源

以下檔案複製到 `Tests/`，歷史未重跑報告仍保留但不計入本輪合計：

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
