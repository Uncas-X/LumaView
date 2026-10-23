# Formaty i podgląd

<!-- doc-navigation:start -->
[Dokumentacja](INDEX.md) · [简体中文](../zh-Hans/FORMATS.md) · [繁體中文](../zh-Hant/FORMATS.md) · [English](../en/FORMATS.md) · [日本語](../ja/FORMATS.md) · [한국어](../ko/FORMATS.md) · [Français](../fr/FORMATS.md) · [Deutsch](../de/FORMATS.md) · [Español](../es/FORMATS.md) · [Italiano](../it/FORMATS.md) · [Português (Brasil)](../pt-BR/FORMATS.md) · [Русский](../ru/FORMATS.md) · [العربية](../ar/FORMATS.md) · [हिन्दी](../hi/FORMATS.md) · [Türkçe](../tr/FORMATS.md) · [Nederlands](../nl/FORMATS.md) · **Polski**
<!-- doc-navigation:end -->


Katalog LumaView 1.7.2 zawiera 72 grupy obrazów, wektorów / dokumentów, filmów i dźwięków. Służy do wykrywania plików i wyboru domyślnej aplikacji, nie jest listą osobno zweryfikowanej zgodności. Identyczne rozszerzenia mogą zawierać różne kodowania; otwarcie zależy od treści, systemu i wbudowanych dekoderów.

## Obrazy

| Kategoria | Przykłady formatów |
| --- | --- |
| Popularne obrazy | JPEG, PNG / APNG, GIF, TIFF, BMP, HEIC / HEIF, WebP |
| Pozostałe obrazy | AVIF, JPEG XL, JPEG 2000, ICO / CUR / ICNS, PSD / PSB, TGA, HDR / OpenEXR, Netpbm |
| RAW aparatów | DNG, Canon CR2 / CR3 / CRW, Nikon NEF / NRW, Sony ARW / SR2 / SRF oraz ORF, RAF, RW2, PEF, SRW |

Obrazy dekoduje macOS ImageIO. Tabela wymienia kandydatów katalogu; zwłaszcza RAW, nowe kodowania i profesjonalne formaty zależą od wersji systemu. Nie ma osobnego dekodera RAW. GIF obsługuje animację, TIFF wiele stron; inne formaty złożone bez podziału stron pokazują pierwszy obraz.

Przezroczystość PNG / APNG, GIF, PSD / PSB i innych rastrów jednolicie pokazuje bieżące tło, bez szaro-białej szachownicy. Cień wynika z rzeczywistej przezroczystości pikseli, obejmuje osobne miękkie maski i każdą klatkę animacji; nie dodaje prostokątnej ramki/cienia przy pustym brzegu płótna. Efekt dotyczy tylko oglądania, kopia zachowuje przezroczystość bez cienia widoku. Dokumenty wektorowe PDF, SVG itd. stosują opisany niżej biały papier.

**Photoshop PSD / PSB:** odczytywany jest zapisany obraz scalony dla widoku, miniatur i kopiowania; warstwy Photoshop nie są odtwarzane ani edytowane. Gdy plik jawnie nie zawiera zgodnego obrazu scalonego, wyświetlane jest zalecenie włączenia „Maksymalizuj zgodność” w Photoshopie i ponownego zapisania. PSD / PSB to wersje pliku 1 / 2; według [specyfikacji Adobe](https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/) bok nie przekracza odpowiednio 30,000 / 300,000 pikseli.

Sprawdzono 112 podstawowych kombinacji: PSD i PSB, szarość z jednym/dodatkowymi kanałami, RGB z trzema/dodatkowymi kanałami przy 8 / 16 / 32 bitach oraz CMYK przy 8 / 16 bitach. Każda kombinacja obejmuje brak kompresji, PackBits RLE, ZIP i ZIP prediction. Dodatkowe 128 szarych/RGB próbek z rzeczywistymi rekordami warstw sprawdza rozróżnianie zwykłej alpha użytkownika od przezroczystości kompozytu przy 8 / 16 / 32 bitach, dodatnie/ujemne liczby warstw, globalne Lr16/Lr32, znaczniki przezroczystości oraz brak kompresji/ZIP. Sprawdzono też ograniczony podgląd PSB 300,000 × 128 pikseli, główne ładowanie i miniatury. Próbki matrycy wygenerowano ze specyfikacji. 1.7.1 dodatkowo sprawdziła trzy rzeczywiste PSB około 108–123 MiB z warstwami, przezroczystym kompozytem i ICC; nie oznacza to sprawdzenia każdego eksportu Photoshopa.

Pasek preferuje prawidłową miniaturę RGB JPEG Photoshopa (zasób 1036), sprawdzając kodowanie, wymiary, proporcje i długość. Gdy jej brak, jest uszkodzona lub nieobsługiwana, używa kompozytu. Osadzony podgląd jest zwykle mały i służy tylko paskowi; główny widok zawsze czyta zgodny kompozyt. RLE czyta bloki do 64 KiB zamiast osobnego odczytu dla każdego znacznika; anulowanie działa na granicach bloków i w długich ciągach no-op.

ZIP, RLE wysokiej głębi, duże obrazy i dodatkowe kanały używają wbudowanego awaryjnego odczytu wierszami, potem ImageIO interpretuje kolor. Jawny znacznik przezroczystości powoduje odczyt odpowiedniej alpha; RGB/szarość usuwa białe tło kompozytu i dodaje osobną maskę. Bez deklaracji pokazuje tylko podstawowe kolory, nie traktuje zapisanych zaznaczeń jako przezroczystości. Wiele alpha, kanały dodatkowych farb, przezroczystość CMYK i złożone maski nie są w pełni sprawdzone; nie gwarantuje się zgodności z warstwową kompozycją Photoshop. Odczyt awaryjny zachowuje pierwszy osadzony ICC do 4 MiB dla systemu. Jeśli system odrzuci mały kompozyt z poprawnym ICC, piksele są dekodowane osobno, a zweryfikowany oryginalny ICC ze zgodnym modelem i składnikami jest ponownie dołączany, nie wyrzucany. Większe profile pomija się, więc kolor może być interpretowany domyślnie. Dane 32-bitowe służą podglądowi, bez pełnego sterowania tonalnością Photoshop HDR. Lab, kolor indeksowany, duotone i inne specjalne tryby nie są w matrycy; otwarcie zależy od struktury i dekodera systemu. Dla 1-bit PackBits jest dodatkowy natywny test małego obrazu.

Duże obrazy nie są odrzucane tylko za przekroczenie 150 milionów pikseli. Ładowarka tworzy podgląd w budżecie pamięci, do 8192 pikseli na długim boku i około 32 milionów łącznie; faktyczny rozmiar może być mniejszy. Informacje zachowują oryginalne wymiary i orientację, oznaczają zmniejszony podgląd. Skala wynika z wymiarów oryginału, powiększenie nie odzyskuje niezdekodowanych detali. Pliki uszkodzone lub niemożliwe do zdekodowania nadal zgłaszają błąd.

## Wektory i dokumenty

| Format | Obecne zachowanie |
| --- | --- |
| SVG | Rysowanie offline systemowym rendererem wektorów, aktualizowane przy skali; rozpoznane standardowe deklaracje SVG DTD są dozwolone bez ładowania DTD. Własne/wewnętrzne DTD, skrypty, zdarzenia i źródła zewnętrzne są odrzucane; złożone lub dynamiczne SVG mogą nie działać. |
| PDF | Miniatury stron, postęp, numery, fokus i klawiatura; rysowanie w bieżącej skali z zachowaniem przycięcia i orientacji; brak edycji. |
| AI | Zgodne dane PDF są pokazywane bezpośrednio, także wiele stron / obszarów roboczych. Stare PostScript AI konwertuje wbudowany Ghostscript do wektorowego PDF; plik zawierający tylko własnościowe dane Illustrator nie ma gwarancji otwarcia. |
| EPS / PostScript | Ghostscript 10.08.0 zamienia pełną treść na PDF, zachowując ścieżki, tekst i obrazy, potem pokazuje płótno wektorowe; obsługuje wielostronicowy PS. Nieudana interpretacja DOS EPS z prawidłowym TIFF może użyć podglądu oznaczonego raster. Bitmapy ogranicza źródło; brakujące nieosadzone fonty mogą zostać zastąpione. |

Główne płótno zachowuje źródło PDF / SVG, rysuje widoczny obszar w kaflach 512 pikseli przy aktualnej skali do 3200%. Zmiana strony najpierw przygotowuje w tle pełne podłoże dopasowane do ekranu; po przejściu całej strony źródłowy wektor uzupełnia detale bieżącej skali, bez pustych obszarów pojawiających się kafelkami. Podłoże ma do 4096 pikseli na długim boku i nie ogranicza ostrości wektora. Papier jest biały, bez szachownicy; zdjęcia ogranicza źródłowa rozdzielczość. Każda strona TIFF ma ograniczony podgląd rastrowy jak duże obrazy. Zaszyfrowanego PDF, którego nie odblokowano, nie można bezpośrednio oglądać; nie ma interfejsu wpisywania hasła. Renderowanie nie zmienia pliku.

PDF / AI zgodne z PDF pozwala skopiować klikniętą osadzoną bitmapę lub całą stronę. Obsługiwane popularne XObject, obrazy inline, zagnieżdżone Form, przycięcie i orientacja. Złożone maski/kolory używają renderowanego widocznego regionu. Bitmapy w Pattern i inne specjalne struktury lub strony ponad budżet skanowania mogą nie pozwolić na osobne kopiowanie. Wynik to PNG/TIFF do 8192 pikseli na długim boku i około 32 milionów pikseli; oryginał nie zmienia się.

## Filmy i dźwięk

| Kategoria | Przykłady w katalogu |
| --- | --- |
| Popularne kontenery wideo | MP4 / M4V, MOV, MKV, WebM, AVI, FLV, WMV / ASF, MPEG, TS / M2TS, 3GP |
| Inne filmy i strumienie | OGV, RM / RMVB, VOB, MOD / TOD, Motion JPEG, MXF, DV, NUT, NSV, AMV, Bink / Smacker oraz strumienie H.264, HEVC, VVC, IVF, Y4M |
| Popularne audio | MP3, AAC, M4A, WAV, AIFF, CAF, FLAC, Ogg / Vorbis, Opus, WMA |
| Inne audio | Speex, APE, WavPack, TTA, TAK, Shorten, AC-3 / E-AC-3 / TrueHD, DTS, AMR, AU / SND, RealAudio, DSD, MKA, Musepack, GSM / QCP, IFF Audio |

Najpierw próbuje systemowy AVFoundation. Jeśli nie odtwarza bezpośrednio, używane są FFmpeg 9.0.2 / ffprobe z aplikacji, ze statycznym dav1d 1.5.3 dla AV1. Odpowiednie filmy najpierw zmieniają kontener z zachowaniem kodeka, potem w razie potrzeby kodowanie na systemowo zgodne. Audio również może przejść przygotowanie zgodności.

Przygotowanie jest lokalne, sieć wyłączona, bez dodatkowej instalacji. Najpierw przetwarzany jest cały plik, więc natychmiastowy start nie jest gwarantowany. Interfejs pokazuje postęp; zmiana pliku/zamknięcie anuluje. Transkodowanie może zmienić jakość obrazu, dźwięku lub barw; oryginał pozostaje. Szybkość wysokiej rozdzielczości, klatkażu, trudnych kodeków i długich plików zależy od urządzenia.

Cache jest czyszczony automatycznie z celem 2 GB; używane pliki pozostają, więc to nie twardy całkowity limit. Jeden przygotowany plik ma do 8 GB, wymagane pozostawienie 512 MB wolnego miejsca; przekroczenie zatrzymuje i zgłasza błąd. Ponowne otwarcie może użyć poprawnego cache.

DRM, uszkodzenia, niedołączone dekodery zewnętrzne, własnościowe kodowania i szczególne kontenery mogą uniemożliwiać odtwarzanie. Katalog ma rzadkie formaty, lecz nie obiecuje wszystkich ani nie sprawdza każdej kombinacji. Nie ma zewnętrznych napisów, menu płyt i streamingu.

## Okładki i przebiegi audio

Główny widok preferuje okładkę osadzoną w oryginale: najpierw natywne metadane, w razie potrzeby attached picture wyciągnięty narzędziem. Okładka dekoduje się do 2048 pikseli na długim boku; błędna wraca do przebiegu. Bez osadzonej okładki nie pobiera się jej z sieci ani nie czyta cover.jpg z folderu.

Bez okładki prawdziwe zdekodowane próbki tworzą obwiednię szczytową całego nagrania z maksymalnie 4096 przedziałami. Bufory PCM są ograniczone, długi dźwięk nie ładuje się w całości do pamięci. Audio zgodności używa przygotowanego lokalnego pliku do przebiegu. To przegląd całości, nie widmo na żywo; podczas generowania odtwarzanie trwa. Zmiana pliku/zamknięcie anuluje analizę, spóźniony wynik nie nadpisuje obecnego. Czas na pasku czyta się osobno asynchronicznie, bez wybierania każdego pliku; znaczniki audio/wideo to `▶ Czas trwania`.

## Ustawienia domyślnej aplikacji

Przez **LumaView → Domyślne otwieranie…** lub `⌘,` zaznacz grupy i zastosuj. Każde otwarcie, aktywacja i zakończenie odczytuje rzeczywiste skojarzenia, trwałe po restarcie. Znacznik oznacza wszystkie typy w obecnej aplikacji, kreska część lub inną kopię LumaView. „Wybierz wszystkie formaty” obejmuje każdą kategorię niezależnie od wyszukiwania; grupowe „Wybierz wszystko” tylko kategorię. Niezastosowany wybór to szkic; czyszczenie nie cofa zapisanych relacji. System może traktować rozszerzenia ze wspólnym identyfikatorem jako jeden typ, więc część zmienia się razem.

Interfejs odczytuje wynik i zgłasza nieudane formaty. Anulowanie zatrzymuje tylko niewykonane zmiany, wykonanych nie cofa automatycznie. Aby przywrócić format, wybierz dawny program w Finderze: „Informacje → Otwórz w programie → Zmień wszystkie”.
