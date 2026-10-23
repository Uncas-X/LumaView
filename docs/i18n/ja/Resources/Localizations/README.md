# LumaView の表示言語

<!-- doc-navigation:start -->
[ドキュメント一覧](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · **日本語** · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · [Türkçe](../../../tr/Resources/Localizations/README.md) · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


アプリは**システムに従う**設定で起動します。macOS の優先言語一覧の最初の対応言語を選び、なければ英語を使います。**LumaView → 言語…** で選択した言語は即座に反映され、このアプリだけに保存されます。

対応言語：簡体字中国語、繁体字中国語、英語、日本語、韓国語、フランス語、ドイツ語、スペイン語、イタリア語、ポルトガル語、ロシア語、アラビア語、ヒンディー語、トルコ語、オランダ語、ポーランド語。ポルトガル語の各変種は現在ブラジルポルトガル語カタログを使います。選択欄の言語名は、読めない表示言語から戻せるよう、意図的に各言語自身の名前で表示します。

`catalog.json` は読みやすい簡体字中国語ソースキーを翻訳文字列へ対応付けます。`core-keys.json` は全カタログ必須の共通コントロール、メニュー、設定、文書操作、メタデータラベル、キーボードヘルプを定義します。頻度の低い診断は翻訳項目がなければ英語を使います。ファイル、ディレクトリ、コーデック、形式、埋め込みカメラメタデータの名前は不変です。システムダイアログの文言は OS 自身の言語で提供されます。

静的テキストは `L10n.tr("source key")`、動的テキストは `L10n.format("第 %d / %d 页", current, total)` を使い、翻訳前に中国語文字列へ値を埋め込まないでください。プレースホルダーの型と数を各翻訳で揃えます。`L10n.languageDidChange` を監視して既存 UI と描画文字を更新します。テストはユーザーの保存言語を変えないよう `useLanguageForTesting` を使います。

`Tests/run-localization-tests.sh` で言語解決、必須キー全件、書式プレースホルダー整合性、フォールバック、アラビア語の文字方向を検証します。翻訳は専門の言語校閲を受けていません。
