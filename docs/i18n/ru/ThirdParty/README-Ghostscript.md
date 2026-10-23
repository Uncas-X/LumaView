# Инструмент преобразования документов Ghostscript

<!-- doc-navigation:start -->
[Документация](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../../zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../../en/ThirdParty/README-Ghostscript.md) · [日本語](../../ja/ThirdParty/README-Ghostscript.md) · [한국어](../../ko/ThirdParty/README-Ghostscript.md) · [Français](../../fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../../de/ThirdParty/README-Ghostscript.md) · [Español](../../es/ThirdParty/README-Ghostscript.md) · [Italiano](../../it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README-Ghostscript.md) · **Русский** · [العربية](../../ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../../hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../../tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../../nl/ThirdParty/README-Ghostscript.md) · [Polski](../../pl/ThirdParty/README-Ghostscript.md)
<!-- doc-navigation:end -->


LumaView запускает Ghostscript **10.08.0**, выпущенный Artifex 2026-09-08, отдельным локальным исполняемым файлом для преобразования EPS и PostScript во временный PDF. PDF сохраняет поддерживаемые векторные пути, текст и градиенты. Уже встроенные растровые изображения остаются растровыми. Ghostscript не связывается со Swift-приложением, и для запуска встроенного файла не нужна установка Homebrew.

## Лицензия и соответствующие исходники

Ghostscript распространяется по **GNU Affero General Public License версии 3 или новее**, как указано в оригинальном `LICENSE` этого выпуска. Полная лицензия, уведомление об авторских правах Ghostscript, исключение для встраивания шрифтов, уведомления Adobe CMap и зависимостей без изменений копируются в `Resources/ThirdPartyNotices/Ghostscript/`. Artifex также предлагает отдельную коммерческую лицензию; этот пакет её не включает. См. [официальную страницу лицензирования](https://www.ghostscript.com/licensing/index.html).

Точный неизменённый соответствующий выпуск исходников, включая зависимости и шрифты, находится в `ThirdParty/sources/ghostscript-10.08.0.tar.xz`. Его SHA-256 записан в `ThirdParty/sources/SHA256SUMS-Ghostscript`:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

Происхождение исходников: [официальная страница выпуска](https://www.ghostscript.com/releases/index.html) и [файлы выпуска Artifex 10.08.0](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). Контрольная сумма совпадает с опубликованной для `.tar.xz`. Архив и этот скрипт сборки сопровождают исходный дистрибутив LumaView. LumaView не ограничивает дополнительно изменение/замену отдельного инструмента или обратную разработку для отладки изменений. Уведомления описывают встроенный сторонний компонент и не изменяют лицензию исходников приложения.

## Пересборка

Требования: macOS, Xcode Command Line Tools, включённый исходный архив и стандартные инструменты сборки macOS. Библиотеки Homebrew не используются. Из каталога исходников LumaView:

```sh
./tools/build-document-tools.sh
./build.sh
```

Скрипт проверяет архив, собирает срезы Intel и Apple Silicon в отдельных исходных каталогах, удаляет локальные символы и объединяет срезы в `Resources/DocumentTools/gs`. Оба предназначены для macOS 13.0 и новее. `make install` не запускается, системный менеджер пакетов не изменяется. `LUMAVIEW_DOCUMENT_BUILD` выбирает промежуточную папку; `LUMAVIEW_DOCUMENT_JOBS` задаёт параллелизм make (по умолчанию 4). Необязательный `x86_64` или `arm64` собирает одну архитектуру. Сборка приложения подписывает скопированный инструмент вместе с приложением.

Исполняемый файл содержит код инициализации, встроенные шрифты, Adobe CMaps и ICC-профили во внутренней файловой системе `%rom%`. Внешние стандартные пути поиска пусты. Разрешено только выходное устройство `pdfwrite`. Печать/CUPS, X11, GTK, fontconfig, D-Bus, Tesseract/OCR, динамические драйверы, внешний IJS и инструменты извлечения документов отключены. Все библиотеки декодирования/цвета/шрифтов собираются из соответствующего исходного архива; динамические связи ограничены системными библиотеками Apple. Механизмы ROM и кросс-компиляции описаны в [официальной документации сборки](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html).

LumaView запускает интерпретатор с `-dSAFER`, конкретными входным и выходным файлами, приватным временным рабочим каталогом, отменой и тайм-аутом. Окружение процесса не должно наследовать заданные пользователем параметры Ghostscript и пути библиотек. Пример для сгенерированных доверенных тестовых файлов:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

Полные параметры сборки находятся в `tools/build-document-tools.sh`; исходный архив не патчится. Нативный запуск можно проверить только для архитектур, поддерживаемых хостом сборки. Проверки выпуска анализируют оба среза Mach-O и прогоняют сгенерированный EPS с путями и текстом через совместимый с хостом срез, подтверждая наличие в PDF векторных и текстовых операторов.
