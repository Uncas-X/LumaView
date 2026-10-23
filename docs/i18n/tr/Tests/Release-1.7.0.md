> Geçmiş doğrulama kayıtlarındaki kişisel örnek adları anonimleştirilmiştir; test verileri ve sonuçları değişmemiştir.

<!-- doc-navigation:start -->
[Belgeler](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · **Türkçe** · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# LumaView 1.7.0 doğrulama kaydı

Tarih: 2026-10-22 (Asia/Shanghai). Bu turun ortamı macOS 15.7.9, x86_64. Uygulama macOS 13+ hedefler; dört yürütülebilir Intel / Apple Silicon evrenseldir.

## Değişiklikler ve gerçek test sonuçları

- Yerleşik Ghostscript 10.08.0 ile EPS, PostScript ve eski PostScript AI açıldığında yolları, metinleri ve özgün gömülü görüntüleri koruyan PDF arka planda üretilip mevcut tuvale verilir. Kullanıcı yorumlayıcı kurmaz veya elle dönüştürmez; yakınlaştırma, sürükleme, döndürme ve çok sayfalı gezinti aynı kalır. Vektör dönüşümü tamamlanamazsa ve dosyada önizleme varsa gömülü TIFF yedeği kullanılır; raster yedek vektör olarak etiketlenmez.
- Özgün `sample-vector.eps` ekinin tam PostScript içeriği kullanılmıştır. Üretilen PDF taramasında **147,521 yol/gradyan işlemi, 59 metin işlemi, 160 XObject çağrısı** bulundu. XObject sayısı PDF `Do` işlemlerinden gelir, görüntü veya Form olabilir; bağımsız görüntü sayısına eşit değildir. Gerçek vektörün korunduğu doğrulandı; özgün EPS ve `sample-vector.svg` öncesi/sonrası SHA-256 karşılaştırması değişmediklerini gösterdi.
- PostScript ayrı, iptal edilebilir süreç, Ghostscript SAFER ve sistem süreç sanal alanı kullanır. Girdi özel geçici dizine kopyalanır; yorumlayıcı diğer kullanıcı dosyalarını okuyamaz, dışarı keyfî yazamaz veya dış boru kullanamaz. Zaman aşımı, iptal, çok tüketicili paylaşım, bozuk girdi ve önbellek geçersizleştirme geçti. Tamamlanan sonuç atomik yayımlanır, yarım PDF küçük resme konmaz. Gerçek görüntüleyicide EPS 3200% vektör yakınlaştırması, çok sayfalı PS'de yukarı/aşağı odak ve sağ/sol sayfalama, dönüştürme sırasında PNG'ye geçince eski sonucun görüntüyü ezmemesi kontrol edildi.
- Photoshop grubuna `.psb` eklendi; `.psd` ile keşif, ana görüntü, küçük resim ve varsayılan açmaya katılır. Uyumlu bileşik okunur, özgün tuval boyutu korunur; büyük dosya için gösterim gereksinimine göre sınırlı önizleme oluşturulur. **112 kodlama birleşimi, katman saydamlık işaretli 128 yapısal örnek, 1 büyük PSB, 13 bozuk örnek** doğrulandı. Bileşik saydamlık katman sayısı ve Lr16/Lr32, Mtrn/Mt16/Mt32 ile belirlenir; normal ek Alpha bileşik saydamlık sayılmaz. Saydam piksel değerleri, beyaz zemin kaldırma, kodlama tutarlılığı, büyük satır iptali ve ana/küçük görüntü entegrasyonu kapsandı.
- Varsayılan açma penceresi her açılış, yeniden etkinleşme ve toplu işlem sonunda gerçek sistem ilişkilerini okur. İlişkiler yeniden başlatmada korunur; uygulanmamış taslak başarı yerine gösterilmez. Tüm türler mevcut uygulamaya gidiyorsa işaret, yalnız bir kısmıysa veya aynı bundle ID'li başka kopyaysa açıklamalı çizgi görünür. Temizleme yalnız taslağı değiştirir, sistem varsayılanını geri almaz.
- Üst “Tüm biçimleri seç” arama dışındakiler dahil görüntü, vektör/belge, video ve sesi seçer; ilişki yazımı için yine uygulama düğmesine basılır. Algılama, kısmi başarı, hata geri okuma, denetleyici yeniden oluşturma, taslak/gerçek ayrımı ve tümünü seçme bellek mock arka ucuyla doğrulandı; kullanıcının varsayılan uygulamaları değiştirilmedi.
- Yeni ayar, PostScript ve Photoshop metinleri 16 dilin tamamını kapsar; temel metin ve yer tutucu doğrulaması geçti.

## Bu turun doğrulaması

Yalnız aşağıda listelenen ve tam başarı özeti olan bu tur günlükleri sayılır; yeniden çalıştırılmayan geçmiş modüller eklenmez.

| Kontrol | Geçti |
| --- | --- |
| PostScript vektör dönüşümü, iptal, izolasyon ve gerçek EPS | 24 / 24 |
| SVG / EPS uyumluluğu ve özgün ek kontrolü | 64 / 64 |
| PSD / PSB bileşik, saydam kanal, büyük görüntü ve bozuk veri | 712 / 712 |
| Sistem varsayılanı okuma ve toplu ayar (mock) | 101 / 101 |
| Biçim penceresi, yeniden açılış durumu ve tümünü seçme (mock) | 34 / 34 |
| 16 dil ve yer tutucular | 174 / 174 |
| Sürüm uygulaması biçim bildirimleri | 15 / 15 |
| Görüntü kitaplığı ve sistem çözme | 78 / 78 |
| Tuval geometrisi, animasyon ve fare | 66 / 66 |
| Belge ayrıştırma ve tam sayfa çizimi | 56 / 56 |
| Belge odağı, EPS / PS ölçek/sayfalama ve dosya değişiminde iptal | 75 / 75 |
| Gerçek pencere tıklamaları ve yaşam döngüsü | 65 / 65 |
| 443 dosya küçük resmi, önbellek ve eski geri çağrılar | 37 / 37 |
| Küçük resim iptali ve tüketici izolasyonu | 13 / 13 |
| Kurulu sürüm sağ tık menüsü ve özel pano | 28 / 28 |
| **Toplam** | **1542 / 1542** |

Kurulu optimize sürümde gerçek menü ve target/action dağıtımıyla, ayrı adlandırılmış pano kullanarak 28 ek sağ tık kontrolü yapıldı. Görüntü, geçerli video karesi, PDF görüntüsü ve tam sayfa kopyalama; dönüş ve değiştirme/kapatmada eski sonuç yönetimi doğrulandı. Kullanıcının sistem panosu ezilmedi. Fare, pencere yaşam döngüsü, sayfa odağı, tam sayfa sunumu, küçük resim önbelleği ve iptal regresyonları geçti.

## Dağıtım ve kurulu sürüm kontrolü

Sürüm **1.7.0, build 12**. Rapor öncesi `outputs/LumaView.app` ve `/Applications/LumaView.app` bundle ID, sürüm, build, tam dosya listesi ve SHA-256 karşılaştırıldı, içerikler aynıydı. Dört yürütülebilir çift mimari kontrolünü, iki uygulama `codesign --verify --deep --strict` kontrolünü geçti. Ghostscript kendisini 10.08.0 olarak bildirdi; yerelleştirme ve sürüm kaynakları kaynak diziniyle, Ghostscript arşivinin SHA-256 özeti ekli listeyle eşleşti. Derleme yorumlayıcıyı yeniden imzaladığından imzalı ikilinin kaynak dizinindeki yeniden imzalanmamış kopyayla byte düzeyinde aynı olması gerekmez.

| Yürütülebilir | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

Rapor sonraki ZIP bütünlük kontrolünün yerine geçmez, Apple noter onayı iddiası taşımaz. İmza yerel geçicidir; Apple Silicon çapraz derleme ve mimari kontrolü yapılmıştır, bu tur donanımında çalıştırılmamıştır. Ghostscript kaynak arşivi, lisansları ve yeniden derleme açıklaması kaynakla teslim edilir.

## Kapsam ve sınırlar

EPS / PS içindeki rasterler özgün çözünürlüğe bağlı kalır; dış yazı tipi/dosya kaynakları, özel veya bozuk PostScript tam dönüştürülemeyebilir. PSD / PSB önizlemesi uyumlu bileşiğe bağlıdır; Photoshop katmanı düzenlemez veya eksik bileşiği yeniden kurmaz. Eksikse “Uyumluluğu En Üst Düzeye Çıkar” ile yeniden kaydetme istenir. Özgün tuval önizlemeden büyük olabilir; sınırlı önizleme tüm kaynak piksellerinin çözüldüğü şeklinde sunulmaz. Diğer sınırlar [FORMATS.md](../FORMATS.md) içindedir.

## Bu turun günlük kaynakları

Aşağıdaki dosyalar `Tests/` altına kopyalandı; yeniden çalıştırılmayan tarihsel raporlar korunur ama bu toplama katılmaz:

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
