# Ghostscript 文件轉換工具

<!-- doc-navigation:start -->
[文件目錄](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · **繁體中文** · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView 將 Artifex 於 2026-09-08 發行的 Ghostscript **10.08.0** 作為獨立的本機執行檔呼叫，將 EPS 與 PostScript 轉換為暫存 PDF。PDF 輸出保留支援的向量路徑、文字與漸層。原本以點陣像素嵌入的圖片仍為點陣圖片。Ghostscript 未連結至 Swift 應用程式，執行這個隨附的執行檔也不需要安裝 Homebrew。

## 授權與對應原始碼

依此發行版本原始 `LICENSE` 檔案的規定，Ghostscript 以 **GNU Affero General Public License 第 3 版或更新版本** 散布。完整授權、Ghostscript 著作權聲明、字型嵌入例外條款、Adobe CMap 聲明與內含相依項目的聲明，均原封不動複製至 `Resources/ThirdPartyNotices/Ghostscript/`。Artifex 也另行提供商業授權；本套件不含商業授權。請參閱[官方授權頁面](https://www.ghostscript.com/licensing/index.html)。

完全相符且未修改的對應原始碼發行版本（包含隨附的相依項目與字型原始碼）位於 `ThirdParty/sources/ghostscript-10.08.0.tar.xz`。其 SHA-256 記錄於 `ThirdParty/sources/SHA256SUMS-Ghostscript`：

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

原始碼來源：[官方發行頁面](https://www.ghostscript.com/releases/index.html)及 [Artifex 的 10.08.0 發行資源](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080)。校驗值與 `.tar.xz` 資源公開的校驗值一致。原始碼套件及此建置指令碼隨 LumaView 原始碼一同散布。LumaView 不對修改或替換這個獨立工具，或為偵錯此類修改所需的逆向工程施加額外限制。這些聲明說明隨附的第三方元件，並非重新授權應用程式原始碼。

## 重新建置

需求：macOS、Xcode Command Line Tools、隨附的原始碼封存檔，以及標準 macOS 建置工具。不使用 Homebrew 函式庫。在 LumaView 原始碼目錄執行：

```sh
./tools/build-document-tools.sh
./build.sh
```

指令碼會驗證原始碼封存檔，從獨立原始碼目錄建置 Intel 與 Apple Silicon 架構區段、移除區域符號，再將兩個區段合併為 `Resources/DocumentTools/gs`。兩者皆以 macOS 13.0 或更新版本為目標。它不會執行 `make install` 或寫入系統套件管理器。`LUMAVIEW_DOCUMENT_BUILD` 選擇中間建置目錄；`LUMAVIEW_DOCUMENT_JOBS` 控制 make 平行工作數（預設 4）。選用參數 `x86_64` 或 `arm64` 僅建置單一架構。應用程式建置會將複製後的執行檔與應用程式一起簽章。

執行檔的內部 `%rom%` 檔案系統包含初始化程式碼、隨附字型、Adobe CMap 與 ICC 描述檔。外部預設搜尋路徑為空。僅啟用 `pdfwrite` 輸出裝置。列印/CUPS、X11、GTK、fontconfig、D-Bus、Tesseract/OCR、動態驅動程式、外部 IJS 與文件擷取工具均已停用。所有內含解碼、色彩與字型函式庫均從對應原始碼封存檔編譯；動態連結僅限 Apple 系統函式庫。ROM 檔案系統與交叉編譯機制請參閱[官方建置文件](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html)。

LumaView 使用 `-dSAFER`、指定的輸入與輸出檔案、私有暫存工作目錄、取消功能和逾時機制執行解譯器。程序環境不得繼承使用者指定的 Ghostscript 選項或函式庫路徑。以下為程式產生且可信任之測試素材的範例：

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

完整建置選項位於 `tools/build-document-tools.sh`；原始碼封存檔未套用修補。原生執行只能在建置主機支援的架構上測試。發行檢查會檢驗兩個 Mach-O 架構區段，並透過與主機相容的區段處理一份程式產生且含路徑與文字的 EPS，確認輸出的 PDF 仍含向量繪圖與文字運算子。
