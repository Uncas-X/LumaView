# Ghostscript 文書変換ツール

<!-- doc-navigation:start -->
[ドキュメント一覧](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · **日本語** · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView は Artifex が 2026-09-08 に公開した Ghostscript **10.08.0** を独立したローカル実行ファイルとして呼び出し、EPS と PostScript を一時 PDF に変換します。PDF は対応するベクトルパス、文字、グラデーションを保持します。元からラスターで埋め込まれた画像はラスターのままです。Ghostscript は Swift アプリにリンクせず、この同梱実行ファイルの実行に Homebrew は不要です。

## ライセンスと対応ソース

Ghostscript は本リリースの元の `LICENSE` が定める **GNU Affero General Public License バージョン 3 以降** で配布します。完全なライセンス、Ghostscript 著作権表示、フォント埋め込み例外、Adobe CMap 告知、依存物の告知を未変更のまま `Resources/ThirdPartyNotices/Ghostscript/` にコピーしています。Artifex は別途商用ライセンスも提供しますが、このパッケージには含めません。[公式ライセンスページ](https://www.ghostscript.com/licensing/index.html)を参照してください。

同梱依存物とフォントのソースを含む、正確で未変更の対応ソースリリースは `ThirdParty/sources/ghostscript-10.08.0.tar.xz` にあります。SHA-256 は `ThirdParty/sources/SHA256SUMS-Ghostscript` に記録しています：

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

ソースの出所：[公式リリースページ](https://www.ghostscript.com/releases/index.html)と [Artifex の 10.08.0 リリース資産](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080)。チェックサムは `.tar.xz` 資産の公開値と一致します。ソースパッケージとこのビルドスクリプトは LumaView ソース配布に同梱します。LumaView はこの独立ツールの変更・交換や、そのデバッグに必要なリバースエンジニアリングに追加制限を課しません。これらは同梱第三者部品の告知であり、アプリのソースを再ライセンスするものではありません。

## 再ビルド

必要なもの：macOS、Xcode Command Line Tools、同梱ソースアーカイブ、標準 macOS ビルドツール。Homebrew ライブラリは使いません。LumaView のソースディレクトリで実行します：

```sh
./tools/build-document-tools.sh
./build.sh
```

スクリプトはソースアーカイブを検証し、別々のソースディレクトリで Intel と Apple Silicon のスライスをビルドし、ローカルシンボルを除去して `Resources/DocumentTools/gs` に結合します。両方とも macOS 13.0 以降を対象にします。`make install` を実行せず、システムのパッケージマネージャーへ書き込みません。`LUMAVIEW_DOCUMENT_BUILD` は中間ディレクトリ、`LUMAVIEW_DOCUMENT_JOBS` は make 並列数（既定 4）です。任意の引数 `x86_64` / `arm64` は一方だけをビルドします。アプリビルドはコピーした実行ファイルをアプリと一緒に署名します。

実行ファイルの内部 `%rom%` ファイルシステムに初期化コード、同梱フォント、Adobe CMaps、ICC プロファイルを収録します。外部の既定検索パスは空です。出力装置は `pdfwrite` のみを有効にします。印刷/CUPS、X11、GTK、fontconfig、D-Bus、Tesseract/OCR、動的ドライバー、外部 IJS、文書抽出ツールは無効です。同梱デコーダー / 色 / フォントライブラリはすべて対応ソースからコンパイルし、動的リンクは Apple システムライブラリに限定します。ROM とクロスコンパイルの仕組みは[公式ビルド文書](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html)を参照してください。

LumaView は `-dSAFER`、指定入力・出力、専用一時作業ディレクトリ、キャンセル、タイムアウト付きで実行します。プロセス環境はユーザー指定の Ghostscript オプションやライブラリパスを継承してはいけません。信頼できる生成テスト素材の例：

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

全ビルドオプションは `tools/build-document-tools.sh` にあり、ソースアーカイブにパッチは適用していません。ネイティブ実行のテストはビルドホストが対応するアーキテクチャのみ可能です。リリース検査は両 Mach-O スライスを検査し、パスと文字を持つ生成 EPS をホスト対応スライスで処理し、PDF 出力にベクトル描画と文字演算子が残ることを確認します。
