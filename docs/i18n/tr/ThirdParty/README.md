# Paketlenmiş medya araçları

<!-- doc-navigation:start -->
[Belgeler](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · [Русский](../../ru/ThirdParty/README.md) · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · **Türkçe** · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView değiştirilmemiş FFmpeg 9.0.2 ve ffprobe'u ayrı yerel süreçler olarak çağırır. macOS 13 hedefiyle Intel ve Apple Silicon için kaynaktan derlenmiştir. AV1 çözmek için statik bağlı dav1d 1.5.3 ve yalnız sistem dinamik kitaplıklarını kullanırlar. Çalışırken Homebrew veya VLC gerekmez.

FFmpeg `--enable-gpl` veya `--enable-nonfree` olmadan LGPL 2.1 veya sonrası için yapılandırılır. dav1d BSD 2-Clause lisanslıdır. Tam lisans bildirimleri `Resources/ThirdPartyNotices` içindedir ve uygulama paketine kopyalanır. Tam eşleşen, değiştirilmemiş kaynak arşivleri SHA-256 değerleriyle `sources/` içindedir. Tüm yapılandırma seçenekleri ve adımlar `tools/build-media-tools.sh` içindedir. LumaView bu ayrı araçları değiştirme/değiştirilmiş olanla değiştirme veya böyle değişiklikleri ayıklamak için gereken tersine mühendisliğe ek kısıtlama getirmez.

Resmî kaynaklar:

- [FFmpeg sürümü ve imzası](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. Ayrık imza FFmpeg sürüm anahtarı `FCF986EA15E6E293A5644F10B4322F04D67658D8` ile doğrulanmıştır.
- [dav1d sürümü](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [FFmpeg lisans bilgisi](https://ffmpeg.org/legal.html).

## Yeniden derleme

Normal uygulama derlemesi hazır evrensel ikilileri kullanır. Araçları yeniden derlemek için Xcode Command Line Tools, Python 3, Meson 1.12.1 ve Ninja 1.13.2 kurun. Örneğin yerel Python sanal ortamına `meson==1.12.1 ninja==1.13.2` kurun, etkinleştirip çalıştırın:

```sh
./tools/build-media-tools.sh
./build.sh
```

İlk komut kaynak sağlama toplamlarını doğrular, iki mimariyi derler ve `Resources/MediaTools/{ffmpeg,ffprobe}` dosyalarını değiştirir. Python için `LUMAVIEW_PYTHON`, ara derleme dizini için `LUMAVIEW_MEDIA_BUILD` kullanın. `x86_64` veya `arm64` tek mimariyi derler; varsayılan `universal` ikisini birleştirir. Uygulama derlemesi iç araçları ve uygulamayı yerel ad-hoc imzayla imzalar.

Ağ, yakalama cihazları, ffplay, dav1d dışı harici kodekler ve GPL kodlayıcıları kapalıdır. Bu yapılandırmanın kullanılabilir tüm iç çözücüleri/ayırıcıları dahildir. Ses AAC olarak hazırlanır; videoda mümkünse remux, sonra VideoToolbox H.264, MPEG-4 veya ProRes uyumlu çıktı kullanılır. Bu görüntüleme yoludur, dışa aktarma veya kod dönüştürme arayüzü değildir.

## PostScript vektör yorumlayıcısı

EPS, PostScript ve eski Illustrator önizlemesi ek olarak paketli Ghostscript 10.08.0'ı ayrı, kısıtlı yerel alt süreç olarak kullanır. AGPL-3.0-or-later lisansı, tam karşılık gelen kaynak arşivi, özetler ve tekrarlanabilir evrensel derleme için [README-Ghostscript.md](README-Ghostscript.md) belgesine bakın. Normal uygulama derlemesi sistem Ghostscript kurulumu gerektirmez.
