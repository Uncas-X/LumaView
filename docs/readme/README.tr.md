# LumaView — Türkçe

<!-- language-navigation:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · **Türkçe** · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- language-navigation:end -->

Bu sayfa hızlı başlangıç kılavuzudur. Ayrıntılı kullanım bilgileri için [İngilizce](README.en.md) veya [Çince](../../README.md) tam kılavuza bakabilirsiniz.

LumaView; görsel, video, ses ve çok sayfalı belgeleri görüntülemek için geliştirilmiş yerel bir macOS uygulamasıdır. Hızlı gezinme düzeni Picasa Photo Viewer'dan esinlenir; ancak uygulamanın adı ve simgesi kendine aittir ve Google ile bağlantısı yoktur. Fotoğraf düzenlemek veya bir fotoğraf arşivi yönetmek yerine dosyaları görüntülemeye odaklanır.

## İndirme ve kurulum

**Sürüm 1.7.2, derleme 14.** macOS 13 veya üzeri gerekir. Evrensel uygulama hem Intel hem de Apple Silicon işlemcili Mac'lerde çalışır.

1. [macOS için LumaView](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip) paketini indirin. Önceki sürümleri [sürümler sayfasında](https://github.com/Uncas-X/LumaView/releases) bulabilirsiniz.
2. Arşivi açın ve `LumaView.app` dosyasını Uygulamalar klasörüne sürükleyin.
3. Uygulamayı açın. Yerel bir ad hoc imza kullanır ve Apple tarafından noter onayı almamıştır. İndirme kaynağını doğruladıktan sonra macOS ayarlarının **Gizlilik ve Güvenlik** bölümünden açılmasına izin vermeniz gerekebilir.

## Gezinme ve özellikler

Bir dosyayı veya klasörü pencereye sürükleyin ya da **Cmd+O** tuşlarına basın. Tek dosya açtığınızda aynı klasördeki diğer medya dosyaları arasında da gezinebilirsiniz. Klasör taraması yalnızca mevcut düzeyi kapsar; alt klasörlere girmez.

- Küçük resim şeridiyle dosya seçin. Yakınlaştırma, görüntüyü kaydırma, döndürme ve tam ekran özelliklerine akıcı geçişler ve buzlu cam etkili yarı saydam arka plan eşlik eder.
- PNG, GIF, PSD ve PSB dosyalarındaki saydam alanlar saydam kalır; gölgeler içeriğin şeklini izler. Belge sayfaları beyaz kâğıt üzerinde gösterilir. PSD/PSB için ayrı katmanlar yerine dosyada kaydedilmiş uyumluluk birleşik görüntüsü kullanılır.
- Video ve ses için önce sistemin yerel oynatıcısı kullanılır. Birlikte gelen FFmpeg ek biçimleri açabilir, ancak oynatmadan önce dosyanın tamamını yerel diskte hazırlaması gerekebilir. Ses dosyalarında gömülü kapak, kapak yoksa dalga biçimi gösterilir. Medya oynatma/duraklatma ve durdurma düğmeleri slayt gösterisinden bağımsızdır.
- PDF, PDF uyumlu AI ve çok sayfalı TIFF belgelerinde sayfalar arasında gezinebilirsiniz. SVG, desteklenen EPS/PS ve eski AI dosyaları vektörel olarak çizilir. EPS/PS için birlikte gelen Ghostscript kullanılır; gömülü bitmap görseller kaynak çözünürlüğüyle sınırlı kalır.
- Sağ tık menüsünden başka bir uygulamada açabilir, Finder'da gösterebilir veya görseli, videonun mevcut karesini, PDF sayfasını ya da PDF içindeki desteklenen gömülü görseli kopyalayabilirsiniz.

Ayarlar, LumaView'in varsayılan uygulama olacağı biçimleri seçmenizi ve arayüz dilini değiştirmenizi sağlar. Uygulama 16 dil sunar ve varsayılan olarak sistem dilini izler.

## Klavye kısayolları

| Tuş | İşlem |
| --- | --- |
| Cmd+O | Dosya veya klasör aç |
| ← / → | Odağa göre önceki/sonraki dosya veya sayfa |
| ↑ / ↓ | Çok sayfalı belgelerde odağı sayfalar/dosyalar arasında değiştir |
| Fare tekerleği / kıstırma hareketi / + / − | Yakınlaştırmayı değiştir |
| 0 / 1 | Pencereye sığdır / %100 ile pencereye sığdırma arasında geçiş yap |
| Cmd+R | Döndür |
| F | Tam ekranı aç veya kapat |
| P / S | Medyayı oynat veya duraklat / durdur |
| Cmd+4 | Slayt gösterisini kontrol et |
| Cmd+C | Görsel, kare veya sayfa kopyala |

**Boşluk tuşu arka planı değiştirir; oynatma/duraklatma işlevi yoktur.**

## Kaynaktan derleme

Xcode veya Swift Komut Satırı Araçları gerekir. Depo, gerekli medya araçlarını ve bunlara karşılık gelen kaynak kodu ve lisans arşivlerini içerir. Aşağıdaki komutları bu belge klasöründen değil, depo kökünden çalıştırın:

```bash
./build.sh
open ../LumaView.app
```

`./build.sh --host` yalnızca mevcut Mac'in mimarisi için derler. Üretilen dosyalar varsayılan olarak `.build/` içine yazılır. `LUMAVIEW_WORK_ROOT` bu klasörü, `LUMAVIEW_APP_PATH` ise oluşturulan uygulamanın yolunu değiştirir.

## Sınırlamalar ve gizlilik

LumaView yerel dosyaları okur; buluta yükleme yapmaz ve özgün dosyaları değiştirmez. Düzenleyici, katman düzenleme, arşiv veritabanı veya bulut eşitlemesi içermez. Büyük görseller sınırlı çözünürlüklü önizlemeler kullanabilir; yakınlaştırma, önizlemede bulunmayan ayrıntıları geri getirmez. Her kodeğin destekleneceği garanti edilmez; DRM korumalı, bozuk veya desteklenmeyen dosyalar açılamayabilir. Dönüştürmeler yerel disk önbelleği kullanır ve zaman alabilir.

Çince [teknik biçim kapsamına](../../FORMATS.md), ayrıca üçüncü taraf [medya araçları](../../ThirdParty/README.md) ve [Ghostscript](../../ThirdParty/README-Ghostscript.md) bildirimlerine bakın.
