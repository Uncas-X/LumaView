# LumaView — 繁體中文

<!-- language-navigation:start -->
[简体中文](../../README.md) · [English](README.en.md) · **繁體中文** · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- language-navigation:end -->

這是 LumaView 的快速入門指南。完整說明請參閱[英文手冊](README.en.md)或[簡體中文手冊](../../README.md)。目前版本為 **1.7.2（組建 14）**。

LumaView 是原生 macOS 圖片、影片、音訊及多頁文件檢視器，操作靈感來自 Picasa Photo Viewer 的快速瀏覽體驗。它使用自己的名稱與原創圖示，與 Google 無隸屬關係，專注於檢視檔案。

## 下載與安裝

下載 [LumaView for macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)，或瀏覽[所有版本](https://github.com/Uncas-X/LumaView/releases)。需要 **macOS 13 或以上版本**，同一個應用程式支援 Intel 與 Apple Silicon。

解壓縮後，將 `LumaView.app` 拖曳到「應用程式」資料夾。目前採用本機 ad-hoc 簽章，尚未經 Apple 公證；若 macOS 阻擋開啟，確認下載來源後，可依系統提示至「隱私權與安全性」允許開啟。

## 開始瀏覽

拖入檔案或資料夾，或按 `Cmd+O` 開啟。開啟單一檔案後，可以瀏覽同一資料夾內相鄰的媒體檔案；資料夾掃描僅限目前層級，不包含子資料夾。

- 底部縮圖列支援快速切換；主畫面提供縮放、平移、旋轉、全螢幕、平滑過場及半透明毛玻璃背景。
- PNG、GIF、PSD、PSB 的點陣透明區域保持透明，陰影沿內容形狀呈現；文件頁面使用白紙背景。PSD/PSB 讀取已儲存的相容性合成圖，不會解析成可編輯圖層。
- 影片與音訊優先使用系統播放功能，需要時以內附 FFmpeg 進行相容性處理。音訊主畫面優先顯示內嵌封面，沒有封面時顯示波形。
- PDF、相容 PDF 的 AI 與多頁 TIFF 支援內頁瀏覽。SVG、支援的 EPS/PS 和舊版 AI 可進行向量繪製；EPS/PS 透過內附 Ghostscript 處理，內嵌點陣圖仍受原始解析度限制。
- 在主畫面按右鍵，可選擇其他應用程式開啟、在 Finder 中顯示，以及複製圖片、影片目前影格、PDF 頁面或支援的 PDF 內嵌圖片。
- 音訊與影片的播放／暫停、停止按鈕與幻燈片控制分開。設定中可依格式指定預設開啟程式，並從 16 種語言中選擇介面語言；預設跟隨系統。

## 常用快捷鍵

| 按鍵 | 功能 |
|---|---|
| `Cmd+O` | 開啟檔案或資料夾 |
| `←` / `→` | 切換目前焦點層的上一個／下一個檔案或頁面 |
| `↑` / `↓` | 多頁文件中，將焦點移至頁面列／檔案列 |
| 滾輪、雙指縮放、`+` / `-` | 放大或縮小 |
| `0`；`1` | 符合視窗大小；切換 100%／符合視窗大小 |
| `Cmd+R`；`F` | 旋轉；全螢幕 |
| `P`；`S` | 音影片播放／暫停；停止 |
| `Cmd+4` | 控制幻燈片播放 |
| `Cmd+C` | 複製圖片、目前影格或頁面 |

**空白鍵切換背景**，不控制媒體播放。多頁文件的橙色框表示焦點所在層的目前項目，失焦層的目前項目則顯示灰色框。

## 從原始碼建置

安裝 Xcode 或 Swift 命令列工具後，在儲存庫根目錄執行：

```bash
./build.sh
open ../LumaView.app
```

`./build.sh --host` 僅建置目前 Mac 的架構。中間檔案預設位於 `.build/`；可用 `LUMAVIEW_WORK_ROOT` 更改工作目錄，以 `LUMAVIEW_APP_PATH` 更改應用程式輸出路徑。以上路徑以儲存庫根目錄為準，不是本說明所在的目錄。所需媒體工具與對應原始碼、授權封存檔均隨儲存庫提供。

## 限制與隱私

LumaView 讀取本機檔案，不上傳雲端、不修改原始檔案，也不提供編輯器、圖層編輯、圖庫資料庫或雲端同步。大型圖片可能使用受記憶體預算限制的降採樣預覽；繼續放大無法恢復預覽中省略的細節。部分媒體需要先在本機完成整個檔案的轉換才可播放，過程會使用磁碟快取並可能花費時間。系統解碼與相容性處理無法保證支援所有編碼；DRM、損壞或不支援的檔案可能無法開啟。

詳見[格式支援說明（簡體中文）](../../FORMATS.md)、[第三方聲明](../../ThirdParty/README.md)與 [Ghostscript 聲明](../../ThirdParty/README-Ghostscript.md)。
