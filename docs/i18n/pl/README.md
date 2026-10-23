# LumaView 1.7.2

<!-- doc-navigation:start -->
[Dokumentacja](INDEX.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [English](../en/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md) · [Français](../fr/README.md) · [Deutsch](../de/README.md) · [Español](../es/README.md) · [Italiano](../it/README.md) · [Português (Brasil)](../pt-BR/README.md) · [Русский](../ru/README.md) · [العربية](../ar/README.md) · [हिन्दी](../hi/README.md) · [Türkçe](../tr/README.md) · [Nederlands](../nl/README.md) · **Polski**
<!-- doc-navigation:end -->


**[Pobierz aplikację macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)** · [Wersje i informacje o zmianach](https://github.com/Uncas-X/LumaView/releases)

Wymagany macOS 13+; ten sam pakiet obsługuje Intel i Apple Silicon. Rozpakuj pobrany ZIP i przeciągnij `LumaView.app` do folderu Aplikacje.

Natywna przeglądarka multimediów dla macOS, inspirowana szybkim przeglądaniem w Picasa Photo Viewer: przeglądanie tego samego folderu, powiększanie, przesuwanie, obracanie, pasek miniatur, pełny ekran i pokaz slajdów. Wersja 1.5 dodała okładki i rzeczywiste przebiegi dźwięku, nawigację po dokumentach wielostronicowych, płótno wektorowe przerysowywane przy zmianie skali oraz wielojęzyczne ustawienia domyślnie zgodne z systemem. Aplikacja ma własną nazwę i oryginalną ikonę; nie deklaruje pełnej zgodności ze wszystkimi funkcjami i interakcjami dawnej Picasy.

1.7.2 ujednolica przezroczystość: PNG, GIF, PSD / PSB i inne obrazy rastrowe pokazują bieżące tło przeglądarki, a cień podąża za rzeczywistym konturem i przezroczystością. Nie ma już szaro-białej szachownicy ani prostokątnego cienia całego przezroczystego płótna. PDF i inne dokumenty zachowują biały papier.

Optymalizacje PSD / PSB z 1.7.1 pozostają: pasek preferuje prawidłowy osadzony JPEG, główny widok dekoduje prawdziwy zgodny obraz scalony, RLE jest czytane blokami. Naprawiono też brak miniatur niektórych małych obrazów scalonych z profilem ICC.

## Używanie i instalacja

Wymagany macOS 13 lub nowszy; obsługiwane Intel i Apple Silicon.

1. Pobierz `LumaView-macOS.zip` z [Releases](https://github.com/Uncas-X/LumaView/releases), rozpakuj, przeciągnij `LumaView.app` do Aplikacji i otwórz.
2. Przeciągnij obrazy, filmy, dźwięki lub folder albo wybierz pliki przez `⌘O`. Otwarcie jednego pliku pokazuje multimedia z tego samego folderu; wybór wielu — tylko zaznaczone pliki. Skanowany jest bieżący poziom folderu, bez podfolderów.
3. W Finderze możesz też kliknąć plik prawym przyciskiem i wybrać „Otwórz w programie → LumaView”.

Lokalna kompilacja ma tymczasowy podpis i nie jest notaryzowana przez Apple. Jeśli Gatekeeper na innym Macu blokuje pobraną kopię, po sprawdzeniu źródła zezwól na otwarcie w systemowych ustawieniach „Prywatność i ochrona”.

## Domyślna aplikacja

Wybierz **LumaView → Domyślne otwieranie…**, naciśnij `⌘,` lub przejdź przez menu „Więcej”. Formaty są pogrupowane jako obrazy, wektory / dokumenty, filmy i dźwięk. Wyszukaj i zaznacz formaty, potem wybierz „Ustaw jako domyślną aplikację dla wybranych formatów”. Przy otwarciu okna, ponownej aktywacji aplikacji i zakończeniu ustawiania odczytywane są rzeczywiste skojarzenia systemowe: znacznik oznacza, że cała grupa otwiera się w bieżącej kopii LumaView; kreska — część typów lub inną kopię. Skojarzenia przetrwają restart; niezastosowane zaznaczenia nie udają pomyślnych zmian. Górne „Wybierz wszystkie formaty” obejmuje wszystkie obrazy, dokumenty wektorowe, filmy i dźwięki niezależnie od wyszukiwania; można też zaznaczyć całą kategorię. Wyczyszczenie usuwa tylko bieżący wybór, nie istniejące skojarzenia.

Ustawianie pokazuje postęp i odczytuje wynik każdego działania z systemu. Anulowanie zatrzymuje dalsze zmiany, zachowując już wykonane. Lista formatów oznacza dostępne skojarzenia, nie przetestowanie każdego kodeka lub pliku; zakres opisuje [dokument o formatach i podglądzie](FORMATS.md).

## Oglądanie i odtwarzanie

Pierwszy plik rozszerza okno do dostępnego obszaru bieżącego ekranu; `F` włącza pełny ekran. Dolny pasek miniatur przełącza pliki. Pasek narzędzi znika po chwili bezruchu myszy w obszarze obrazu i wraca przy ruchu.

1.5.2 naprawia puste lub migające miniatury po długim przeglądaniu dużych folderów: widoczne miniatury są przechowywane osobno, ładowanie poza ekranem szybko anulowane, stare wyniki folderu nie trafiają do nowej listy. Pliki bez możliwości dekodowania pokazują stabilny symbol zastępczy; powrót do tego zakresu umożliwia kolejną próbę.

Obrazy i filmy obsługują powiększanie, przesuwanie, obracanie i pełny ekran. Okno, zmiany obrazu, skali i obrotu mają krótkie płynne przejścia, przerywane kolejnymi działaniami. Systemowe „Ogranicz ruch” wyłącza te własne przejścia; animowane obrazy nadal grają normalnie. Domyślne tło to półprzezroczyste matowe szkło; spacja przełącza szkło, ciemne i jasne tło.

Przezroczystość rastrów ma jedną zasadę: pokazuje bieżące tło, cień dotyczy wyłącznie pikseli z treścią, półprzezroczyste krawędzie zachowują przezroczystość. Cień GIF / APNG zmienia się z każdą klatką. Kopiowanie zachowuje oryginalne przezroczyste piksele bez tła i cienia przeglądarki.

Odtwarzanie, zatrzymanie, postęp i głośność audio/wideo znajdują się nad miniaturami. Odtwarzanie rusza automatycznie, po końcu pozostaje na końcu; `P` powtarza, `S` zatrzymuje i wraca na początek. Dolny przycisk pokazu slajdów jest niezależny: po włączeniu ciągłego odtwarzania przez `⌘4` obrazy zmieniają się według interwału, a audio/wideo po zakończeniu. Samo odtwarzanie audio/wideo nie przechodzi automatycznie do następnego pliku.

Najpierw używane jest natywne odtwarzanie macOS. Gdy system nie odtwarza pliku bezpośrednio, wbudowane uniwersalne FFmpeg 9.0.2 i dav1d 1.5.3 lokalnie przygotowują zgodny plik; jeśli to możliwe, najpierw zmieniany jest kontener, potem podejmowane transkodowanie. Nie trzeba instalować odtwarzacza, Homebrew ani kodeków; sieć nie jest używana. Odtwarzanie zgodności czeka na przygotowanie całego pliku i pokazuje postęp; zmiana pliku lub zamknięcie okna anuluje przygotowanie. Pierwsze przygotowanie długiego filmu może wymagać czasu i dodatkowego miejsca na dysku.

`C` lub „Więcej” ustawia przeglądanie w pętli, działanie kółka, zamykanie przez tło, miniatury, sortowanie i interwał slajdów (2, 3, 5, 8, 10 sekund). Kółko domyślnie powiększa; przytrzymanie `Ctrl` chwilowo przełącza na pliki. Jeśli domyślnie przegląda pliki, `Ctrl` chwilowo powiększa. „Zamykaj po kliknięciu tła poza obrazem” jest domyślnie włączone. Ustawienia są lokalne.

## Menu kontekstowe i kopiowanie

Kliknij główny obraz prawym przyciskiem (lub Ctrl-kliknij), aby wybrać „Otwórz w programie → Aplikacja / Inna aplikacja…” albo „Pokaż w Finderze”. Wybór programu dotyczy tylko tego otwarcia, bez zmiany domyślnego skojarzenia; obie opcje działają także dla niedekodowalnych plików.

- Obrazy: „Kopiuj obraz” zachowuje obrót bieżącego widoku i przezroczyste piksele, kopiuje cały zdekodowany obraz, bez paska narzędzi lub wycinka powiększonego ekranu.
- Film: „Kopiuj bieżącą klatkę” kopiuje klatkę z chwili otwarcia menu, zachowuje orientację filmu i obrót widoku, nie zmienia pozycji ani stanu odtwarzania.
- PDF / AI zgodne z PDF: prawy klik bitmapy na stronie udostępnia „Kopiuj ten obraz” lub „Kopiuj bieżącą stronę”. Po skali, przesunięciu i obrocie nadal uwzględniane jest rzeczywiste miejsce kliknięcia. Zwykły tekst i wektory nie są obrazami; przy złożonych maskach/przestrzeniach barw kopiowany jest widoczny wynik regionu, być może z nałożonym tekstem. Strona zeskanowana jako jeden obraz jest kopiowana jako cały skan.
- `⌘C` kopiuje bieżący obraz, klatkę filmu lub stronę dokumentu; audio nie udostępnia kopiowania obrazu. Schowek otrzymuje PNG i TIFF. Po zmianie pliku / strony lub zamknięciu stary wynik nie nadpisuje schowka.

Kopie dokumentów i osadzonych obrazów są bitmapami do 8192 pikseli na długim boku i około 32 milionów pikseli; instrukcje wektorowe PDF/SVG nie trafiają do schowka. Jeśli duży obraz jest pokazywany w ograniczonym podglądzie, kopiowany jest podgląd. Skanowanie obrazów PDF ma limit złożoności; szczególne struktury, np. obrazy w wypełnieniach wzorkiem, mogą nie być osobno wybieralne, lecz można kopiować stronę.

Standardowe nagłówki SVG 1.0/1.1 są analizowane offline, bez zewnętrznego DTD. W 1.7 wbudowany Ghostscript 10.08.0 przekształca EPS / PostScript i stare PostScript AI w PDF zachowujący ścieżki, tekst i obrazy; główny widok przerysowuje wektory przy skali. Wielostronicowy PS korzysta z obecnej nawigacji. Nie potrzeba dodatkowego oprogramowania. Nieudana konwersja EPS z prawidłowym TIFF może użyć awaryjnego podglądu jawnie oznaczonego TIFF. Oryginalne bitmapy nie stają się wektorami.

## Dźwięk, dokumenty i języki

Gdy audio ma osadzoną okładkę, główny widok preferuje ją; w przeciwnym razie rzeczywiste próbki są analizowane asynchronicznie i pokazywany jest przebieg całego nagrania. Podczas analizy widać symbol zastępczy, odtwarzanie nie czeka. Audio i wideo mają jednakowe `▶ Czas trwania` w prawym dolnym rogu miniatury, z tym samym fontem, tłem i pozycją; przed odczytem jest `▶ –:––`. Okładka pochodzi wyłącznie z osadzonych metadanych, nie z sieci ani sąsiednich plików.

PDF, AI zgodne z PDF i wielostronicowy TIFF pozwalają przeglądać strony. Mniejsze miniatury stron, pasek postępu stron i bieżąca / łączna liczba stron są nad paskiem plików. `↑` ustawia fokus stron, `↓` plików; pomarańczowa ramka zaznaczonej miniatury wskazuje aktywny rząd, szara zachowuje zaznaczenie drugiego. Nie ma etykiet „Strony / Pliki”. `←` / `→`, `J` / `K` oraz `Home` / `End` działają na bieżący fokus. Kliknięcie rzędu również go aktywuje. Pierwsza/ostatnia strona zatrzymuje nawigację bez przypadkowego przejścia do pliku. Dolne przyciski poprzedniego / następnego pliku zawsze zmieniają plik. Nawigacja stron pozostaje po ukryciu paska plików.

PDF, SVG i AI zgodne z PDF rysują widoczny obszar oryginalnymi instrukcjami wektorowymi w bieżącej skali zamiast powiększać stały podgląd. Przezroczyste obszary dokumentu są białym papierem bez szachownicy. Przy zmianie stron najpierw gotowa jest cała nowa strona, potem następuje płynne pojawienie całości; rysowanie detali wektorowych w tle nie zostawia pustych kafelków pojawiających się kolejno. Osadzone zdjęcia i inne bitmapy ogranicza rozdzielczość źródła.

Wybierz **LumaView → Język…** lub otwórz przez „Więcej”. Domyślnie zgodny z systemem; dostępne są chiński uproszczony, chiński tradycyjny, angielski, japoński, koreański, francuski, niemiecki, hiszpański, włoski, portugalski, rosyjski, arabski, hindi, turecki, niderlandzki i polski. Menu, podpowiedzi, strony i ustawienia aktualizują się natychmiast; język jest zapisywany lokalnie. Nieobsługiwany język systemu wraca do angielskiego; rzadkie błędy dekodowania też mogą być po angielsku. Nazwy plików, ścieżki i tekst wewnątrz plików pozostają bez zmian.

## Klawiatura i mysz

| Działanie | Skrót / gest |
| --- | --- |
| Poprzedni / następny element (według fokusu) | `←` / `→` lub `J` / `K` |
| Fokus stron / plików | `↑` / `↓` (dokumenty wielostronicowe) |
| Pierwszy / ostatni element | `Home` / `End` |
| Otwórz plik lub folder | `⌘O` |
| Domyślne otwieranie | `⌘,` |
| Powiększenie | Kółko, szczypanie gładzika, `+` / `−`, `Page Up` / `Page Down` |
| Tymczasowa zmiana kółka | Przewijaj z przytrzymanym `Ctrl` |
| 100% / dopasuj do okna | Kliknij obraz lub `1` |
| Dopasuj do okna | `0` |
| Przesuń powiększony obraz/film | Przeciągnij obraz |
| Obrót widoku w prawo | `⌘R` / `Ctrl+R`, z `Shift` w lewo |
| Zmień tło | Spacja |
| Włącz / wyłącz pełny ekran | `F` / `⌃⌘F` / `F11` (jeśli system nie przejął) |
| Odtwarzaj / pauzuj audio i wideo | `P` |
| Zatrzymaj audio/wideo i wróć na początek | `S` |
| Uruchom / zatrzymaj slajdy i ciągłe odtwarzanie | `⌘4` |
| Audio/wideo 5 sekund wstecz / naprzód | `Option + ←` / `Option + →` |
| Wycisz / przywróć dźwięk | `M` |
| Informacje o pliku | `I` / `⌘I` |
| Pokaż / ukryj miniatury | `T` / `⌘T` |
| Więcej opcji | `C` |
| Pokaż bieżący plik w Finderze | `⌘Return` |
| Pauza, zamknij informacje, wyjdź z pełnego ekranu, zamknij okno | `Esc`, kolejno według bieżącego stanu |
| Minimalizuj / zamknij / zakończ | `⌘M` / `⌘W` / `⌘Q` |

`P` steruje tylko bieżącym audio/wideo, nie pokazem zdjęć. Wbudowana pomoc jest też w „Pomoc → Klawiatura i mysz”.

## Zakres i ograniczenia

- Obrazy dekoduje systemowy ImageIO; rzeczywista obsługa JPEG, PNG, GIF, HEIC, TIFF, BMP, WebP, RAW itd. zależy od systemu i treści pliku.
- Ogromne obrazy nie są odrzucane tylko dlatego, że przekraczają 150 milionów pikseli. W razie potrzeby podgląd jest zmniejszany zgodnie z budżetem pamięci, przy zachowaniu wymiarów i orientacji źródła. Skala 100% używa źródłowych wymiarów, ale nie odtwarza niezdekodowanych szczegółów.
- Obsługiwane wektorowo: SVG, PDF, AI zgodne z PDF oraz EPS / PS / stare AI przez interpreter. Wielostronicowe PDF / AI / PS można przewijać; SVG odrzuca skrypty i źródła zewnętrzne. Bitmapy wewnątrz wektorów ogranicza źródło; brakujące nieosadzone fonty mogą być zastępowane.
- PostScript działa w osobnym procesie z SAFER i systemową piaskownicą: dostępne są tylko bieżące tymczasowe wejście/wyjście, sieć zabroniona. Szybka zmiana pliku może anulować; miniatury i główny widok współdzielą gotową pamięć podręczną. Jedna interpretacja ma limit 90 sekund, wynik 1 GB, cel czyszczenia cache 2 GB.
- Photoshop PSD / PSB pokazuje zapisany obraz scalony bez edycji warstw. Ogromne płótno otrzymuje podgląd w budżecie pamięci z zachowaniem źródłowych wymiarów; tryby barw, głębie i kompresja są w FORMATS.md.
- Wbudowane dekodowanie zgodności poszerza audio/wideo, lecz DRM, uszkodzone pliki i własnościowe kodeki bez dekodera mogą nie działać. Rozszerzenie nie gwarantuje dekodowania; nie przetestowano osobno wszystkich formatów, urządzeń i wersji systemu.
- Cache zgodności ma cel czyszczenia 2 GB; używane pliki mogą go chwilowo przekraczać. Jeden przygotowany plik ma limit 8 GB i musi pozostać co najmniej 512 MB wolnego dysku. Brak miejsca zatrzymuje przygotowanie z komunikatem.
- TIFF ma strony; pozostałe formaty złożone bez zaimplementowanego podziału pokazują pierwszy obraz. Obrót widoku nie jest zapisywany w oryginale. Brak edycji, usuwania, bazy biblioteki, udostępniania, synchronizacji chmurowej i zarządzania napisami zewnętrznymi.
- Czytane są tylko lokalne media otwarte przez użytkownika i ich folder; przygotowanie zapisuje lokalny cache, nie wysyła mediów i nie zmienia oryginałów.

Dalsze przykłady, granice cache i podglądu: [FORMATS.md](FORMATS.md).

## Budowanie ze źródeł

Wymagane Xcode lub Command Line Tools z kompilatorem Swift. Repozytorium i pakiet źródeł mają uniwersalne narzędzia Intel / Apple Silicon; zwykła kompilacja nie potrzebuje dodatkowych zależności ani pobierania. Po klonowaniu/pobraniu przejdź do katalogu głównego z `build.sh`; dawny układ środowiska dewelopera nie jest potrzebny.

```bash
cd /path/to/LumaView
./build.sh
open ../LumaView.app
```

Domyślnie powstaje aplikacja uniwersalna; `./build.sh --host` kompiluje tylko obecną architekturę. Aplikacja trafia obok źródeł jako `LumaView.app`; inną lokalizację ustawia `LUMAVIEW_APP_PATH`. Katalog roboczy kompilacji/testów to `.build/` w repozytorium, zmieniany przez `LUMAVIEW_WORK_ROOT`; pliki wynikowe wyklucza `.gitignore`.

`LUMAVIEW_TEST_BUILD=1 ./build.sh --host` tworzy osobną aplikację `LumaView Tests`, bez deklarowania skojarzeń, aby testowa kopia nie przejęła ustawień zainstalowanej. Skrypty UI używają tego domyślnie; istniejącą kompilację można wskazać przez `LUMAVIEW_SKIP_TEST_BUILD=1` i `LUMAVIEW_TEST_APP_PATH`.

FFmpeg zbudowano na LGPL 2.1 lub nowszej, statyczny dav1d używa BSD 2-Clause. Odpowiednie archiwa źródłowe, sumy i licencje są w pakiecie. Przebudowa narzędzi wymaga Xcode Command Line Tools, Python 3, Meson 1.12.1 i Ninja 1.13.2; można zainstalować je w środowisku wirtualnym Python i uruchomić `./tools/build-media-tools.sh`. Kroki i konfiguracja: [ThirdParty/README.md](ThirdParty/README.md). PostScript używa osobnego Ghostscript 10.08.0 (AGPL-3.0-or-later), z licencją, pełnym odpowiadającym źródłem i skryptem. Zwykła kompilacja używa gotowych komponentów obu architektur; przebudowa jest w [opisie Ghostscript](ThirdParty/README-Ghostscript.md).

## Źródła i weryfikacja

- `Sources/`: AppKit, płótno mediów, ładowanie obrazów i wektorów, cykl życia audio/wideo, przygotowanie zgodności i ustawienia domyślnej aplikacji.
- `Resources/Localizations/`: tłumaczenia i lista podstawowych kluczy.
- `Resources/MediaFormats.json`: katalog formatów; `Resources/MediaTools/`: FFmpeg / ffprobe.
- `ThirdParty/sources/`, `Resources/ThirdPartyNotices/`: odpowiednie źródła i licencje narzędzi.
- `build.sh`: kompilacja uniwersalna, pakowanie i lokalny podpis; `tools/build-media-tools.sh`: przebudowa narzędzi multimedialnych.

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

Testy jednostkowe dekodowania audio tworzą próbki MP3 / FLAC / Opus i wymagają deweloperskiego FFmpeg z odpowiednimi enkoderami, wskazanego przez `LUMAVIEW_TEST_FFMPEG`. Aplikacja i testy interfejsu audio używają tylko dołączonych komponentów.

Testy integracyjne UI wymagają zalogowanego pulpitu macOS, otwierają aplikację i sprawdzają interakcje na automatycznie generowanych mediach. Kompilacje i raporty są domyślnie w `.build/`; część materiałów roboczych w systemowym katalogu tymczasowym. Testy domyślnie nie czytają prywatnych zdjęć. Kopiowanie przez menu używa osobnego nazwanego schowka i nie nadpisuje schowka użytkownika; testy Otwórz w / Finder / domyślnej aplikacji używają atrap i nie zmieniają skojarzeń. Weryfikacja dostarczonej wersji jest w [TEST-RESULTS.txt](TEST-RESULTS.md).

Raporty w `Tests/` to historyczna weryfikacja odpowiednich wersji, nie dowód automatycznego sukcesu w obecnym środowisku po klonowaniu. Prywatne nazwy próbek zanonimizowano, oryginalne media nie są w repozytorium. Historyczne ścieżki `work/` dokumentują ówczesne źródła testów i nie są wymagane obecnie. Repozytorium zawiera archiwa źródeł, sumy i licencje zewnętrznych narzędzi, więc pierwsze klonowanie jest duże.
