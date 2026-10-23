# LumaView 1.7.2 検証記録

<!-- doc-navigation:start -->
[ドキュメント一覧](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · [繁體中文](../zh-Hant/TEST-RESULTS.md) · [English](../en/TEST-RESULTS.md) · **日本語** · [한국어](../ko/TEST-RESULTS.md) · [Français](../fr/TEST-RESULTS.md) · [Deutsch](../de/TEST-RESULTS.md) · [Español](../es/TEST-RESULTS.md) · [Italiano](../it/TEST-RESULTS.md) · [Português (Brasil)](../pt-BR/TEST-RESULTS.md) · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · [Türkçe](../tr/TEST-RESULTS.md) · [Nederlands](../nl/TEST-RESULTS.md) · [Polski](../pl/TEST-RESULTS.md)
<!-- doc-navigation:end -->


バージョン 1.7.2、build 14。2026-10-22、macOS 15.7.9 / Intel。アプリと内蔵ツールは arm64 + x86_64 のユニバーサル構成とローカル署名を検証済みです。今回は Apple Silicon 実機では実行していません。

## 今回の修正

ラスター画像の透明領域を統一して直接透過表示します。PNG / GIF / PSD / PSB などに市松模様やキャンバスの長方形枠を重ねません。影は画像キャンバス全体ではなく、現在の画面の実際の合成透明度から作ります。透明な余白には長方形の影が付かず、穴、独立ソフトマスク、半透明部分が実際の輪郭に反映されます。

以前は CGImage.alphaInfo だけで市松模様を追加し、独立した Quartz mask を持つ PSB を見落としていました。またズームごとに長方形の shadowPath を強制設定し、枠自体も長方形の影を作っていました。現在はこれらの原因を除き、レイヤーの影を合成 alpha から自動形成します。描画書き出しも画像自体に影を付け、長方形を事前充填しません。GIF / APNG は引き続き現在のテクスチャをフレームごとに交換し、影も更新します。毎フレーム透明ピクセルを走査したり、追加の全体 RGBA 画像を作ったりする必要はありません。

文書の白い紙面と動画の長方形表面は従来どおりです。画像コピーは元のピクセルを使い、閲覧背景、市松模様、表示用の影を含みません。PSB デコーダー、サムネイルのスケジューリング、前版の高速プレビューは変更していません。

## 今回の検証

| 項目 | 合格 |
| --- | --- |
| 透明領域、輪郭の影、フレーム変更 | 133 / 133 |
| キャンバスの幾何、アニメーション、マウス | 66 / 66 |
| 文書解析とページ全体の描画 | 56 / 56 |
| 正式インストール版の文書、EPS / PS のズーム・ページ操作・フォーカス | 75 / 75 |
| 正式インストール版の右クリックメニューとコピー | 28 / 28 |
| 合計 | 358 / 358 |

透明性テストは穴、不規則な突出部、大きな透明余白を持つ同じ図形を、RGBA、独立 Quartz mask、実際に符号化・デコードした PNG、GIF、PSD、PSB で使用しました。CALayer 合成と draw 書き出しのピクセルを調べ、透明縁に長方形の下地 / 影がなく、内外輪郭に影があることを確認しました。全透明画像、フレーム変更、回転・ズーム、高速切り替え、半透明の閲覧背景も対象です。書き出した PNG は目視でも確認しました。

上記 6 種の入力について CALayer 書き出しと PNG draw 書き出しの PNG SHA-256 はすべて一致しました：`578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`。素材はコード生成で、ユーザーの写真をソースへ追加していません。

制限付きソフトウェア描画プローブも実施しました。32 MP ビットマップ、16,384 × 7,812 と 300,000 × 128 の論理キャンバスで、ウィンドウに合わせる、100%、3200% の各状態で新旧の影を比較しました。テストプロセスのピーク RSS は約 428 MiB、描画時間は新旧で同程度です。これは CALayer.render(in:) のソフトウェアスナップショット費用であり、GPU フレームレートの結論ではありません。この結果を理由にレイヤーのラスターキャッシュを追加していません。

正式インストール版と outputs/LumaView.app は全ファイル一覧とハッシュが一致し、両方で codesign --verify --deep --strict に合格しました。インストール前に旧版 ZIP を保存し、デフォルトの関連付けを前後で読み戻して確認しました。配布 ZIP はその後 CRC と版を検証しました。過去レポートは Tests/Release-1.7.0.md と Tests/Release-1.7.1.md に保存しています。再実行していない旧版の検査は今回の件数に含めません。

メイン実行ファイル SHA-256：`b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`。

## ログの出所

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
