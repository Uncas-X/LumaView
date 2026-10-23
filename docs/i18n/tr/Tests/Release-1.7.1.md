> Geçmiş doğrulama kayıtlarındaki kişisel örnek adları anonimleştirilmiştir; test verileri ve sonuçları değişmemiştir.

<!-- doc-navigation:start -->
[Belgeler](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · **Türkçe** · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# LumaView 1.7.1 doğrulama kaydı

Sürüm 1.7.1, build 13. 2026-10-22, macOS 15.7.9 / Intel. Uygulama ve üç yerleşik araç arm64 + x86_64 ve yerel imza kontrolünü geçti; bu tur Apple Silicon donanımında çalıştırılmadı.

## Bulunan ve düzeltilenler

Üç kullanıcı PSB'si 8 bit RGB, 4 kanal, saydam bileşik içeren RLE dosyalarıdır, yaklaşık 108–123 MiB. Hacmin çoğu doğrudan atlanabilen katman verisidir; ana tuval yaklaşık 8.50–9.60 milyon pikseldir.

1. Eski satır çözücü her PackBits işaret/değeri için FileHandle okuması yaparak çok sayıda küçük okuma oluşturuyor, ana ve küçük resim kuyruklarını uzatıyordu. En fazla 64 KiB blok okumaya geçildi; bloklar arası literal/run durumu ve sınır kontrolleri korundu, uzun no-op iptal edilebilir. ZIP yalnız örneklenen satırlarda tahmini geri alır, sıkışmış akışı yine tamamen doğrular.
2. Üç dosyada da kaynak 1036 geçerli RGB JPEG küçük resmi vardır. Şerit artık bunu tercih eder, biçim/boyut/oran/sıkışmış uzunluğu kontrol eder; ana görüntü daima gerçek bileşiği çözer. Geçersiz önizleme, eski BGR kaynağı veya önizleme yokluğunda bileşiğe dönülür.
3. ImageIO bazı geçerli Generic RGB ICC içeren küçük PSD bileşiklerini reddederek eskiden boş küçük resim döndürüyordu. Yedekte pikseller ayrı çözülür; doğrulanmış, model ve bileşeni uyumlu özgün ICC yeniden eklenir, atılmaz. Özgün ICC sistem Generic RGB Profile ile aynıdır; yeni regresyon sistem profiliyle veri üretir, kullanıcı fotoğrafları kaynağa girmez.
4. PSB ana görüntüsü ayrıştırılmış başlığı tekrar kullanır; metaveri için fazladan ImageIO katman taramasından kaçınır. Özgün boyut, saydamlık ve ana görüntü kalitesi korunur.

## Üç özgün dosyanın gerçek testi

Bu Mac'teki yerel ölçümlerdir, sistem yükü ve dosya önbelleğinden etkilenir; tüm cihazlar için performans garantisi değildir. Eski ve yeni çözücü optimize derlenmiştir.

| Dosya | Özgün boyut | Eski ana çözme | Yeni ana çözme | Yeni bileşik küçük resim çözme (gömülü önizlemesiz yol) |
| --- | --- | --- | --- | --- |
| Sample A | 2582 × 3318 | 15 saniyeyi aşınca test iptal edildi | 0.68 saniye | 0.039 saniye |
| Sample B | 2610 × 3307 | 14.35 saniye | 0.65 saniye | 0.028 saniye |
| Sample C | 2843 × 3361 | 15 saniyeyi aşınca test iptal edildi | 0.70 saniye | 0.028 saniye |

Gerçek ImageLoader ile aynı anda istenen üç küçük resim yaklaşık 0.06 saniyede bitti. Tam ana görüntüler yükleyicide yaklaşık 0.90 / 0.65 / 0.74 saniye sürdü. Eski üç bileşik küçük resim unsupported veriyordu; yeniler başarılıdır. Öncesi/sonrası SHA-256 byte düzeyinde aynıdır, uygulama özgünlere yazmadı.

## Bu tur geçen kontroller

| Kontrol | Sonuç |
| --- | --- |
| PSD / PSB kodlama ve saydam bileşik | 712 / 712 |
| RLE performansı, gömülü önizleme, ICC, blok sınırı ve iptal | 54 / 54 |
| Üç özgün PSB ile gerçek ImageLoader entegrasyonu | 21 / 21 |
| 443 dosya şeridi, önbellek, geçersiz geri çağrı | 37 / 37 |
| Bağımsız küçük resim istekleri ve iptal | 13 / 13 |
| Görüntü kitaplığı ve sistem çözme | 78 / 78 |
| Kurulu optimize sürüm sağ tık menüsü ve kopyalama | 28 / 28 |
| Toplam | 943 / 943 |

Yeni testler yoğun tek byte literal, 64 KiB sınırı, uzun no-op iptali, kesilme/sınır aşımı, gömülü küçük resim ve ana görüntünün ayrı doğru içeriği, ICC, saydamlık ve küçük görüntüde tam sayı olmayan ölçeği kapsar. Önceki 112 kodlama birleşimi ve 128 katman saydamlık işaretli yapısal örnek geçmeye devam eder. Şerit kontrolleri hızlı geçiş, ekran dışı iptal ve eski geri çağrının mevcut listeyi kirletmemesini içerir.

Kurulu sürüm ile outputs/LumaView.app dosya listesi/özetleri aynıdır, ikisi codesign --verify --deep --strict geçti. Kurulum öncesi eski ZIP yedeği korundu; varsayılan ilişkiler değişmedi. Teslim ZIP'i ayrıca CRC/sürüm kontrolünden geçer. Tarihsel tam 1.7.0 raporu Tests/Release-1.7.0.md içindedir; tekrarlanmayan kontroller sayılmadı.

Ana program SHA-256: `cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`.

## Günlükler

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
