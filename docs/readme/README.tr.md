# LumaView 1.7.2

<!-- doc-navigation:start -->
[Belgeler](../i18n/tr/INDEX.md) · [简体中文](../i18n/zh-Hans/README.md) · [繁體中文](../i18n/zh-Hant/README.md) · [English](../i18n/en/README.md) · [日本語](../i18n/ja/README.md) · [한국어](../i18n/ko/README.md) · [Français](../i18n/fr/README.md) · [Deutsch](../i18n/de/README.md) · [Español](../i18n/es/README.md) · [Italiano](../i18n/it/README.md) · [Português (Brasil)](../i18n/pt-BR/README.md) · [Русский](../i18n/ru/README.md) · [العربية](../i18n/ar/README.md) · [हिन्दी](../i18n/hi/README.md) · **Türkçe** · [Nederlands](../i18n/nl/README.md) · [Polski](../i18n/pl/README.md)
<!-- doc-navigation:end -->


**[macOS uygulamasını indir](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)** · [Sürümler ve değişiklikler](https://github.com/Uncas-X/LumaView/releases)

macOS 13+ gerekir; aynı paket Intel ve Apple Silicon ile uyumludur. ZIP'i indirip açın, ardından `LumaView.app` dosyasını Uygulamalar'a sürükleyin.

Picasa Photo Viewer'ın hızlı görüntüleme alışkanlıklarından esinlenen yerel bir macOS medya görüntüleyicisi: aynı klasörde gezinme, yakınlaştırma, sürükleme, döndürme, film şeridi, tam ekran ve slayt gösterisi sunar. 1.5; ses kapakları ve gerçek dalga biçimleri, çok sayfalı belge gezintisi, ölçeğe göre yeniden çizilen vektör tuvali ve varsayılan olarak sistemi izleyen çok dilli ayarlar ekledi. Kendi adı ve özgün simgesi kullanılır; eski Picasa'nın tüm işlev ve etkileşimleriyle birebir aynı olduğu ileri sürülmez.

1.7.2 saydam görüntü alanlarını birleştirir: PNG, GIF, PSD / PSB gibi raster görüntüler mevcut görüntüleme arka planını doğrudan gösterir; gölge gerçek görüntü konturu ve saydamlığına uyar. Gri-beyaz dama veya tüm saydam tuvalin dikdörtgen gölgesi artık gösterilmez. PDF gibi belgeler beyaz kâğıt üzerinde kalır.

1.7.1'in PSD / PSB önizleme iyileştirmeleri korunur: film şeridi önce geçerli gömülü JPEG'i okur, ana görüntü gerçek uyumlu bileşik görüntüyü çözer; RLE bloklar halinde okunur. Bazı ICC profilli küçük bileşiklerden küçük resim üretilememe sorunu da giderilmiştir.

## Kullanım ve kurulum

macOS 13 veya sonrası gerekir; Intel ve Apple Silicon desteklenir.

1. [Releases](https://github.com/Uncas-X/LumaView/releases) üzerinden `LumaView-macOS.zip` dosyasını indirip açın; `LumaView.app` dosyasını Uygulamalar'a sürükleyip çalıştırın.
2. Görüntü, video, ses veya klasör sürükleyin ya da `⌘O` ile dosya seçin. Tek dosya açılınca aynı klasördeki medyalar listelenir; çoklu seçimde yalnız seçilen dosyalarda gezinilir. Klasörün yalnız mevcut düzeyi taranır, alt klasörlere inilmez.
3. Finder'da dosyaya sağ tıklayıp “Birlikte Aç → LumaView” da seçebilirsiniz.

Yerel derleme geçici imza kullanır, Apple noter onayı yoktur. Başka bir Mac'te Gatekeeper indirilen kopyayı engellerse kaynağı doğruladıktan sonra sistemin “Gizlilik ve Güvenlik” ayarındaki açmaya izin verme seçeneğini kullanabilirsiniz.

## Varsayılan açma uygulaması

**LumaView → Varsayılan Açma Uygulaması…** seçin, `⌘,` basın veya “Daha Fazla” menüsünden ayarlara girin. Biçimler görüntü, vektör / belge, video ve ses olarak gruplanır; arayıp işaretledikten sonra “Seçilen biçimler için varsayılan uygulama yap” düğmesine basın. Pencere her açıldığında, uygulama yeniden etkinleştiğinde ve işlem tamamlandığında gerçek sistem ilişkileri okunur: onay işareti grubun tamamının mevcut LumaView ile açıldığını, çizgi bazı türlerin ilişkili olduğunu veya başka bir kopyaya yöneldiğini gösterir. Sistem ilişkileri yeniden başlatmalarda korunur; uygulanmamış geçici seçimler başarıyla ayarlanmış gibi gösterilmez. Üstteki “Tüm biçimleri seç” aramadan bağımsız olarak görüntü, vektör belge, video ve sesin tamamını kapsar; kategori içinde ayrı toplu seçim de vardır. Temizleme yalnız mevcut seçimi kaldırır, var olan sistem varsayılanlarını kaldırmaz.

İşlem ilerlemeyi gösterir ve her sistem sonucunu yeniden okur. İptal sonraki ayarlamaları durdurur; tamamlanan değişiklikler korunur. Biçim listesi seçilebilir dosya ilişkilerini belirtir, her iç kodlamanın veya her dosyanın test edildiğini göstermez; kapsam için [Biçimler ve önizleme](../i18n/tr/FORMATS.md) belgesine bakın.

## Görüntüleme ve oynatma

İlk dosya açılışında pencere mevcut ekranın kullanılabilir alanına genişler; `F` tam ekranı açar. Alt film şeridiyle doğrudan dosya değiştirilebilir. Fare bir süre görüntü alanında kalınca araç çubuğu gizlenir; fareyi hareket ettirince görünür.

1.5.2, büyük klasörlerde uzun gezinme sonrası boş veya sürekli yanıp sönen küçük resimleri düzeltti: görünür küçük resimler ayrıca tutulur, ekran dışı yüklemeler zamanında iptal edilir, eski klasör sonuçları yeni listeye yazılmaz. Çözülemeyen dosyalar sabit bir yer tutucu gösterir; ilgili aralığa yeniden gelindiğinde tekrar denenebilir.

Görüntü ve videolar yakınlaştırılabilir, sürüklenebilir, döndürülebilir ve tam ekrana alınabilir. Pencere, görüntü değiştirme, yakınlaştırma ve döndürme kısa yumuşak geçişler kullanır; ardışık işlemler geçişi kesebilir. Sistem “Hareketi Azalt” açıkken özel geçişler kapatılır; hareketli görüntüler normal oynar. Varsayılan arka plan yarı saydam buzlu camdır; boşluk tuşu buzlu cam, koyu ve açık arka planlar arasında geçer.

Raster saydamlığı tek kurala uyar: mevcut arka plan görünür, gölge yalnız içerikli pikselleri izler, yarı saydam kenarlar saydamlıklarını korur. GIF / APNG oynarken gölge her kareyle değişir. Kopyalanan görüntü özgün saydam piksellerini korur, görüntüleyici arka planı veya gölgesi eklenmez.

Ses/video oynatma, durdurma, ilerleme ve ses düzeyi denetimleri film şeridinin üstündedir. Açılınca otomatik oynar, bitince sonda kalır; `P` yeniden oynatır, `S` durdurup başa döndürür. Alttaki slayt gösterisi düğmesi medya oynatmadan ayrıdır: `⌘4` ile sürekli oynatma açıldığında görüntüler ayarlanan aralıkta, ses/video ise bitince değiştirilir. Tek başına ses/video oynatmak sonraki dosyaya otomatik geçmez.

Önce macOS'un yerel oynatıcısı kullanılır. Sistem doğrudan oynatamıyorsa yerleşik evrensel FFmpeg 9.0.2 ve dav1d 1.5.3 yerelde uyumlu dosya hazırlar; uygun olduğunda önce kapsayıcı değiştirilir, sonra yeniden kodlama denenir. Ek oynatıcı, Homebrew veya kodek paketi gerekmez, ağa erişilmez. Uyumlu oynatma tüm dosyanın hazırlanmasını bekler ve ilerleme gösterir; dosya değiştirmek veya pencereyi kapatmak hazırlığı iptal eder. Uzun videonun ilk hazırlığı uzun sürebilir ve ek disk alanı gerektirebilir.

`C` veya “Daha Fazla” menüsü; döngüsel gezinme, tekerlek davranışı, arka planla kapatma, film şeridi, sıralama ve slayt aralığını (2, 3, 5, 8, 10 saniye) ayarlar. Tekerlek varsayılan olarak yakınlaştırır; `Ctrl` basılıyken geçici olarak dosyalar arasında gezinir. Varsayılan gezinmeyse `Ctrl` geçici yakınlaştırır. “Görüntü dışındaki arka plana tıklayarak kapat” varsayılan açıktır. Tercihler yerelde saklanır.

## Sağ tık menüsü ve kopyalama

Ana görüntüye sağ tıklayın (veya Ctrl-tıklayın): “Birlikte Aç → Uygulama / Diğer Uygulama…” ya da “Finder'da Göster” seçebilirsiniz. Birlikte Aç yalnız bu açılışa uygulanır, varsayılan ilişkiyi değiştirmez; çözülemeyen dosyalarda da bu seçenekler kullanılabilir.

- Görüntü: “Görüntüyü Kopyala”. Mevcut görünümün dönüşünü ve saydam pikselleri koruyarak çözülen görüntünün tamamını kopyalar; araç çubuğunu veya yakınlaştırılmış ekran kesitini yakalamaz.
- Video: “Geçerli Kareyi Kopyala”. Sağ tık menüsünün açıldığı andaki kareyi kopyalar; video yönünü ve görünüm dönüşünü korur, oynatma konumunu veya durumunu değiştirmez.
- PDF / PDF uyumlu AI: sayfadaki raster görüntüye sağ tıklayarak “Bu Görüntüyü Kopyala” veya “Geçerli Sayfayı Kopyala” seçilebilir. Yakınlaştırma, sürükleme ve dönüşten sonra gerçek tıklama konumu esas alınır. Normal metin ve vektör alanları görüntü sayılmaz; karmaşık maske veya renk uzayında o bölgenin görünen sonucu kopyalanır ve üstteki metni içerebilir. Tek görüntü olarak taranmış sayfa tüm tarama olarak kopyalanır.
- `⌘C` geçerli görüntüyü, video karesini veya belge sayfasını kopyalar; ses için görüntü kopyalama yoktur. Panoya PNG ve TIFF sunulur; dosya / sayfa değiştirme veya kapatma sonrasında eski kopyalama sonucu panoyu ezmez.

Belge ve gömülü görüntü kopyalama, uzun kenarı en fazla 8192 piksel ve yaklaşık 32 milyon piksel olan raster üretir; PDF/SVG vektör komutlarını panoya yazmaz. Büyük görüntü sınırlı önizlemeyle gösteriliyorsa kopyalanan bu önizlemedir. PDF görüntü taramasının karmaşıklık sınırı vardır; desen dolgularındaki görüntüler gibi özel yapılar ayrı seçilemeyebilir, ancak geçerli sayfa kopyalanabilir.

Standart SVG 1.0/1.1 başlıkları dış DTD yüklemeden çevrimdışı ayrıştırılır. 1.7'de yerleşik Ghostscript 10.08.0; EPS / PostScript ve eski PostScript AI dosyalarını yolları, metinleri ve gömülü görüntüleri koruyan PDF'ye dönüştürür; ana görünüm ölçeğe göre vektörü yeniden çizer. Çok sayfalı PS mevcut sayfa gezintisini kullanır. Ek yazılım kurulmaz. Dönüştürme başarısızsa geçerli gömülü TIFF içeren EPS, açıkça TIFF etiketli önizlemeye dönebilir. Özgün dosyadaki rasterler vektöre dönüşmez.

## Ses, belgeler ve dil

Ses dosyasında gömülü kapak varsa ana görünüm onu tercih eder; yoksa gerçek örnekler eşzamansız analiz edilir ve tüm sesin dalga biçimi gösterilir. Analiz sırasında yer tutucu görünür, oynatma dalganın tamamlanmasını beklemez. Ses ve video film şeridinin sağ altında aynı yazı tipi, zemin ve konumda `▶ Süre` görünür; henüz okunmadıysa `▶ –:––` gösterilir. Kapak yalnız gömülü metaveriden alınır; ağda veya aynı klasörde aranmaz.

PDF, PDF uyumlu AI ve çok sayfalı TIFF iç sayfa gezinmesini destekler. Daha küçük sayfa küçük resimleri, sayfa ilerleme çubuğu ve geçerli / toplam sayfa sayısı dosya şeridinin üstündedir. `↑` sayfalara, `↓` dosyalara odaklanır; etkin katmanın seçili küçük resmi turuncu, diğer katmanın seçimi gri çerçevelidir. Ek “Sayfalar / Dosyalar” etiketi yoktur. `←` / `→`, `J` / `K` ve `Home` / `End` mevcut odağı yönetir. Katmana tıklamak da odağı oraya taşır. İlk ve son sayfada gezinme durur, başka dosyaya yanlışlıkla geçmez. Alt önceki / sonraki dosya düğmeleri her zaman dosya değiştirir. Dosya şeridi gizlenince sayfa gezintisi kalır.

PDF, SVG ve PDF uyumlu AI, sabit önizlemeyi büyütmek yerine görünür alanı özgün vektör komutlarıyla mevcut ölçekte çizer. Saydam belge alanları dama olmadan beyaz kâğıt görünür. Sayfa değiştirirken yeni sayfanın tamamı hazırlanır, sonra tüm sayfa yumuşakça belirir; arka plandaki vektör ayrıntı çizimi parça parça beliren boşluk bırakmaz. Gömülü fotoğraflar gibi rasterler özgün çözünürlükleriyle sınırlıdır.

**LumaView → Dil…** seçin veya “Daha Fazla” menüsünden açın. Varsayılan sistemi izler; Basitleştirilmiş Çince, Geleneksel Çince, İngilizce, Japonca, Korece, Fransızca, Almanca, İspanyolca, İtalyanca, Portekizce, Rusça, Arapça, Hintçe, Türkçe, Felemenkçe ve Lehçe desteklenir. Uygulama menüleri, ipuçları, sayfalama ve ayarlar hemen güncellenir; seçilen dil yerelde saklanır. Desteklenmeyen sistem dilleri İngilizceye döner; nadir çözme hataları da İngilizce olabilir. Dosya adları, yollar ve dosya içindeki özgün metin değişmez.

## Klavye ve fare

| İşlem | Kısayol / hareket |
| --- | --- |
| Önceki / sonraki öğe (mevcut odağa göre) | `←` / `→` veya `J` / `K` |
| Sayfa odağı / dosya odağı | `↑` / `↓` (çok sayfalı belgeler) |
| İlk / son öğe | `Home` / `End` |
| Dosya veya klasör aç | `⌘O` |
| Varsayılan açma uygulaması | `⌘,` |
| Yakınlaştırma | Tekerlek, izleme dörtgeninde kıstırma, `+` / `−`, `Page Up` / `Page Down` |
| Tekerlek davranışını geçici değiştir | `Ctrl` basılıyken kaydır |
| 100% / pencereye sığdır | Görüntüye tıkla veya `1` |
| Pencereye sığdır | `0` |
| Büyütülmüş görüntü veya videoyu kaydır | Görüntüyü sürükle |
| Görünümü saat yönünde döndür | `⌘R` / `Ctrl+R`, ters yön için `Shift` ekle |
| Arka planı değiştir | Boşluk |
| Tam ekrana gir / çık | `F` / `⌃⌘F` / `F11` (sistem kullanmıyorsa) |
| Ses/video oynat / duraklat | `P` |
| Ses/videoyu durdur ve başa dön | `S` |
| Slayt gösterisini ve sürekli oynatmayı başlat / durdur | `⌘4` |
| Ses/videoda 5 saniye geri / ileri | `Option + ←` / `Option + →` |
| Sesi kapat / aç | `M` |
| Dosya bilgisi | `I` / `⌘I` |
| Film şeridini göster / gizle | `T` / `⌘T` |
| Diğer seçenekler | `C` |
| Geçerli dosyayı Finder'da göster | `⌘Return` |
| Oynatmayı duraklat, bilgiyi kapat, tam ekrandan çık, pencereyi kapat | `Esc`, mevcut duruma göre sırayla |
| Küçült / kapat / çık | `⌘M` / `⌘W` / `⌘Q` |

`P` yalnız geçerli ses/videoyu yönetir, görüntü slayt gösterisini değil. “Yardım → Klavye ve Fare İşlemleri” içinde de açıklamalar bulunur.

## Destek kapsamı ve sınırlar

- Görüntüler sistem ImageIO ile çözülür; JPEG, PNG, GIF, HEIC, TIFF, BMP, WebP, RAW vb. desteği sistem sürümü ve dosya içeriğine bağlıdır.
- Çok büyük görüntüler yalnız 150 milyon pikseli aştığı için reddedilmez. Belleği sınırlamak için gerekirse küçültülmüş önizleme üretilir; özgün boyut ve yön korunur. 100% ölçek özgün boyuta göre hesaplanır, ancak önizlemede çözülmemiş ayrıntıyı geri getirmez.
- SVG, PDF, PDF uyumlu AI ve yerleşik yorumlayıcıyla EPS / PS / eski AI vektör gösterimi desteklenir. Çok sayfalı PDF / AI / PS gezilebilir; SVG betikleri ve dış kaynakları reddeder. Vektör içindeki rasterler kaynak çözünürlüğüyle sınırlıdır; bulunmayan gömülmemiş yazı tipleri değiştirilebilir.
- PostScript ayrı süreçte SAFER ve sistem sanal alanıyla çalışır: yalnız geçerli geçici giriş/çıkışa izin verilir, ağ yasaktır. Hızlı dosya değişiminde iptal edilebilir; küçük resim ve ana görüntü tamamlanmış önbelleği paylaşır. Tek yorumlama 90 saniye, çıktı 1 GB ile sınırlıdır; önbellek temizleme hedefi 2 GB'dir.
- Photoshop PSD / PSB kaydedilmiş bileşik görüntüyü gösterir, katman düzenlemez. Çok büyük tuvalde bellek bütçesine göre önizleme oluşturulur, özgün boyut saklanır; renk modu, bit derinliği ve sıkıştırma desteği FORMATS.md içindedir.
- Yerleşik uyumluluk çözmesi ses/video kapsamını genişletir; DRM, bozuk dosya veya kullanılabilir çözücüsü olmayan özel kodlamalar yine oynatılamayabilir. Uzantı iç kodlamanın çözülebileceğini garanti etmez; bütün biçim, cihaz ve sistem sürümleri tek tek denenmemiştir.
- Uyumluluk önbelleği için temizleme hedefi 2 GB'dir; kullanılan dosyalar geçici aşım yaratabilir. Hazırlanan tek dosya en fazla 8 GB olur, en az 512 MB boş alan korunur. Yetersiz alanda hazırlık durur ve uyarı gösterilir.
- TIFF çok sayfalıdır; sayfalama uygulanmamış diğer bileşik görüntü biçimleri ilk görüntüyü gösterir. Görünüm dönüşü özgün dosyaya yazılmaz. Düzenleme, silme, kütüphane veritabanı, paylaşım, bulut eşitleme veya dış altyazı yönetimi sunulmaz.
- Yalnız kullanıcının açtığı yerel medya ve bulunduğu klasör okunur; uyumlu oynatma yerel önbelleğe yazar, medyayı yüklemez ve özgün dosyayı değiştirmez.

Ek biçim örnekleri, önbellek ve önizleme sınırları [FORMATS.md](../i18n/tr/FORMATS.md) içindedir.

## Kaynaktan derleme

Swift derleyicili Xcode veya Command Line Tools gerekir. Depo ve kaynak paketi Intel / Apple Silicon evrensel medya araçlarını içerir; normal derleme ek bağımlılık kurulumu veya indirme gerektirmez. Klonlama veya indirmeden sonra `build.sh` içeren depo köküne girin; özgün geliştirme çalışma alanı yapısı gerekmez.

```bash
cd /path/to/LumaView
./build.sh
open ../LumaView.app
```

Varsayılan evrensel uygulamadır; `./build.sh --host` yalnız mevcut Mac mimarisini derler. Uygulama kaynak klasörünün yanında `LumaView.app` olarak oluşur; başka yol `LUMAVIEW_APP_PATH` ile verilir. Derleme ve test çalışma dizini varsayılan olarak depodaki `.build/` olup `LUMAVIEW_WORK_ROOT` ile değiştirilebilir; üretilenler `.gitignore` dışında tutulur.

`LUMAVIEW_TEST_BUILD=1 ./build.sh --host` test derlemesi, dosya açma ilişkileri bildirmeyen bağımsız `LumaView Tests` uygulamasını üretir; böylece kurulu sürümün ilişkileri devralınmaz. Arayüz test betikleri varsayılan bu modu kullanır; mevcut derlemeyi `LUMAVIEW_SKIP_TEST_BUILD=1` ve `LUMAVIEW_TEST_APP_PATH` ile seçebilirsiniz.

FFmpeg LGPL 2.1 veya sonrası altında derlenir, statik bağlı dav1d BSD 2-Clause kullanır. İlgili kaynak arşivleri, sağlama toplamları ve lisanslar kaynak paketindedir. Medya araçlarını yeniden derlemek için Xcode Command Line Tools, Python 3, Meson 1.12.1 ve Ninja 1.13.2 gerekir; Python sanal ortamına kurduktan sonra `./tools/build-media-tools.sh` çalıştırılabilir. Adımlar ve yapılandırma [ThirdParty/README.md](../i18n/tr/ThirdParty/README.md) içindedir. PostScript ayrı Ghostscript 10.08.0 (AGPL-3.0-or-later) kullanır; lisans, tam karşılık gelen kaynak ve derleme betiği dahildir. Normal uygulama derlemesi hazır çift mimarili bileşenleri kullanır; yeniden derleme için [Ghostscript açıklaması](../i18n/tr/ThirdParty/README-Ghostscript.md).

## Kaynak ve doğrulama

- `Sources/`: AppKit arayüzü, medya tuvali, görüntü/vektör yükleme, ses/video yaşam döngüsü, uyumluluk hazırlığı ve varsayılan uygulama ayarları.
- `Resources/Localizations/`: dil metinleri ve temel çeviri anahtarları.
- `Resources/MediaFormats.json`: biçim kataloğu; `Resources/MediaTools/`: paketlenmiş FFmpeg / ffprobe.
- `ThirdParty/sources/`, `Resources/ThirdPartyNotices/`: medya araçlarının karşılık gelen kaynakları ve lisansları.
- `build.sh`: evrensel uygulama derleme, paketleme ve yerel imza; `tools/build-media-tools.sh`: medya araçlarını yeniden derleme.

```bash
./Tests/run-core-tests.sh
./Tests/run-thumbnail-tests.sh
./Tests/run-thumbnail-request-tests.sh
./Tests/run-canvas-tests.sh
./Tests/run-ui-tests.sh
./Tests/run-video-tests.sh
./Tests/run-default-application-tests.sh
./Tests/run-default-preferences-tests.sh
./Tests/run-media-declaration-tests.sh
./Tests/run-document-tests.sh
./Tests/run-vector-compatibility-tests.sh
./Tests/run-postscript-tests.sh
./Tests/run-photoshop-tests.sh
./Tests/run-pdf-image-copy-tests.sh
./Tests/run-media-copy-tests.sh
./Tests/run-context-menu-tests.sh
./Tests/run-large-document-tests.sh
./Tests/run-audio-waveform-tests.sh
./Tests/run-audio-visual-tests.sh
./Tests/run-localization-tests.sh
```

Ses çözme birim testleri MP3 / FLAC / Opus örnekleri üretmek için uygun kodlayıcılara sahip geliştirme FFmpeg'i gerektirir; yolu `LUMAVIEW_TEST_FFMPEG` ile verilebilir. Uygulama ve ses arayüz testleri yalnız paketli bileşenleri kullanır.

Arayüz entegrasyon kontrolleri oturum açılmış macOS grafik masaüstü ister, uygulamayı açıp otomatik üretilmiş medyayla etkileşimleri denetler. Derlemeler ve saklanan raporlar varsayılan `.build/` içindedir; bazı çalışma materyalleri sistem geçici dizinindedir. Testler varsayılan kişisel fotoğrafları okumaz. Sağ tık kopyalama testleri ayrı adlandırılmış pano kullanır, kullanıcının panosunu ezmez; Birlikte Aç / Finder / varsayılan uygulama testleri sahte arayüz kullanır, dosya ilişkilerini değiştirmez. Teslim sürümünün kayıtları [TEST-RESULTS.txt](../i18n/tr/TEST-RESULTS.md) içindedir.

`Tests/` altındaki kayıtlar ilgili sürümlerin geçmiş doğrulamalarıdır; klonlanan güncel ortamın testleri otomatik geçtiği anlamına gelmez. Kişisel örnek dosya adları anonimleştirilmiş, özgün medya depoya alınmamıştır. Geçmiş raporlardaki `work/` yolları o zamanki test kaynağını kaydeder, bugünkü derleme için gerekli değildir. Depo üçüncü taraf araçlarının kaynak arşivleri, sağlama toplamları ve lisanslarını tuttuğu için ilk klonlama büyüktür.
