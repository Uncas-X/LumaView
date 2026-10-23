Ghostscript 10.08.0（2026-09-08）

<!-- doc-navigation:start -->
[ドキュメント一覧](../../../INDEX.md) · [简体中文](../../../../zh-Hans/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [繁體中文](../../../../zh-Hant/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [English](../../../../en/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · **日本語** · [한국어](../../../../ko/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [Français](../../../../fr/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [Deutsch](../../../../de/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [Español](../../../../es/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [Italiano](../../../../it/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [Português (Brasil)](../../../../pt-BR/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [Русский](../../../../ru/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [العربية](../../../../ar/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [हिन्दी](../../../../hi/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [Türkçe](../../../../tr/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [Nederlands](../../../../nl/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md) · [Polski](../../../../pl/Resources/ThirdPartyNotices/Ghostscript/NOTICE.txt.md)
<!-- doc-navigation:end -->

Copyright (C) 2026 Artifex Software, Inc. すべての権利を留保します。

この独立実行ファイルは GNU AGPL バージョン 3 以降で提供し、
無保証です。Ghostscript-LICENSE.txt と AGPL-3.0.txt を参照してください。ソース
リリースのフォント埋め込み例外は Ghostscript-LICENSE.txt に保持しています。
完全で未変更の対応ソースリリースとビルドスクリプトを
同梱の LumaView ソースパッケージに含みます：

  ThirdParty/sources/ghostscript-10.08.0.tar.xz
  ThirdParty/sources/SHA256SUMS-Ghostscript
  ThirdParty/README-Ghostscript.md
  tools/build-document-tools.sh

ソース SHA-256：
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf

公式ソース：
https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080

このソフトウェアは一部 Independent JPEG Group の成果に基づきます。
FreeType ライブラリを使用しています。同梱の FreeType 告知を参照してください。
同梱ソース依存物は zlib、Brotli、Little CMS、JBIG2dec、
OpenJPEG、libtiff、libpng を含みます。元のライセンス告知は
このディレクトリに複製しています。Adobe CMap 著作権と再配布告知は
Adobe-CMap-Copyrights.txt に保持し、元の各ファイルの告知も
対応ソースアーカイブに残っています。

インタープリターは独立プロセスとして呼び出します。ビルドは内部
ROM リソースとシステム libSystem のみを使い、別の
Ghostscript、fontconfig、Homebrew 導入は不要です。ソースへのパッチは
適用していません。全設定オプションは同梱ビルドスクリプトにあります。
