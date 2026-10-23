# Konwersja dokumentów przez Ghostscript

<!-- doc-navigation:start -->
[Dokumentacja](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../../ru/ThirdParty/README-Ghostscript.md) · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · **Polski**
<!-- doc-navigation:end -->


LumaView uruchamia Ghostscript **10.08.0**, wydany przez Artifex 2026-09-08, jako osobny lokalny program konwertujący EPS i PostScript na tymczasowy PDF. PDF zachowuje obsługiwane ścieżki wektorowe, tekst i gradienty. Osadzone rastry pozostają rastrami. Ghostscript nie jest linkowany do aplikacji Swift, a do uruchomienia dołączonego programu nie potrzeba Homebrew.

## Licencja i odpowiadające źródła

Ghostscript jest rozpowszechniany na **GNU Affero General Public License wersja 3 lub nowsza**, zgodnie z oryginalnym `LICENSE` tego wydania. Pełna licencja, prawa autorskie Ghostscript, wyjątek osadzania fontów, informacje Adobe CMap i zależności są kopiowane bez zmian do `Resources/ThirdPartyNotices/Ghostscript/`. Artifex oferuje osobną licencję komercyjną; ten pakiet jej nie zawiera. Zobacz [oficjalną stronę licencji](https://www.ghostscript.com/licensing/index.html).

Dokładne niezmienione odpowiadające wydanie źródeł, wraz z zależnościami i fontami, jest w `ThirdParty/sources/ghostscript-10.08.0.tar.xz`. SHA-256 zapisano w `ThirdParty/sources/SHA256SUMS-Ghostscript`:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

Pochodzenie: [oficjalna strona wydań](https://www.ghostscript.com/releases/index.html) i [zasoby Artifex 10.08.0](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). Suma zgadza się z opublikowaną dla `.tar.xz`. Pakiet źródeł i skrypt towarzyszą dystrybucji źródłowej LumaView. LumaView nie ogranicza dodatkowo modyfikacji/zamiany narzędzia ani inżynierii wstecznej koniecznej do debugowania. Te informacje opisują obcy komponent, nie zmieniają licencji kodu aplikacji.

## Przebudowa

Wymagania: macOS, Xcode Command Line Tools, dołączone archiwum i standardowe narzędzia macOS. Biblioteki Homebrew nie są używane. Z katalogu źródłowego LumaView:

```sh
./tools/build-document-tools.sh
./build.sh
```

Skrypt sprawdza archiwum, buduje części Intel i Apple Silicon z osobnych katalogów, usuwa symbole lokalne i łączy do `Resources/DocumentTools/gs`. Obie celują w macOS 13.0 lub nowszy. Nie uruchamia `make install` ani nie zapisuje w systemowym menedżerze pakietów. `LUMAVIEW_DOCUMENT_BUILD` wybiera katalog pośredni, `LUMAVIEW_DOCUMENT_JOBS` równoległość make (domyślnie 4). Opcjonalne `x86_64` lub `arm64` buduje jedną architekturę. Budowa aplikacji podpisuje skopiowany program razem z appką.

Program zawiera inicjalizację, fonty, Adobe CMaps i ICC w wewnętrznym systemie `%rom%`. Domyślne zewnętrzne ścieżki wyszukiwania są puste. Włączone jest tylko wyjście `pdfwrite`. Druk/CUPS, X11, GTK, fontconfig, D-Bus, Tesseract/OCR, dynamiczne sterowniki, zewnętrzny IJS i narzędzia ekstrakcji dokumentów są wyłączone. Wszystkie biblioteki dekodowania/koloru/fontów pochodzą z odpowiadającego archiwum; dynamicznie linkowane są tylko biblioteki Apple. ROM i kompilacja skrośna: [oficjalna dokumentacja budowy](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html).

LumaView uruchamia interpreter z `-dSAFER`, konkretnym wejściem/wyjściem, prywatnym katalogiem tymczasowym, anulowaniem i limitem czasu. Środowisko procesu nie może dziedziczyć opcji ani ścieżek bibliotek Ghostscript ustawionych przez użytkownika. Przykład dla wygenerowanych zaufanych próbek:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

Pełne opcje są w `tools/build-document-tools.sh`; źródło nie jest łatane. Natywne uruchomienie można sprawdzić tylko dla architektur hosta. Kontrole wydania analizują obie części Mach-O i przepuszczają wygenerowany EPS ze ścieżkami i tekstem przez część zgodną z hostem, potwierdzając operatory wektorowe i tekstowe w PDF.
