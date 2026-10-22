# LumaView — Polski

<!-- language-navigation:start -->
[简体中文](../../README.md) · [English](README.en.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · **Polski**
<!-- language-navigation:end -->

To krótki przewodnik ułatwiający rozpoczęcie pracy. Pełna dokumentacja jest dostępna w języku [angielskim](README.en.md) oraz [chińskim](../../README.md).

LumaView to natywna aplikacja dla macOS do przeglądania obrazów, filmów, dźwięku i dokumentów wielostronicowych. Sposób szybkiego przeglądania jest inspirowany Picasa Photo Viewer, ale aplikacja ma własną nazwę i ikonę oraz nie jest powiązana z Google. Służy do oglądania plików, a nie do edycji zdjęć lub prowadzenia biblioteki fotograficznej.

## Pobieranie i instalacja

**Wersja 1.7.2, kompilacja 14.** Wymagany jest macOS 13 lub nowszy. Uniwersalna aplikacja działa na komputerach Mac z procesorami Intel i Apple Silicon.

1. Pobierz [LumaView dla macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip). Starsze wersje znajdziesz na stronie [wydań](https://github.com/Uncas-X/LumaView/releases).
2. Rozpakuj archiwum i przeciągnij `LumaView.app` do folderu Aplikacje.
3. Otwórz aplikację. Korzysta z lokalnego podpisu ad hoc i nie została poświadczona przez Apple. Po sprawdzeniu źródła pobrania może być konieczne zezwolenie na jej otwarcie w sekcji **Prywatność i ochrona** ustawień macOS.

## Przeglądanie i funkcje

Przeciągnij plik lub folder do okna albo naciśnij **Cmd+O**. Po otwarciu jednego pliku możesz przechodzić do innych plików multimedialnych w tym samym folderze. Skanowanie obejmuje wyłącznie bieżący poziom folderu, bez podfolderów.

- Pasek miniatur ułatwia wybieranie plików. Dostępne są powiększanie, przesuwanie obrazu, obracanie i pełny ekran, a także płynne przejścia i półprzezroczyste tło z efektem matowego szkła.
- Przezroczyste obszary PNG, GIF, PSD i PSB pozostają przezroczyste; cień podąża za kształtem zawartości. Strony dokumentów mają białe tło papieru. PSD/PSB pokazuje zapisany obraz scalony na potrzeby zgodności, nie poszczególne warstwy.
- Filmy i dźwięk są najpierw odtwarzane natywnie. Dołączony FFmpeg obsługuje dodatkowe formaty, ale niekiedy przed odtwarzaniem musi przygotować cały plik lokalnie. Dla dźwięku wyświetlana jest osadzona okładka, a gdy jej brak — przebieg fali. Przyciski odtwarzania/pauzy i zatrzymania multimediów są niezależne od pokazu slajdów.
- Możesz przeglądać strony PDF, plików AI zgodnych z PDF i wielostronicowych TIFF. SVG, obsługiwane EPS/PS oraz starsze AI są renderowane wektorowo. EPS/PS przetwarza dołączony Ghostscript; osadzone bitmapy nadal mają ograniczenia wynikające z oryginalnej rozdzielczości.
- Menu prawego przycisku myszy pozwala otworzyć plik inną aplikacją, pokazać go w Finderze oraz skopiować obraz, bieżącą klatkę filmu, stronę PDF lub obsługiwany obraz osadzony w PDF.

W ustawieniach wybierzesz formaty, dla których LumaView będzie domyślną aplikacją, oraz język interfejsu. Dostępnych jest 16 języków; domyślnie aplikacja używa języka systemu.

## Skróty klawiszowe

| Klawisz | Działanie |
| --- | --- |
| Cmd+O | Otwórz plik lub folder |
| ← / → | Poprzedni/następny plik lub strona, zależnie od aktywnego poziomu |
| ↑ / ↓ | Przełącz aktywny poziom między stronami i plikami dokumentu wielostronicowego |
| Kółko myszy / gest szczypania / + / − | Zmień powiększenie |
| 0 / 1 | Dopasuj do okna / przełącz między 100% a dopasowaniem |
| Cmd+R | Obróć |
| F | Przełącz pełny ekran |
| P / S | Odtwarzaj lub wstrzymaj multimedia / zatrzymaj |
| Cmd+4 | Steruj pokazem slajdów |
| Cmd+C | Kopiuj obraz, klatkę lub stronę |

**Spacja zmienia tło; nie uruchamia ani nie wstrzymuje odtwarzania.**

## Kompilacja ze źródeł

Zainstaluj Xcode lub narzędzia wiersza poleceń Swift. Repozytorium zawiera wymagane narzędzia multimedialne wraz z odpowiadającymi im archiwami kodu źródłowego i licencjami. Uruchom polecenia z katalogu głównego repozytorium, nie z katalogu tej dokumentacji:

```bash
./build.sh
open ../LumaView.app
```

`./build.sh --host` kompiluje tylko dla architektury bieżącego Maca. Wygenerowane pliki domyślnie trafiają do `.build/`. `LUMAVIEW_WORK_ROOT` zmienia ten katalog, a `LUMAVIEW_APP_PATH` — ścieżkę wynikowej aplikacji.

## Ograniczenia i prywatność

Aplikacja odczytuje lokalne pliki, nie przesyła ich do chmury i nie modyfikuje oryginałów. Nie oferuje edytora, edycji warstw, bazy biblioteki ani synchronizacji z chmurą. Duże obrazy mogą być wyświetlane jako podglądy o zmniejszonej rozdzielczości; powiększanie nie przywróci pominiętych szczegółów. Obsługa wszystkich kodeków nie jest gwarantowana. Pliki chronione DRM, uszkodzone lub nieobsługiwane mogą się nie otworzyć. Konwersja korzysta z lokalnej pamięci podręcznej na dysku i może potrwać.

Zobacz [techniczny opis obsługi formatów](../../FORMATS.md) po chińsku oraz informacje o zewnętrznych [narzędziach multimedialnych](../../ThirdParty/README.md) i [Ghostscript](../../ThirdParty/README-Ghostscript.md).
