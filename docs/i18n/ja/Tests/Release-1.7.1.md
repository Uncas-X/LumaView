> 過去の検証記録の個人サンプル名は匿名化しています。テストデータと結果はそのままです。

<!-- doc-navigation:start -->
[ドキュメント一覧](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · **日本語** · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# LumaView 1.7.1 検証記録

バージョン 1.7.1、build 13。2026-10-22、macOS 15.7.9 / Intel。アプリと 3 つの内蔵ツールは arm64 + x86_64 構成とローカル署名を確認しました。今回は Apple Silicon 実機では実行していません。

## 原因の特定と修正

ユーザーの 3 つの PSB は、8 ビット RGB、4 チャンネル、合成透明度付き RLE で、約 108–123 MiB でした。大部分は読み飛ばせるレイヤーデータで、メインキャンバスは約 850–960 万ピクセルでした。

1. 旧行単位デコーダーは PackBits の各マーカーと値に FileHandle 読み取りを行い、大量の小さな読み取りがメイン画像とサムネイルのキューを長く占有していました。最大 64 KiB のブロック読み取りへ変更し、ブロックをまたぐ literal/run 状態と境界検査を維持しました。長い no-op もキャンセルできます。ZIP はサンプル対象行だけ予測を復元し、圧縮ストリーム全体の検証は維持します。
2. 3 ファイルすべてにリソース 1036 の有効な RGB JPEG サムネイルがありました。現在はフィルムストリップがこれを優先し、形式、寸法、縦横比、圧縮長を検証します。メイン画像は常に実合成画像をデコードします。無効なプレビュー、旧 BGR リソース、未収録時は合成画像へ戻ります。
3. システム ImageIO は一部の有効な Generic RGB ICC 付き小サイズ PSD 合成データを拒否し、旧版は空サムネイルを返していました。フォールバックではピクセルを別にデコードし、検証済みで色モデル・成分が一致する元 ICC を再付与します。プロファイルを捨てません。原本の ICC は標準 Generic RGB Profile と同一で、新規回帰はシステムプロファイルから素材を生成しました。ユーザーの写真はソースに入れていません。
4. PSB のメイン画像は解析済みヘッダーを再利用し、メタデータ取得のために ImageIO でレイヤーを追加走査しません。元の寸法、透明度、メイン画像品質は保持します。

## 3 つの原本での実測

この Mac のローカル測定であり、システム負荷とファイルキャッシュの影響を受け、全機器の性能保証ではありません。新旧とも最適化コンパイルを使用しました。

| ファイル | 元の寸法 | 旧メイン画像デコード | 新メイン画像デコード | 新合成サムネイルデコード（埋め込みなし経路） |
| --- | --- | --- | --- | --- |
| Sample A | 2582 × 3318 | 15 秒超でテスト側がキャンセル | 0.68 秒 | 0.039 秒 |
| Sample B | 2610 × 3307 | 14.35 秒 | 0.65 秒 | 0.028 秒 |
| Sample C | 2843 × 3361 | 15 秒超でテスト側がキャンセル | 0.70 秒 | 0.028 秒 |

実 ImageLoader で 3 サムネイルを同時要求し、約 0.06 秒で全部完了しました。全メイン画像はローダー経由で約 0.90 / 0.65 / 0.74 秒でした。旧版の 3 合成サムネイルはすべて unsupported、新版はすべて成功しました。原本のバイト列 SHA-256 はテスト前後で一致し、アプリは原本へ書き込みませんでした。

## 今回合格した検査

| 項目 | 結果 |
| --- | --- |
| PSD / PSB 符号化と透明合成 | 712 / 712 |
| RLE 性能、埋め込みプレビュー、ICC、ブロック越え、キャンセル | 54 / 54 |
| 3 つの元 PSB の実 ImageLoader 統合 | 21 / 21 |
| 443 ファイルのフィルムストリップ、キャッシュ、失効コールバック | 37 / 37 |
| 独立したサムネイル要求とキャンセル | 13 / 13 |
| 画像ライブラリとシステムデコード | 78 / 78 |
| インストール済み最適化リリース版の右クリックとコピー | 28 / 28 |
| 合計 | 943 / 943 |

新規テストは密集した 1 バイト literal、64 KiB 境界、長い no-op のキャンセル、切り詰めと範囲外、埋め込みサムネイルとメイン画像それぞれの正しい内容、ICC、透明度、小サイズの非整数縮小を網羅しました。既存の 112 符号化組み合わせと 128 レイヤー透明マーカー付き構造サンプルも引き続き合格しました。サムネイルバー検査は高速切り替え、画面外キャンセル、古いコールバックが現在一覧を汚さないことを確認しました。

正式インストール版と outputs/LumaView.app の全ファイル一覧とハッシュは一致し、両方が codesign --verify --deep --strict に合格しました。導入前に旧版 ZIP を保存し、デフォルトの関連付けは変更しませんでした。配布 ZIP の CRC と版は別途検証します。完全な過去 1.7.0 レポートは Tests/Release-1.7.0.md に残し、再実行しなかった検査は今回に含めません。

メイン実行ファイル SHA-256：`cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`。

## ログ

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
