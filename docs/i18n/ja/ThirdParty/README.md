# 同梱のメディアツール

<!-- doc-navigation:start -->
[ドキュメント一覧](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · **日本語** · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView は未変更の FFmpeg 9.0.2 と ffprobe を独立したローカルプロセスとして呼び出します。ソースから Intel / Apple Silicon 向け、macOS 13 対象でビルドしています。AV1 デコードに静的リンクの dav1d 1.5.3 を使い、動的ライブラリはシステムのものだけです。実行時に Homebrew や VLC は不要です。

FFmpeg は LGPL 2.1 以降で設定し、`--enable-gpl` と `--enable-nonfree` は使いません。dav1d は BSD 2-Clause です。完全なライセンス告知は `Resources/ThirdPartyNotices` にあり、アプリバンドルへコピーされます。正確で未変更の対応ソースアーカイブを SHA-256 とともに `sources/` に含めます。全設定フラグと手順は `tools/build-media-tools.sh` にあります。LumaView はこれらの独立ツールの変更・交換や、その変更のデバッグに必要なリバースエンジニアリングに追加制限を課しません。

公式ソース：

- [FFmpeg リリースと署名](https://ffmpeg.org/download.html)：`https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`。分離署名は FFmpeg リリース鍵 `FCF986EA15E6E293A5644F10B4322F04D67658D8` で検証しました。
- [dav1d リリース](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/)：`dav1d-1.5.3.tar.xz`。
- [FFmpeg ライセンス情報](https://ffmpeg.org/legal.html)。

## 再ビルド

通常のアプリビルドは同梱のユニバーサルバイナリを使います。再ビルドには Xcode Command Line Tools、Python 3、Meson 1.12.1、Ninja 1.13.2 を導入します。例えばローカル Python 仮想環境に `meson==1.12.1 ninja==1.13.2` を導入し、有効化してから実行します：

```sh
./tools/build-media-tools.sh
./build.sh
```

最初のコマンドはソースのチェックサムを検証し、両アーキテクチャをコンパイルして `Resources/MediaTools/{ffmpeg,ffprobe}` を置換します。`LUMAVIEW_PYTHON` で Python、`LUMAVIEW_MEDIA_BUILD` で中間ビルドディレクトリを指定します。引数 `x86_64` または `arm64` は単一アーキテクチャ、既定の `universal` は両者を結合します。アプリビルドは内蔵ツールとアプリをローカルのアドホック署名で署名します。

ネットワーク、キャプチャ機器、ffplay、dav1d 以外の外部コーデック、GPL エンコーダーは無効です。この構成で利用可能な内部デコーダー / デマルチプレクサーはすべて含みます。音声出力は AAC に準備します。動画は可能なら再多重化し、その後 VideoToolbox H.264、MPEG-4、ProRes の互換出力を使います。閲覧用の処理であり、書き出しやトランスコード用の UI ではありません。

## PostScript ベクトルインタープリター

EPS、PostScript、旧 Illustrator のプレビューには、同梱 Ghostscript 10.08.0 を独立した制限付きローカル子プロセスとして追加使用します。AGPL-3.0-or-later ライセンス、完全な対応ソース、チェックサム、再現可能なユニバーサルビルドは [README-Ghostscript.md](README-Ghostscript.md) を参照してください。通常のアプリビルドはシステムへの Ghostscript 導入を必要としません。
