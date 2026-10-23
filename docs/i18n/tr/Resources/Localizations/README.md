# LumaView arayüz dilleri

<!-- doc-navigation:start -->
[Belgeler](../../INDEX.md) · [简体中文](../../../zh-Hans/Resources/Localizations/README.md) · [繁體中文](../../../zh-Hant/Resources/Localizations/README.md) · [English](../../../en/Resources/Localizations/README.md) · [日本語](../../../ja/Resources/Localizations/README.md) · [한국어](../../../ko/Resources/Localizations/README.md) · [Français](../../../fr/Resources/Localizations/README.md) · [Deutsch](../../../de/Resources/Localizations/README.md) · [Español](../../../es/Resources/Localizations/README.md) · [Italiano](../../../it/Resources/Localizations/README.md) · [Português (Brasil)](../../../pt-BR/Resources/Localizations/README.md) · [Русский](../../../ru/Resources/Localizations/README.md) · [العربية](../../../ar/Resources/Localizations/README.md) · [हिन्दी](../../../hi/Resources/Localizations/README.md) · **Türkçe** · [Nederlands](../../../nl/Resources/Localizations/README.md) · [Polski](../../../pl/Resources/Localizations/README.md)
<!-- doc-navigation:end -->


Uygulama **Sistemi İzle** ile başlar. macOS tercih edilen dil listesindeki ilk desteklenen dili, hiçbiri desteklenmiyorsa İngilizceyi seçer. **LumaView → Dil…** içinden seçilen dil hemen uygulanır ve yalnız bu uygulama için hatırlanır.

Desteklenenler: Basitleştirilmiş Çince, Geleneksel Çince, İngilizce, Japonca, Korece, Fransızca, Almanca, İspanyolca, İtalyanca, Portekizce, Rusça, Arapça, Hintçe, Türkçe, Felemenkçe ve Lehçe. Portekizce çeşitleri şu anda Brezilya Portekizcesi kataloğunu kullanır. Seçicideki yerel dil adları bilinçlidir; kullanıcı yabancı arayüz dilinden geri dönebilir.

`catalog.json`, okunabilir Basitleştirilmiş Çince kaynak anahtarlarını yerelleştirilmiş dizelere eşler. `core-keys.json` her katalogda gerekli ortak denetimleri, menüleri, ayarları, belge gezintisini, metaveri etiketlerini ve klavye yardımını tanımlar. Seyrek tanılar dilde karşılığı yoksa İngilizce yedek kullanır. Dosya, dizin, kodek, biçim ve gömülü kamera metaverisi adları değişmez. Sistem diyaloglarının metnini işletim sistemi kendi dilinde sağlar.

Sabit metinde `L10n.tr("source key")` kullanın. Dinamik metinde Çince dizeyi önce interpolasyonla kurmak yerine `L10n.format("第 %d / %d 页", current, total)` kullanın. Yer tutucu tür ve sayıları çevirilerde tutarlı olmalıdır. Mevcut arayüzü yenilemek ve metni yeniden çizmek için `L10n.languageDidChange` izleyin. Testler kullanıcı dilini değiştirmemek için `useLanguageForTesting` kullanır.

Dil çözümleme, tam temel kapsam, yer tutucu tutarlılığı, yedek davranışı ve Arapça yönü için `Tests/run-localization-tests.sh` çalıştırın. Çeviriler profesyonel dil incelemesinden geçmemiştir.
