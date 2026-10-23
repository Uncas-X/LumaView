# Ghostscript belge dönüştürme aracı

<!-- doc-navigation:start -->
[Belgeler](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · **Türkçe** · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView, Artifex'in 2026-09-08'de yayımladığı Ghostscript **10.08.0** sürümünü EPS ve PostScript'i geçici PDF'ye dönüştüren ayrı yerel yürütülebilir olarak çağırır. PDF çıktısı desteklenen vektör yollarını, metin ve geçişleri korur. Raster piksel olarak gömülü görüntüler raster kalır. Ghostscript Swift uygulamasına bağlanmaz, paketli aracı çalıştırmak için Homebrew gerekmez.

## Lisans ve karşılık gelen kaynak

Ghostscript bu sürümün özgün `LICENSE` dosyasında belirtildiği gibi **GNU Affero General Public License sürüm 3 veya sonrası** altında dağıtılır. Tam lisans, Ghostscript telif bildirimi, yazı tipi gömme istisnası, Adobe CMap ve bağımlılık bildirimleri değiştirilmeden `Resources/ThirdPartyNotices/Ghostscript/` içine kopyalanır. Artifex ayrı ticari lisans da sunar; bu paket ticari lisans içermez. [Resmî lisans sayfasına](https://www.ghostscript.com/licensing/index.html) bakın.

Paketli bağımlılık ve yazı tipi kaynakları dahil tam, değiştirilmemiş karşılık gelen kaynak `ThirdParty/sources/ghostscript-10.08.0.tar.xz` içindedir. SHA-256 değeri `ThirdParty/sources/SHA256SUMS-Ghostscript` içinde kayıtlıdır:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

Kaynak kökeni: [resmî sürüm sayfası](https://www.ghostscript.com/releases/index.html) ve [Artifex 10.08.0 sürüm dosyaları](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). Özet `.tar.xz` için yayımlananla aynıdır. Kaynak paketi ve bu derleme betiği LumaView kaynak dağıtımına eşlik eder. LumaView bu ayrı aracı değiştirme, yerine başkasını koyma veya değişiklikleri ayıklamak için tersine mühendisliğe ek kısıtlama getirmez. Bildirimler üçüncü taraf bileşeni açıklar; uygulama kaynağının lisansını değiştirme iddiasında değildir.

## Yeniden derleme

Gerekenler: macOS, Xcode Command Line Tools, ekli kaynak arşivi ve standart macOS derleme araçları. Homebrew kitaplıkları kullanılmaz. LumaView kaynak dizininden:

```sh
./tools/build-document-tools.sh
./build.sh
```

Betik arşivi doğrular, ayrı kaynak dizinlerinden Intel ve Apple Silicon dilimlerini derler, yerel sembolleri ayıklar ve `Resources/DocumentTools/gs` içinde birleştirir. İki dilim macOS 13.0 veya sonrasını hedefler. `make install` çalıştırmaz, sistem paket yöneticisine yazmaz. `LUMAVIEW_DOCUMENT_BUILD` ara dizini, `LUMAVIEW_DOCUMENT_JOBS` make paralelliğini (varsayılan 4) seçer. İsteğe bağlı `x86_64` veya `arm64` tek mimari derler. Uygulama derlemesi kopyalanan aracı uygulamayla imzalar.

Yürütülebilir başlatma kodunu, gömülü yazı tiplerini, Adobe CMaps ve ICC profillerini iç `%rom%` dosya sisteminde tutar. Varsayılan dış arama yolları boştur. Yalnız `pdfwrite` çıktı aygıtı açıktır. Yazdırma/CUPS, X11, GTK, fontconfig, D-Bus, Tesseract/OCR, dinamik sürücüler, dış IJS ve belge çıkarma araçları kapalıdır. Tüm çözücü/renk/yazı tipi kitaplıkları karşılık gelen arşivden derlenir; dinamik bağlar Apple sistem kitaplıklarıyla sınırlıdır. ROM ve çapraz derleme için [resmî derleme belgesine](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html) bakın.

LumaView yorumlayıcıyı `-dSAFER`, belirli giriş/çıkış, özel geçici çalışma dizini, iptal ve zaman aşımı ile çalıştırır. Süreç ortamı kullanıcı Ghostscript seçeneklerini veya kitaplık yollarını devralmamalıdır. Üretilmiş güvenilir test girdileri için örnek:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

Tüm seçenekler `tools/build-document-tools.sh` içindedir; kaynak arşivi yamalanmaz. Yerel yürütme yalnız derleme bilgisayarının desteklediği mimarilerde denenebilir. Sürüm kontrolleri iki Mach-O dilimini inceler ve yol/metin içeren üretilmiş EPS'yi ana makineyle uyumlu dilimde çalıştırarak PDF'nin vektör çizim ve metin operatörlerini koruduğunu doğrular.
