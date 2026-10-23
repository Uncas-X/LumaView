# LumaView 1.7.2 doğrulama kaydı

<!-- doc-navigation:start -->
[Belgeler](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · [繁體中文](../zh-Hant/TEST-RESULTS.md) · [English](../en/TEST-RESULTS.md) · [日本語](../ja/TEST-RESULTS.md) · [한국어](../ko/TEST-RESULTS.md) · [Français](../fr/TEST-RESULTS.md) · [Deutsch](../de/TEST-RESULTS.md) · [Español](../es/TEST-RESULTS.md) · [Italiano](../it/TEST-RESULTS.md) · [Português (Brasil)](../pt-BR/TEST-RESULTS.md) · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · **Türkçe** · [Nederlands](../nl/TEST-RESULTS.md) · [Polski](../pl/TEST-RESULTS.md)
<!-- doc-navigation:end -->


Sürüm 1.7.2, build 14. 2026-10-22, macOS 15.7.9 / Intel. Uygulama ve yerleşik araçlar arm64 + x86_64 evrensel mimari ve yerel imza kontrollerini geçti; bu tur Apple Silicon donanımında çalıştırılmadı.

## Bu düzeltme

Raster görüntüler saydam alanları tek biçimde doğrudan gösterir: PNG / GIF / PSD / PSB artık gri-beyaz dama veya dikdörtgen tuval çerçevesi eklemez. Gölge bütün tuvalden değil geçerli görüntünün gerçek bileşik saydamlığından gelir; saydam boşlukta ek dikdörtgen gölge yoktur, delikler, bağımsız yumuşak maskeler ve yarı saydam alanlar gerçek kontura katılır.

Eski uygulama dama eklemek için yalnız CGImage.alphaInfo kullanıyor, bağımsız Quartz mask içeren PSB'yi kaçırıyordu; her yakınlaştırmada dikdörtgen shadowPath zorlanıyor, çerçeve de dikdörtgen gölge üretiyordu. Artık rasterde bu kaynaklar kaldırıldı, katman gölgesi bileşik alpha'dan otomatik oluşuyor. Çizim dışa aktarımı da önceden dikdörtgen doldurmadan görüntünün kendisine gölge verir. GIF / APNG kare değişimi mevcut dokuyu değiştirir, gölge kareyle güncellenir; her karede saydam piksel tarama veya ek tam RGBA üretimi gerekmez.

Belge beyaz kâğıdı ve video dikdörtgen yüzeyi mevcut gösterimini korur; kopyalama özgün pikselleri arka plan, dama veya gösterim gölgesi olmadan kullanır. PSB çözücü, küçük resim planlama ve önceki hızlı önizleme değiştirilmedi.

## Bu turun doğrulaması

| Kontrol | Geçti |
| --- | --- |
| Saydamlık, kontur gölgesi ve kare değişimi | 133 / 133 |
| Tuval geometrisi, animasyon ve fare | 66 / 66 |
| Belge ayrıştırma ve tam sayfa çizimi | 56 / 56 |
| Kurulu sürüm belgeleri, EPS / PS yakınlaştırma/sayfalama ve odak | 75 / 75 |
| Kurulu sürüm sağ tık menüsü ve kopyalama | 28 / 28 |
| Toplam | 358 / 358 |

Saydamlık testi aynı delikli, düzensiz çıkıntılı ve geniş saydam kenarlı şekli; RGBA, bağımsız Quartz mask, gerçekten kodlanıp çözülmüş PNG, GIF, PSD ve PSB olarak kullanır. CALayer bileşimi ve draw dışa aktarım pikselleri incelenir; saydam kenarda dikdörtgen taban/gölge olmaması, iç/dış konturda gölge olması doğrulanır. Tam saydam görüntü, kare değişimi, döndürme/yakınlaştırma, hızlı geçiş ve yarı saydam arka plan da kapsanır. Dışa aktarılan PNG elle incelenmiştir.

Bu altı girdinin CALayer ve PNG draw çıktılarının PNG SHA-256 değeri aynıdır: `578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`. Malzemeler kodla üretildi, kullanıcı fotoğrafları kaynağa eklenmedi.

Ek sınırlı yazılımsal çizim denemesi: 32 MP raster, mantıksal tuval 16,384 × 7,812 ve 300,000 × 128; eski/yeni gölgeler pencereye sığdırma, 100% ve 3200% altında karşılaştırıldı. Süreç tepe RSS yaklaşık 428 MiB, eski/yeni süreler yakındı; bu CALayer.render(in:) yazılım görüntüsü maliyetidir, GPU kare hızı sonucu değildir. Bu nedenle katman raster önbelleği eklenmedi.

Kurulu sürüm ve outputs/LumaView.app tam dosya listesi ve özetleri aynıdır; ikisi codesign --verify --deep --strict geçti. Kurulum öncesi eski ZIP yedeği saklandı, varsayılan ilişkiler önce/sonra okundu. Teslim ZIP'i daha sonra CRC ve sürüm kontrolü gördü. Tarihsel raporlar Tests/Release-1.7.0.md ve Tests/Release-1.7.1.md içindedir; tekrarlanmayan eski kontroller bu toplamda yoktur.

Ana program SHA-256: `b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`.

## Günlük kaynakları

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
