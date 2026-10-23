# Встроенные медиаинструменты

<!-- doc-navigation:start -->
[Документация](../INDEX.md) · [简体中文](../../zh-Hans/ThirdParty/README.md) · [繁體中文](../../zh-Hant/ThirdParty/README.md) · [English](../../en/ThirdParty/README.md) · [日本語](../../ja/ThirdParty/README.md) · [한국어](../../ko/ThirdParty/README.md) · [Français](../../fr/ThirdParty/README.md) · [Deutsch](../../de/ThirdParty/README.md) · [Español](../../es/ThirdParty/README.md) · [Italiano](../../it/ThirdParty/README.md) · [Português (Brasil)](../../pt-BR/ThirdParty/README.md) · **Русский** · [العربية](../../ar/ThirdParty/README.md) · [हिन्दी](../../hi/ThirdParty/README.md) · [Türkçe](../../tr/ThirdParty/README.md) · [Nederlands](../../nl/ThirdParty/README.md) · [Polski](../../pl/ThirdParty/README.md)
<!-- doc-navigation:end -->


LumaView запускает неизменённые FFmpeg 9.0.2 и ffprobe отдельными локальными процессами. Они собраны из исходников для Intel и Apple Silicon с целью macOS 13, используют статически связанный dav1d 1.5.3 для AV1 и только системные динамические библиотеки. Во время работы Homebrew и VLC не нужны.

FFmpeg настроен по LGPL 2.1 или новее, без `--enable-gpl` и `--enable-nonfree`. dav1d использует BSD 2-Clause. Полные лицензии находятся в `Resources/ThirdPartyNotices` и копируются в пакет приложения. Точные неизменённые соответствующие архивы исходников включены в `sources/` с SHA-256. Все флаги и этапы сборки — в `tools/build-media-tools.sh`. LumaView не накладывает дополнительных ограничений на изменение или замену этих отдельных инструментов, а также обратную разработку, необходимую для отладки таких изменений.

Официальные источники:

- [Выпуск и подпись FFmpeg](https://ffmpeg.org/download.html): `https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz`. Отдельная подпись проверена по ключу выпуска FFmpeg `FCF986EA15E6E293A5644F10B4322F04D67658D8`.
- [Выпуск dav1d](https://downloads.videolan.org/pub/videolan/dav1d/1.5.3/): `dav1d-1.5.3.tar.xz`.
- [Информация о лицензии FFmpeg](https://ffmpeg.org/legal.html).

## Пересборка

Обычная сборка приложения использует готовые универсальные бинарные файлы. Для пересборки инструментов установите Xcode Command Line Tools, Python 3, Meson 1.12.1 и Ninja 1.13.2. Например, создайте локальное виртуальное окружение Python и установите в нём `meson==1.12.1 ninja==1.13.2`. Активируйте его и выполните:

```sh
./tools/build-media-tools.sh
./build.sh
```

Первая команда проверяет контрольные суммы исходников, компилирует обе архитектуры и заменяет `Resources/MediaTools/{ffmpeg,ffprobe}`. `LUMAVIEW_PYTHON` выбирает Python, `LUMAVIEW_MEDIA_BUILD` — промежуточную папку. Аргумент `x86_64` или `arm64` собирает одну архитектуру; стандартный `universal` объединяет обе. Сборка приложения подписывает вложенные инструменты и приложение локальной ad-hoc-подписью.

Сеть, устройства захвата, ffplay, внешние кодеки кроме dav1d и GPL-энкодеры отключены. Включены все внутренние декодеры/демультиплексоры, доступные этой конфигурации. Аудио подготавливается как AAC; видео по возможности меняет контейнер, затем использует совместимый вывод VideoToolbox H.264, MPEG-4 или ProRes. Это путь просмотра, а не интерфейс экспорта или перекодирования.

## Векторный интерпретатор PostScript

Предпросмотр EPS, PostScript и старого Illustrator дополнительно использует встроенный Ghostscript 10.08.0 отдельным ограниченным локальным подпроцессом. Его лицензия AGPL-3.0-or-later, полный соответствующий архив, контрольные суммы и воспроизводимая универсальная сборка описаны в [README-Ghostscript.md](README-Ghostscript.md). Обычная сборка не требует системной установки Ghostscript.
