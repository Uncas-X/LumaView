# Weryfikacja LumaView 1.7.2

<!-- doc-navigation:start -->
[Dokumentacja](INDEX.md) · [简体中文](../zh-Hans/TEST-RESULTS.md) · [繁體中文](../zh-Hant/TEST-RESULTS.md) · [English](../en/TEST-RESULTS.md) · [日本語](../ja/TEST-RESULTS.md) · [한국어](../ko/TEST-RESULTS.md) · [Français](../fr/TEST-RESULTS.md) · [Deutsch](../de/TEST-RESULTS.md) · [Español](../es/TEST-RESULTS.md) · [Italiano](../it/TEST-RESULTS.md) · [Português (Brasil)](../pt-BR/TEST-RESULTS.md) · [Русский](../ru/TEST-RESULTS.md) · [العربية](../ar/TEST-RESULTS.md) · [हिन्दी](../hi/TEST-RESULTS.md) · [Türkçe](../tr/TEST-RESULTS.md) · [Nederlands](../nl/TEST-RESULTS.md) · **Polski**
<!-- doc-navigation:end -->


Wersja 1.7.2, build 14. 2026-10-22, macOS 15.7.9 / Intel. Aplikacja i narzędzia przeszły kontrolę arm64 + x86_64 i lokalnych podpisów; w tej rundzie nie uruchomiono na sprzęcie Apple Silicon.

## Ta poprawka

Rastry jednolicie pokazują przezroczystość bezpośrednio: PNG / GIF / PSD / PSB nie dodają szaro-białej szachownicy ani prostokątnej ramki płótna. Cień wynika z rzeczywistej scalonej przezroczystości, nie całego płótna; przezroczyste marginesy nie mają dodatkowego prostokątnego cienia, a otwory, osobne miękkie maski i półprzezroczystość tworzą właściwy kontur.

Dawniej szachownica zależała tylko od CGImage.alphaInfo, pomijając PSB z osobną Quartz mask; każde powiększenie wymuszało prostokątny shadowPath, a ramka też tworzyła prostokątny cień. Te źródła usunięto; cień warstwy powstaje automatycznie z kompozytowej alpha. Eksport rysowania również rzuca cień samego obrazu bez wstępnego wypełnienia prostokąta. GIF / APNG zastępuje teksturę przy każdej klatce, cień idzie za nią; nie trzeba skanować pikseli ani tworzyć dodatkowego pełnego RGBA w każdej klatce.

Biały papier dokumentów i prostokątna powierzchnia filmu zachowują dawny wygląd. Kopiowanie używa oryginalnych pikseli bez tła, szachownicy i cienia widoku. Dekoder PSB, harmonogram miniatur i poprzedni szybki podgląd nie były zmieniane.

## Weryfikacja tej rundy

| Element | Zaliczone |
| --- | --- |
| Przezroczystość, cień konturu i klatki | 133 / 133 |
| Geometria płótna, animacja i mysz | 66 / 66 |
| Parsowanie dokumentów i pełne strony | 56 / 56 |
| Zainstalowane wydanie: dokumenty, skala/strony EPS / PS i fokus | 75 / 75 |
| Zainstalowane wydanie: menu kontekstowe i kopiowanie | 28 / 28 |
| Razem | 358 / 358 |

Test przezroczystości używa tej samej figury z otworami, nieregularnymi występami i dużymi przezroczystymi marginesami jako RGBA, osobna Quartz mask oraz faktycznie zakodowane/zdekodowane PNG, GIF, PSD, PSB. Kompozycja CALayer i piksele eksportu draw potwierdzają brak prostokątnej podstawy/cienia na przezroczystych krawędziach i cień konturów wewnętrznych/zewnętrznych. Obejmuje też całkowicie przezroczyste obrazy, klatki, obrót/skalę, szybkie przełączenia i półprzezroczyste tło. Wyeksportowane PNG sprawdzono ręcznie.

SHA-256 PNG eksportu CALayer i draw dla sześciu wejść jest identyczny: `578021195e2a41b30187ebc271542d599aecba7f0b9204fbfdf21eb680cac18c`. Materiały wygenerowano kodem; zdjęć użytkownika nie dodano do źródeł.

Dodatkowa ograniczona próba renderowania programowego: bitmapa 32 MP, logiczne płótna 16,384 × 7,812 i 300,000 × 128; stare/nowe cienie przy dopasowaniu, 100% i 3200%. Szczyt RSS około 428 MiB, czasy podobne; to koszt programowego zrzutu CALayer.render(in:), nie wniosek o FPS GPU. Nie dodano z tego powodu cache rasteryzacji warstw.

Pełne listy plików i sumy zainstalowanego wydania oraz outputs/LumaView.app są identyczne, obie przechodzą codesign --verify --deep --strict. Przed instalacją zachowano stary ZIP; domyślne skojarzenia sprawdzono odczytem przed i po. ZIP dostawy później przeszedł CRC i kontrolę wersji. Historia jest w Tests/Release-1.7.0.md i Tests/Release-1.7.1.md; niepowtórzone stare testy nie są doliczone.

SHA-256 programu: `b022867c703cb1cdc94c31589d040356a5ec2be9bc5dd0c17395d323f8556d4e`.

## Źródła dzienników

- `Transparency-test-results.txt` ← `work/transparency-1.7.2/transparency-test-results.txt`
- `Canvas-test-results.txt` ← `work/canvas-1.7.2-run.log`
- `Document-core-test-results.txt` ← `work/document-release-1.7.2/document-core-test-results.txt`
- `Document-UI-test-results.txt` ← `work/document-release-1.7.2/document-test-results.txt`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.2/context-menu-test-results.txt`
