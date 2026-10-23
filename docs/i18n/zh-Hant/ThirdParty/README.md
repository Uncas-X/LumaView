# 隨附的媒體工具

<!-- doc-navigation:start -->
[文件目錄](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · **繁體中文** · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView 將未修改的 FFmpeg 9.0.2 與 ffprobe 作為獨立的本機程序呼叫。這些工具從原始碼建置，支援 Intel 與 Apple Silicon，目標系統為 macOS 13。它們使用靜態連結的 dav1d 1.5.3 解碼 AV1，動態函式庫僅使用系統提供的版本。執行時不需要 Homebrew 或 VLC。

FFmpeg 以 LGPL 2.1 或更新版本設定，未使用 `--enable-gpl` 或 `--enable-nonfree`。dav1d 採用 BSD 2-Clause 授權。完整授權聲明位於 `Resources/ThirdPartyNotices`，並會複製至應用程式套件。完全相符且未修改的對應原始碼封存檔隨附於 `sources/`，並提供 SHA-256 校驗值。所有設定旗標與建置步驟均在 `tools/build-media-tools.sh` 中。LumaView 不對修改或替換這些獨立工具，或為偵錯此類修改所需的逆向工程施加額外限制。

官方來源：

- [FFmpeg 發行版本與簽章](https://ffmpeg.org/download.html)：`https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`。其分離式簽章已使用 FFmpeg 發行金鑰 `FCF986EA15E6E293A5644F10B4322F04D67658D8` 驗證。
- [dav1d 發行版本](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/)：`dav1d-1.5.3.tar.xz`。
- [FFmpeg 授權資訊](https://ffmpeg.org/legal.html)。

## 重新建置

一般應用程式建置使用隨附的通用二進位檔。若要重新建置這些工具，請安裝 Xcode Command Line Tools、Python 3、Meson 1.12.1 與 Ninja 1.13.2。例如，可使用本機 Python 虛擬環境，並在其中安裝 `meson==1.12.1 ninja==1.13.2`。啟用環境後執行：

```sh
./tools/build-media-tools.sh
./build.sh
```

第一個指令會驗證原始碼校驗值、編譯兩種架構，並替換 `Resources/MediaTools/{ffmpeg,ffprobe}`。使用 `LUMAVIEW_PYTHON` 選擇 Python，使用 `LUMAVIEW_MEDIA_BUILD` 選擇中間建置目錄。參數 `x86_64` 或 `arm64` 只編譯單一架構；預設的 `universal` 會合併兩者。應用程式建置會為內含工具與應用程式加上本機 ad-hoc 簽章。

網路、擷取裝置、ffplay、dav1d 以外的外部編解碼器，以及 GPL 編碼器均已停用。此設定可用的所有內部解碼器與解多工器都包含在內。音訊輸出會準備成 AAC；影片盡可能先重新封裝，再使用 VideoToolbox H.264、MPEG-4 或 ProRes 產生相容輸出。這是供檢視使用的流程，並非匯出或轉碼介面。

## PostScript 向量解譯器

EPS、PostScript 與舊版 Illustrator 預覽還會使用隨附的 Ghostscript 10.08.0，作為獨立且受限制的本機子程序。其 AGPL-3.0-or-later 授權、完整對應原始碼封存檔、校驗值及可重現的通用建置方式，請參閱 [README-Ghostscript.md](README-Ghostscript.md)。一般應用程式建置不需要在系統中安裝 Ghostscript。
