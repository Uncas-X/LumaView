> 過去の検証記録の個人サンプル名は匿名化しています。テストデータと結果はそのままです。

<!-- doc-navigation:start -->
[ドキュメント一覧](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · **日本語** · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# LumaView 1.7.0 検証記録

日付：2026-10-22（Asia/Shanghai）。今回の実行環境：macOS 15.7.9、x86_64。アプリの対象は macOS 13+、4 つの実行ファイルすべてが Intel / Apple Silicon ユニバーサル版です。

## 今回の変更と実測結果

- Ghostscript 10.08.0 を内蔵しました。EPS、PostScript、旧 PostScript AI を直接開くと、ベクトルパス、文字、元の埋め込み画像を保持する PDF を背景生成し、既存キャンバスへ渡します。別のインタープリター導入や手動変換は不要です。ズーム、ドラッグ、回転、複数ページ操作は従来どおりです。ベクトル変換できずファイルにプレビューがある場合は埋め込み TIFF へフォールバックし、ラスターをベクトルと表示しません。
- 実際の元添付 `sample-vector.eps` は完全な PostScript 内容を使うことを確認しました。生成 PDF の走査は **147,521 回のパス / グラデーション関連操作、59 回の文字操作、160 回の XObject 呼び出し**を検出しました。XObject は PDF `Do` 操作数で、画像または Form を含むため独立画像枚数と同じではありません。実際のベクトル保持を確認し、元 EPS と `sample-vector.svg` はテスト前後の SHA-256 が一致して変更されていません。
- PostScript はキャンセル可能な独立プロセス、Ghostscript SAFER、システムプロセスサンドボックスを使います。入力を専用一時ディレクトリへコピーし、ユーザーの他ファイルの読み取り、任意の外部書き込み、外部パイプを禁止します。タイムアウト、キャンセル、複数消費者の再利用、破損入力、キャッシュ無効化を検査しました。完成結果を原子的に公開し、途中の PDF でサムネイルを埋めません。実ビューアで EPS の 3200% ベクトルズーム、複数ページ PS の上下フォーカス / 左右ページ操作、変換中に PNG へ切り替えた後に古い結果が画面を上書きしないことを検証しました。
- Photoshop グループに `.psb` を追加し、`.psd` と同様にファイル検出、メイン画像、サムネイル、デフォルト設定の対象にしました。互換合成画像を読み、元のキャンバス寸法を保持し、大ファイルは表示要求に応じた制限付きプレビューを生成します。**112 の符号化組み合わせ、128 のレイヤー透明マーカー付き構造サンプル、1 個の大きな PSB、13 個の破損サンプル**を検証しました。合成透明度はレイヤー数と Lr16/Lr32、Mtrn/Mt16/Mt32 で識別し、通常の追加 Alpha を誤認しません。透明ピクセル値、白マット除去、符号化間整合性、大行キャンセル、メイン画像 / サムネイル統合回帰を含みます。
- デフォルト設定ダイアログを開くたび、アプリ再アクティブ化時、一括設定完了時にシステムの実際の関連付けを取得します。関連付けは再起動後も保持し、未適用の下書きを成功結果としません。グループの全タイプが現在のアプリならチェック、一部のみ、または同じ bundle ID の別コピーなら横線と説明を表示します。クリアは下書きだけを変え、システム関連付けを解除しません。
- 上の「すべての形式を選択」は検索外を含む画像、ベクトル / 文書、動画、音声を一括選択します。実際の関連付け書き込みには設定ボタンが必要です。検出、一部成功、失敗の読み戻し、コントローラー再作成、下書きと実状態の区別、全選択をメモリ上の mock バックエンドで検証し、ユーザーのシステム既定アプリは変更していません。
- 今回追加した設定、PostScript、Photoshop 文言は全 16 言語を網羅し、必須文言と書式プレースホルダー検証に合格しました。

## 今回の検証

下記の完全な成功集計がある今回のログだけを数えます。再実行していない過去のモジュールは含めません。

| 検査 | 合格 |
| --- | --- |
| PostScript ベクトル変換、キャンセル、隔離、実 EPS | 24 / 24 |
| SVG / EPS 互換性と元添付の検証 | 64 / 64 |
| PSD / PSB 合成画像、透明チャンネル、大画像、破損データ | 712 / 712 |
| デフォルトアプリのシステム読み戻しと一括設定（mock） | 101 / 101 |
| デフォルト形式ダイアログ、再開状態、全形式選択（mock） | 34 / 34 |
| 16 言語とプレースホルダー | 174 / 174 |
| リリースアプリの形式宣言 | 15 / 15 |
| 画像ライブラリとシステムデコード | 78 / 78 |
| キャンバス幾何、アニメーション、マウス | 66 / 66 |
| 文書解析とページ全体描画 | 56 / 56 |
| 文書フォーカス、EPS / PS ズーム・ページ操作、切り替えキャンセル | 75 / 75 |
| 実ウィンドウのクリックとライフサイクル | 65 / 65 |
| 443 ファイルのサムネイル、キャッシュ、期限切れコールバック | 37 / 37 |
| サムネイル要求のキャンセルと消費者隔離 | 13 / 13 |
| 正式インストール版の右クリックと私有クリップボード | 28 / 28 |
| **合計** | **1542 / 1542** |

正式インストールした最適化リリース版では、実メニューと target/action 配送、独立した名前付きクリップボードで 28 件の右クリック検査も行いました。画像、動画現在フレーム、PDF 内画像と全ページ、回転、切り替え / 終了時の古い結果処理を検証しました。ユーザーのシステムクリップボードは上書きしていません。既存のマウスクリック、ウィンドウライフサイクル、ページフォーカス、完全ページ表示、サムネイルキャッシュとキャンセル回帰も合格しました。

## リリースディレクトリとインストール版の確認

バージョン **1.7.0、build 12**。レポート作成前に `outputs/LumaView.app` と `/Applications/LumaView.app` の bundle ID、版、build、全ファイル一覧、SHA-256 を照合し、内容は一致しました。4 実行ファイルは両アーキテクチャ検査、両アプリは `codesign --verify --deep --strict` に合格しました。内蔵 Ghostscript は 10.08.0 を報告し、翻訳・版リソースはソースディレクトリと一致し、Ghostscript ソースアーカイブ SHA-256 も同梱一覧と一致しました。ビルド時にインタープリターを再署名するため、署名後バイナリとソース内の未再署名コピーのバイト一致は要求しません。

| 実行ファイル | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

この報告は後から生成する ZIP の整合性検査に代わるものではなく、Apple 公証済みともしていません。署名はローカルのアドホック署名です。Apple Silicon はクロスコンパイルと構成検査を実施しましたが、今回は実機実行していません。Ghostscript ソースアーカイブ、ライセンス、再ビルド手順をソースとともに配布します。

## 範囲と境界

EPS / PS に元から埋め込まれたビットマップはその解像度に制限されます。外部フォントやファイル資源、特殊 / 破損 PostScript の完全変換は保証しません。PSD / PSB はファイルの互換合成画像に依存し、Photoshop レイヤー編集や欠落合成画像の再構築はしません。欠落時は「互換性を優先」を有効にして再保存するよう案内します。元キャンバスは表示プレビューより大きい場合があり、制限付きプレビューを全元ピクセルの完全デコードとは称しません。他の制限は [FORMATS.md](../FORMATS.md) を参照してください。

## 今回のログの出所

以下を `Tests/` へコピーしました。再実行しない過去レポートも保持しますが、今回の合計には含めません：

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
