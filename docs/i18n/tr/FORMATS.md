# Biçimler ve önizleme

<!-- doc-navigation:start -->
[Belgeler](INDEX.md) · [简体中文](../zh-Hans/FORMATS.md) · [繁體中文](../zh-Hant/FORMATS.md) · [English](../en/FORMATS.md) · [日本語](../ja/FORMATS.md) · [한국어](../ko/FORMATS.md) · [Français](../fr/FORMATS.md) · [Deutsch](../de/FORMATS.md) · [Español](../es/FORMATS.md) · [Italiano](../it/FORMATS.md) · [Português (Brasil)](../pt-BR/FORMATS.md) · [Русский](../ru/FORMATS.md) · [العربية](../ar/FORMATS.md) · [हिन्दी](../hi/FORMATS.md) · **Türkçe** · [Nederlands](../nl/FORMATS.md) · [Polski](../pl/FORMATS.md)
<!-- doc-navigation:end -->


LumaView 1.7.2 biçim kataloğunda görüntü, vektör / belge, video ve ses için 72 grup vardır. Katalog dosya bulma ve varsayılan açma seçimi içindir, tek tek sınanmış uyumluluk listesi değildir. Aynı uzantı farklı kodlamalar taşıyabilir; açılabilirlik içerik, sistem yetenekleri ve yerleşik çözücülere bağlıdır.

## Görüntüler

| Kategori | Biçim örnekleri |
| --- | --- |
| Yaygın görüntüler | JPEG, PNG / APNG, GIF, TIFF, BMP, HEIC / HEIF, WebP |
| Diğer görüntüler | AVIF, JPEG XL, JPEG 2000, ICO / CUR / ICNS, PSD / PSB, TGA, HDR / OpenEXR, Netpbm |
| Kamera RAW | DNG, Canon CR2 / CR3 / CRW, Nikon NEF / NRW, Sony ARW / SR2 / SRF ve ORF, RAF, RW2, PEF, SRW |

Görüntüler macOS ImageIO ile çözülür. Tablo katalogdaki adayları listeler; özellikle RAW, yeni kodlamalar ve profesyonel biçimlerin desteği sistem sürümüne bağlıdır. Ayrı RAW çözücüsü paketlenmez. GIF hareketlidir; TIFF çok sayfalıdır; sayfalaması uygulanmamış diğer bileşik görüntüler yalnız ilk görüntüyü gösterir.

PNG / APNG, GIF, PSD / PSB gibi rasterlerin saydam alanları, gri-beyaz dama eklenmeden mevcut arka planı gösterir. Gölge gerçek piksel saydamlığından oluşur; bağımsız yumuşak maskeleri ve animasyonun her karesini kapsar, boş tuval kenarına dikdörtgen gölge veya çerçeve eklemez. Etki yalnız görüntüleme içindir; kopya özgün saydamlığı korur ve gösterim gölgesini içermez. PDF, SVG gibi vektör belgeler aşağıdaki beyaz kâğıt kuralını izler.

**Photoshop PSD / PSB:** dosyanın bileşik görüntüsü okunur; ana görünüm, küçük resim ve gösterilen görüntüyü kopyalama desteklenir, Photoshop katmanları yeniden oluşturulmaz veya düzenlenmez. Dosya uyumlu bileşik kaydetmediğini açıkça belirtiyorsa Photoshop'ta “Uyumluluğu En Üst Düzeye Çıkar” açılıp yeniden kaydedilmesi istenir. PSD / PSB, dosya sürümleri 1 / 2'dir; [Adobe biçim belirtimine](https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/) göre en uzun kenar sırasıyla 30,000 / 300,000 pikseldir.

112 temel kodlama birleşimi doğrulanmıştır: PSD ve PSB için tek/ek kanallı gri, üç/ek kanallı RGB'de 8 / 16 / 32 bit; CMYK'da 8 / 16 bit. Her birleşim sıkıştırmasız, PackBits RLE, ZIP ve ZIP prediction içerir. Gerçek katman kayıtlı 128 gri/RGB örneği ayrıca 8 / 16 / 32 bitte kullanıcı alpha'sını bileşik saydamlıktan ayırmayı sınar; pozitif/negatif katman sayıları, genel Lr16/Lr32 kayıtları, bileşik saydamlık işaretleri ve sıkıştırmasız/ZIP kodlamalarını kapsar. 300,000 × 128 piksellik PSB'nin sınırlı önizlemesi, ana görüntüsü ve küçük resmi de doğrulanmıştır. Matris örnekleri biçim belirtiminden üretilmiştir. 1.7.1 ayrıca katman, saydam bileşik ve ICC içeren yaklaşık 108–123 MiB boyutlu üç gerçek PSB'nin ana görünüm ve küçük resimlerini sınadı; bunlar her Photoshop dışa aktarımının doğrulandığı anlamına gelmez.

Film şeridi Photoshop'un geçerli RGB JPEG küçük resmini (kaynak 1036) tercih eder; kodlama, boyut, en-boy oranı ve uzunluğu doğrular. Yoksa, bozuksa veya desteklenmiyorsa bileşiğe döner. Gömülü önizleme genellikle küçüktür ve yalnız şeritte kullanılır; ana görünüm her zaman uyumlu bileşiği okur. RLE en fazla 64 KiB bloklarla okunur, her sıkıştırma işareti için dosya okuması yapılmaz; blok sınırları ve uzun no-op dizilerinde iptal korunur.

ZIP, yüksek bitli RLE, büyük görüntüler ve ek kanallı dosyalar yerleşik satır satır yedek okumayı, ardından ImageIO renk yorumunu kullanır. Açık bileşik saydamlık işareti varsa ilgili saydamlık okunur; RGB/gri için bileşik önizlemenin beyaz zemini kaldırılıp ayrı maske eklenir. İşaret yoksa yalnız temel renkler gösterilir, kaydedilmiş seçimler saydamlık sayılmaz. Çoklu alpha, spot kanallar, CMYK saydamlığı ve karmaşık maskeler tam doğrulanmamıştır; Photoshop katman bileşimiyle eşitlik garanti edilmez. Yedek okuma ilk 4 MiB'yi aşmayan gömülü ICC'yi sisteme verir. Sistem geçerli ICC içeren küçük bileşiği reddederse pikseller ayrı çözülür ve doğrulanmış, model/bileşen uyumlu özgün ICC yeniden eklenir; profil doğrudan atılmaz. Daha büyük profiller atlanır, renk sistem varsayılanıyla yorumlanabilir. 32 bit veri önizleme içindir, tam Photoshop HDR ton denetimi yoktur. Lab, indeksli renk, duotone ve diğer özel modlar matriste değildir; açılabilirlik dosya yapısı ve sistem çözücüsüne bağlıdır. 1 bit PackBits için ayrıca küçük görüntü yerel çözme kontrolü vardır.

Büyük görüntüler yalnız 150 milyon pikseli aştığı için reddedilmez. Yükleyici bellek bütçesine göre, uzun kenarı en fazla 8192 piksel ve toplamı yaklaşık 32 milyon piksel olan önizleme oluşturur; gerçek sınır daha düşük olabilir. Bilgi paneli özgün boyut ve yönü korur, küçültülmüş önizlemeyi belirtir. Ölçek özgün boyuttan hesaplanır; önizlemeyi büyütmek çözülmemiş özgün ayrıntıyı getirmez. Bozuk veya çözülemeyen dosyalar hata verir.

## Vektörler ve belgeler

| Biçim | Mevcut davranış |
| --- | --- |
| SVG | Sistem vektör çizicisiyle çevrimdışı, ölçeğe göre çizilir; tanınan standart SVG DTD bildirimlerine izin verilir ama DTD yüklenmez. Özel/iç DTD, betik, olay işleyici ve dış kaynak reddedilir; bazı karmaşık veya dinamik SVG'ler gösterilemeyebilir. |
| PDF | Çok sayfalı küçük resimler, ilerleme, sayfa numarası, odak ve klavye gezintisi; kırpma kutusu ve sayfa yönü korunarak mevcut ölçekte çizim; belge düzenleme yoktur. |
| AI | PDF uyumlu veri doğrudan gösterilir, çoklu sayfa / çalışma yüzeyi desteklenir; eski PostScript AI yerleşik Ghostscript ile vektör PDF'ye dönüştürülür. Yalnız özel Illustrator verisi içeren dosyaların açılması garanti edilmez. |
| EPS / PostScript | Yerleşik Ghostscript 10.08.0 tam çizimi yollar, metin ve gömülü görüntüler korunarak PDF'ye dönüştürür, vektör tuvali gösterir; çok sayfalı PS desteklenir. Yorumlama başarısızsa geçerli gömülü TIFF içeren DOS EPS, raster olarak belirtilen önizlemeye dönebilir. Raster özgün çözünürlükle sınırlıdır; bulunamayan gömülmemiş yazı tipleri değiştirilebilir. |

Ana tuval PDF / SVG vektör kaynağını tutar, görünür alanı mevcut ölçekte 512 piksellik parçalarda çizer; en fazla 3200% yakınlaştırma desteklenir. Sayfa geçişinde önce arka planda ekrana uygun tam sayfa tabanı hazırlanır, bütün sayfa geçişinden sonra özgün vektör katmanı mevcut ölçekteki ayrıntıları tamamlar; boş alanların parça parça belirmesi önlenir. Taban uzun kenarı en fazla 4096 pikseldir, vektörün büyütme netliğini etkilemez. Kâğıt beyazdır, dama yoktur; gömülü fotoğraflar kaynak çözünürlüğüyle sınırlıdır. TIFF'in her sayfası büyük görüntülerle aynı sınırlı raster önizlemeyi kullanır. Şifreli, kilidi açılmamış PDF için parola girişi yoktur, doğrudan görüntülenemez. Çizim özgün dosyayı değiştirmez.

PDF / PDF uyumlu AI, tıklanan gömülü rasteri veya tüm sayfayı sağ tıkla kopyalar. Yaygın XObject, satır içi görüntü, iç içe Form, kırpma ve sayfa yönü desteklenir. Karmaşık maske veya renk uzayında görünür bölgenin çizilmiş sonucu kullanılır. Pattern içindeki rasterler gibi özel yapılar veya tarama bütçesini aşan sayfalarda gömülü görüntü ayrı kopyalanamayabilir. Çıktı en fazla 8192 piksel uzun kenarlı, yaklaşık 32 milyon piksellik PNG/TIFF'tir; özgün dosya değişmez.

## Video ve ses

| Kategori | Katalog örnekleri |
| --- | --- |
| Yaygın video kapsayıcıları | MP4 / M4V, MOV, MKV, WebM, AVI, FLV, WMV / ASF, MPEG, TS / M2TS, 3GP |
| Diğer videolar ve bit akışları | OGV, RM / RMVB, VOB, MOD / TOD, Motion JPEG, MXF, DV, NUT, NSV, AMV, Bink / Smacker ve H.264, HEVC, VVC, IVF, Y4M akışları |
| Yaygın ses | MP3, AAC, M4A, WAV, AIFF, CAF, FLAC, Ogg / Vorbis, Opus, WMA |
| Diğer ses | Speex, APE, WavPack, TTA, TAK, Shorten, AC-3 / E-AC-3 / TrueHD, DTS, AMR, AU / SND, RealAudio, DSD, MKA, Musepack, GSM / QCP, IFF Audio |

Önce sistem AVFoundation denenir. Doğrudan oynatamazsa uygulamayla gelen FFmpeg 9.0.2 / ffprobe kullanılır; AV1 için statik bağlı dav1d 1.5.3 içerir. Uygun videoda önce video kodlaması korunarak kapsayıcı değiştirilir, hâlâ oynatılamıyorsa sistemin desteklediği kodlamaya çevrilir. Ses de uyumluluk hazırlığıyla oynatılabilir.

Hazırlık yereldir, ağ kapalıdır, ek kurulum gerekmez. Tüm dosya önce işlenir, anında başlama garanti değildir. İlerleme gösterilir; dosya değiştirme veya pencereyi kapatma iptal eder. Yeniden kodlama görüntü, ses veya renk kalitesini değiştirebilir; özgün dosya değişmez. Yüksek çözünürlük, yüksek kare hızı, karmaşık kodlama ve uzun dosyalarda hız cihaza bağlıdır.

Önbellek otomatik temizlenir, hedef 2 GB'dir; kullanılan dosyalar tutulduğundan bu kesin toplam sınır değildir. Hazırlanan tek dosya en fazla 8 GB, diskte kalan boş alan en az 512 MB olmalıdır; sınır aşılırsa durur ve hata gösterilir. Tekrar açılış geçerli önbelleği kullanabilir.

DRM korumalı, bozuk, dahil olmayan harici çözücü isteyen, özel kodlamalı veya bazı özel kapsayıcılı dosyalar oynatılamayabilir. Katalog nadir biçimler içerir ama hepsini vaat etmez; her kodlama birleşimi test edilmemiştir. Dış altyazı yönetimi, disk menüsü veya akış oynatma yoktur.

## Ses kapağı ve dalga biçimi

Ana görünüm özgün dosyanın gömülü kapağını tercih eder; önce yerel metaveri okunur, gerektiğinde yerleşik araç attached picture çıkarır. Kapak uzun kenarı 2048 piksele kadar çözülür; çözülemiyorsa dalga biçimine dönülür. Gömülü kapak yoksa ağdan indirilmez, aynı klasördeki cover.jpg okunmaz.

Kapak yoksa gerçek çözülen örneklerden tüm sesin tepe zarfı üretilir, en fazla 4096 örnek aralığı tutulur. PCM tamponları sınırlıdır, uzun dosyanın tamamı belleğe yüklenmez. Uyumluluk sesi, hazırlanmış yerel dosyadan dalga üretir. Bu tüm parçanın genel görünümüdür, gerçek zamanlı spektrum değildir; üretilirken oynatma sürer. Dosya değiştirme veya kapatma analizi iptal eder, geciken sonuç mevcut dosyanın üstüne yazmaz. Şerit süresi her dosyayı seçmeden ayrı eşzamansız okunur; ses ve video köşe etiketi `▶ Süre` biçimindedir.

## Varsayılan uygulama ayarı

**LumaView → Varsayılan Açma Uygulaması…** veya `⌘,` ile biçimleri gruplar halinde seçip uygulayın. Her açılış, yeniden etkinleşme ve tamamlanmada gerçek sistem ilişkileri okunur; yeniden başlatmalarda saklanırlar. İşaret tüm türlerin mevcut uygulamaya, çizgi bir kısmının veya başka LumaView kopyasına gittiğini belirtir. “Tüm biçimleri seç” aramadan bağımsız tüm kategorileri, grup “Tümünü seç” yalnız o kategoriyi kapsar. Uygulanmamış seçim taslaktır; temizleme yazılmış ilişkileri geri almaz. Sistem aynı tür tanımlayıcısını kullanan uzantıları tek tür sayabilir, dolayısıyla bazı uzantılar birlikte değişir.

Arayüz sistem sonucunu yeniden okur, başarısız biçimleri bildirir. İptal yalnız henüz yapılmamış değişiklikleri durdurur; yapılanlar otomatik geri alınmaz. Bir biçimi geri döndürmek için Finder'da “Bilgi Ver → Birlikte Aç → Tümünü Değiştir” ile eski uygulamayı seçin.
