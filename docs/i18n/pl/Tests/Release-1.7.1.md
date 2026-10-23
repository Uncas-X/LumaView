> Prywatne nazwy próbek w historycznych raportach zanonimizowano; dane i wyniki testów są niezmienione.

<!-- doc-navigation:start -->
[Dokumentacja](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · [English](../../en/Tests/Release-1.7.1.md) · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · **Polski**
<!-- doc-navigation:end -->

# Weryfikacja LumaView 1.7.1

Wersja 1.7.1, build 13. 2026-10-22, macOS 15.7.9 / Intel. Aplikacja i trzy narzędzia przeszły kontrolę arm64 + x86_64 oraz lokalnych podpisów; nie uruchomiono ich w tej rundzie na Apple Silicon.

## Zidentyfikowane i naprawione

Trzy PSB użytkownika to 8-bit RGB, 4 kanały, RLE z przezroczystym kompozytem, około 108–123 MiB. Większość rozmiaru to pomijalne dane warstw; główne płótno ma około 8.50–9.60 miliona pikseli.

1. Stary dekoder wierszowy wywoływał FileHandle dla każdego znacznika/wartości PackBits, powodując wiele małych odczytów i blokując kolejki widoku i miniatur. Zmieniono na bloki do 64 KiB z zachowaniem literal/run między blokami i kontroli granic; długie no-op nadal można anulować. ZIP odwraca predykcję tylko próbkowanych wierszy, ale sprawdza cały skompresowany strumień.
2. Wszystkie trzy mają poprawną miniaturę RGB JPEG zasobu 1036. Pasek preferuje ją, sprawdzając format, wymiary, proporcje i długość kompresji; główny widok zawsze dekoduje prawdziwy kompozyt. Błędne podglądy, stary zasób BGR lub brak podglądu wracają do kompozytu.
3. ImageIO odrzuca niektóre małe kompozyty PSD z prawidłowym Generic RGB ICC, dawniej zwracając pustą miniaturę. Awaryjnie piksele są dekodowane osobno i dołączany jest sprawdzony oryginalny ICC ze zgodnym modelem/składnikami, bez odrzucania profilu. ICC źródeł jest identyczny z systemowym Generic RGB Profile; regresje generują dane z profilu systemu, bez zdjęć użytkownika w źródłach.
4. Główny widok PSB używa już sparsowanego nagłówka, unika dodatkowego skanowania warstw ImageIO dla metadanych. Zachowuje wymiary, przezroczystość i jakość głównego obrazu.

## Test trzech oryginałów

To pomiary lokalne na tym Macu, zależne od obciążenia i cache plików, nie gwarancja wydajności każdego urządzenia. Oba dekodery były optymalizowane.

| Plik | Wymiary źródła | Stare dekodowanie główne | Nowe dekodowanie główne | Nowa miniatura kompozytu (bez osadzonego podglądu) |
| --- | --- | --- | --- | --- |
| Sample A | 2582 × 3318 | Test anulowano po ponad 15 sekundach | 0.68 sekundy | 0.039 sekundy |
| Sample B | 2610 × 3307 | 14.35 sekundy | 0.65 sekundy | 0.028 sekundy |
| Sample C | 2843 × 3361 | Test anulowano po ponad 15 sekundach | 0.70 sekundy | 0.028 sekundy |

Trzy miniatury żądane równocześnie przez prawdziwy ImageLoader zakończyły się w około 0.06 sekundy. Główne obrazy przez loader zajęły około 0.90 / 0.65 / 0.74 sekundy. Stare trzy miniatury kompozytu zgłaszały unsupported; nowe są poprawne. SHA-256 przed/po jest bajtowo identyczny; aplikacja nie zapisywała oryginałów.

## Zaliczone kontrole

| Element | Wynik |
| --- | --- |
| Kodowanie PSD / PSB i przezroczysty kompozyt | 712 / 712 |
| Wydajność RLE, podgląd, ICC, granice bloków i anulowanie | 54 / 54 |
| Integracja prawdziwego ImageLoader z trzema PSB | 21 / 21 |
| Pasek 443 plików, cache i wygasłe wywołania | 37 / 37 |
| Niezależne żądania miniatur i anulowanie | 13 / 13 |
| Biblioteka obrazów i dekodowanie systemowe | 78 / 78 |
| Zainstalowane zoptymalizowane wydanie: menu i kopiowanie | 28 / 28 |
| Razem | 943 / 943 |

Nowe testy obejmują gęste jednobajtowe literal, granicę 64 KiB, anulowanie długich no-op, obcięcie/wyjście poza granice, osobną poprawną treść miniatury i głównego obrazu, ICC, alpha i niecałkowitą skalę małych obrazów. Dotychczasowe 112 kombinacji i 128 struktur znaczników przezroczystości nadal przechodzi. Pasek sprawdza szybkie zmiany, anulowanie poza ekranem i brak zanieczyszczenia listy dawnymi wynikami.

Zainstalowane wydanie i outputs/LumaView.app mają identyczne listy i sumy, obie przechodzą codesign --verify --deep --strict. Przed instalacją zachowano stary ZIP; skojarzeń nie zmieniono. Dostarczany ZIP osobno przechodzi CRC i kontrolę wersji. Pełny raport 1.7.0 pozostaje w Tests/Release-1.7.0.md; niepowtórzonych testów nie doliczono.

SHA-256 programu: `cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`.

## Dzienniki

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
