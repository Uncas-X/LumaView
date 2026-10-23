> Prywatne nazwy próbek w historycznych raportach zanonimizowano; dane i wyniki testów są niezmienione.

<!-- doc-navigation:start -->
[Dokumentacja](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · [English](../../en/Tests/Release-1.7.0.md) · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · **Polski**
<!-- doc-navigation:end -->

# Weryfikacja LumaView 1.7.0

Data: 2026-10-22 (Asia/Shanghai). Środowisko tej rundy: macOS 15.7.9, x86_64. Aplikacja wymaga macOS 13+; cztery programy są uniwersalne Intel / Apple Silicon.

## Zmiany i rzeczywiste wyniki

- Dołączono Ghostscript 10.08.0. Otwarcie EPS, PostScript i starego PostScript AI generuje w tle PDF zachowujący ścieżki, tekst i osadzone obrazy, przekazywany obecnemu płótnu. Nie trzeba instalować interpretera ani konwertować ręcznie; skala, przesuwanie, obrót i strony zachowują obecne interakcje. Osadzony TIFF jest nadal awaryjną ścieżką, gdy wektorowa konwersja nie udaje się, a plik ma podgląd; raster nie jest oznaczany jako wektor.
- Oryginalny załącznik `sample-vector.eps` sprawdzono z pełną treścią PostScript. Skan PDF wykazał **147,521 operacji ścieżek/gradientów, 59 operacji tekstu, 160 wywołań XObject**. XObject liczy się przez PDF `Do`, może być obrazem lub Form, więc nie oznacza liczby osobnych obrazów. Potwierdzono prawdziwą treść wektorową; SHA-256 EPS i `sample-vector.svg` przed/po dowodzi niezmienionych oryginałów.
- PostScript używa osobnego anulowalnego procesu, Ghostscript SAFER i systemowej piaskownicy. Wejście jest kopiowane do prywatnego katalogu tymczasowego; interpreter nie czyta innych plików użytkownika, nie zapisuje dowolnie na zewnątrz i nie używa zewnętrznych potoków. Testy limitu czasu, anulowania, wielu odbiorców, uszkodzeń i unieważniania cache przeszły. Gotowy wynik jest publikowany atomowo, niepełny PDF nie trafia do miniatur. Prawdziwy viewer sprawdził EPS przy 3200%, fokus góra/dół i strony lewo/prawo w PS oraz brak nadpisania PNG spóźnioną konwersją po zmianie pliku.
- `.psb` dodano do Photoshop obok `.psd` w wykrywaniu, głównym widoku, miniaturach i domyślnym otwieraniu. Czytany jest zgodny kompozyt, zachowywane wymiary źródła; duże pliki otrzymują ograniczony podgląd według potrzeb wyświetlania. Sprawdzono **112 kombinacji kodowania, 128 struktur ze znacznikami przezroczystości warstw, 1 duży PSB, 13 uszkodzonych próbek**. Przezroczystość rozpoznaje liczba warstw i Lr16/Lr32, Mtrn/Mt16/Mt32; zwykły dodatkowy Alpha nie jest mylony z przezroczystością kompozytu. Testy obejmują wartości pikseli, usunięcie białego tła, zgodność kodowań, anulowanie długich wierszy i integrację głównego obrazu/miniatur.
- Okno domyślnej aplikacji odczytuje systemowe skojarzenia przy otwarciu, aktywacji i po operacji zbiorczej. Skojarzenia przetrwają restart, niezastosowany szkic nie udaje sukcesu. Wszystkie typy bieżącej aplikacji dają znacznik, tylko część lub inna kopia o tym samym bundle ID — kreskę z wyjaśnieniem. Czyszczenie zmienia szkic, nie cofa systemowych skojarzeń.
- Górne „Wybierz wszystkie formaty” wybiera obrazy, wektory/dokumenty, wideo i audio także poza wyszukiwaniem; zapis nadal wymaga przycisku zastosowania. Wykrywanie, częściowy sukces, odczyt błędów, odbudowa kontrolera, szkic a stan rzeczywisty oraz pełny wybór sprawdzono atrapą backendu w pamięci; domyślne aplikacje użytkownika nie zostały zmienione.
- Nowe teksty ustawień, PostScript i Photoshop obejmują wszystkie 16 języków; weryfikacja podstawowych tekstów i znaczników przeszła.

## Weryfikacja tej rundy

Liczone są tylko wymienione dzienniki tej rundy z pełnym podsumowaniem sukcesu; niepowtórzone dawne moduły nie wchodzą do sumy.

| Kontrola | Zaliczone |
| --- | --- |
| Wektorowa konwersja PostScript, anulowanie, izolacja i prawdziwy EPS | 24 / 24 |
| Zgodność SVG / EPS i oryginalne załączniki | 64 / 64 |
| PSD / PSB: kompozyt, alpha, duże obrazy i uszkodzenia | 712 / 712 |
| Odczyt domyślnej aplikacji i operacja zbiorcza (mock) | 101 / 101 |
| Okno formatów, ponowne otwarcie i pełny wybór (mock) | 34 / 34 |
| 16 języków i znaczniki | 174 / 174 |
| Deklaracje formatów wydania | 15 / 15 |
| Biblioteka obrazów i dekodowanie systemowe | 78 / 78 |
| Geometria płótna, animacje i mysz | 66 / 66 |
| Parsowanie dokumentów i pełne strony | 56 / 56 |
| Fokus, skala/strony EPS / PS i anulowanie przy zmianie | 75 / 75 |
| Prawdziwe kliknięcia okna i cykl życia | 65 / 65 |
| Miniatury 443 plików, cache i nieaktualne wywołania | 37 / 37 |
| Anulowanie żądań miniatur i izolacja odbiorców | 13 / 13 |
| Zainstalowane wydanie: menu i prywatny schowek | 28 / 28 |
| **Razem** | **1542 / 1542** |

Zainstalowane zoptymalizowane wydanie przeszło dodatkowe 28 kontroli menu przez prawdziwe menu i target/action z osobnym nazwanym schowkiem. Sprawdzono kopiowanie obrazów, klatek, obrazów PDF i stron, obrót oraz nieaktualne wyniki po zmianie/zamknięciu; schowka użytkownika nie nadpisano. Dawne regresje myszy, cyklu okna, fokusu stron, pełnego rysowania, cache miniatur i anulowania przeszły.

## Weryfikacja wydania i instalacji

Wersja **1.7.0, build 12**. Przed raportem porównano bundle ID, wersję, build, pełne listy plików i SHA-256 `outputs/LumaView.app` oraz `/Applications/LumaView.app`; są identyczne. Cztery programy przeszły kontrolę dwóch architektur, obie aplikacje `codesign --verify --deep --strict`. Ghostscript zgłasza 10.08.0, lokalizacje i zasoby wersji są zgodne ze źródłami, archiwum Ghostscript ma sumę SHA-256 zgodną z listą. Budowa podpisuje interpreter ponownie, więc podpisane binarium nie musi być bajtowo identyczne z niepodpisaną ponownie kopią źródłową.

| Program | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

Raport nie zastępuje późniejszej kontroli ZIP ani nie deklaruje notaryzacji Apple. Podpis jest lokalny tymczasowy; Apple Silicon skompilowano skrośnie i sprawdzono architekturę, ale w tej rundzie nie uruchomiono na sprzęcie. Źródło Ghostscript, licencje i instrukcja przebudowy są w dostawie źródłowej.

## Zakres i granice

Bitmapy EPS / PS pozostają ograniczone rozdzielczością; fonty i pliki zewnętrzne oraz szczególne/uszkodzone PostScript mogą nie konwertować się w całości. PSD / PSB wymaga zgodnego kompozytu, nie edytuje warstw ani nie odtwarza brakującego; w razie braku prosi o „Maksymalizuj zgodność” i ponowny zapis. Źródłowe płótno może być większe od podglądu; ograniczony podgląd nie oznacza pełnego dekodowania wszystkich pikseli. Pozostałe granice: [FORMATS.md](../FORMATS.md).

## Źródła dzienników tej rundy

Poniższe skopiowano do `Tests/`; dawne niepowtórzone raporty zachowano, ale nie doliczono:

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
