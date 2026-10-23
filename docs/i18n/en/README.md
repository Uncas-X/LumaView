# LumaView 1.7.2

<!-- doc-navigation:start -->
[Documentation](INDEX.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · **English** · [日本語](../ja/README.md) · [한국어](../ko/README.md) · [Français](../fr/README.md) · [Deutsch](../de/README.md) · [Español](../es/README.md) · [Italiano](../it/README.md) · [Português (Brasil)](../pt-BR/README.md) · [Русский](../ru/README.md) · [العربية](../ar/README.md) · [हिन्दी](../hi/README.md) · [Türkçe](../tr/README.md) · [Nederlands](../nl/README.md) · [Polski](../pl/README.md)
<!-- doc-navigation:end -->


**[Download the macOS app](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)** · [Releases and release notes](https://github.com/Uncas-X/LumaView/releases)

Requires macOS 13+. The same package supports Intel and Apple Silicon. Extract the downloaded ZIP and drag `LumaView.app` into Applications to install it.

A native macOS media viewer inspired by the quick-viewing habits of Picasa Photo Viewer, with same-folder browsing, zooming, panning, rotation, a filmstrip, fullscreen, and slideshows. Version 1.5 added audio artwork and real waveforms, multi-page document navigation, a vector canvas redrawn at the current zoom, and language settings that follow the system by default. It uses an independent name and original icon and does not claim to reproduce every feature or interaction of historical Picasa releases.

Version 1.7.2 unifies image transparency: transparent areas of raster images such as PNG, GIF, and PSD / PSB reveal the current viewing background. Shadows follow the actual image outline and opacity; there is no checkerboard or rectangular shadow around the entire transparent canvas. Documents such as PDF retain a white paper background.

The PSD / PSB preview improvements from 1.7.1 remain: the filmstrip prefers a valid embedded JPEG, while the main view decodes the actual compatibility composite. RLE uses chunked reads, and a problem that prevented thumbnail generation for some small composites with ICC profiles has been fixed.

## Use and installation

Requires macOS 13 or later, with support for Intel and Apple Silicon.

1. Download `LumaView-macOS.zip` from [Releases](https://github.com/Uncas-X/LumaView/releases), extract it, drag `LumaView.app` into Applications, and open it.
2. Drop an image, video, audio file, or folder onto the app, or press `⌘O` to select files. Opening one file lists media in the same folder; selecting multiple files browses that selection. Folder scans cover the current level only and do not recurse into subfolders.
3. In Finder, you can also right-click a file and choose Open With → LumaView.

Local builds use an ad hoc signature and have not been notarized by Apple. If Gatekeeper blocks a downloaded copy on another Mac, verify its source and use the system's Privacy & Security option to allow it to open.

## Default application settings

Choose **LumaView → Default Application…**, press `⌘,`, or open settings from the More menu. Formats are grouped into images, vectors / documents, video, and audio. Search and select formats, then click Set as Default for Selected Formats. Whenever the dialog opens, the app becomes active again, or changes finish, it reads the actual system associations: a checkmark means every type in the group opens with this copy of LumaView; a dash means only some types do, or they still point to another copy. System associations persist across restarts; unapplied selections are not presented as successfully applied settings. Select All Formats at the top covers all images, vector documents, video, and audio regardless of the search filter; individual categories can still be selected separately. Clear only clears the current selection and does not remove existing system defaults.

Settings display progress and read back each result from the system. Cancel stops subsequent changes; completed changes remain. The format list represents selectable file associations, not a claim that every internal encoding or file has been tested. See [Formats and previews](FORMATS.md) for details.

## Viewing and playback

Opening the first file expands the window to the current screen's available area. Press `F` for fullscreen. Click the bottom filmstrip to change files. Controls hide after the pointer rests in the viewing area for a while and reappear when it moves.

Version 1.5.2 fixed blank or repeatedly flashing thumbnails during extended browsing of large folders: visible thumbnails are retained independently, and offscreen loading is canceled promptly. Results from the previous folder cannot enter the new list. Undecodable files display a stable placeholder and can be retried when their range is revisited.

Images and videos support zoom, pan, rotation, and fullscreen. Window changes, image changes, zooming, and rotation use short smooth transitions that further input can interrupt. Enabling the system's Reduce Motion setting disables these custom transitions while animated images continue playing. The default background is translucent frosted glass; press Space to cycle through frosted, dark, and light backgrounds.

Raster transparency follows one rule: show the current background and cast shadows only from pixels containing visible content, retaining the opacity of translucent edges. GIF / APNG shadows change with each frame. Copying an image preserves its original transparent pixels and excludes the viewer background and shadow.

Audio/video play, stop, position, and volume controls appear above the filmstrip. Media plays automatically when opened and remains at the end when finished; press `P` to replay or `S` to stop and return to the beginning. The slideshow button below is independent of media playback: after `⌘4` starts continuous playback, images advance at the selected interval, while audio/video finishes before advancing. Playing an individual audio/video file does not automatically move to the next item.

Native macOS playback is tried first. If the system cannot play the file directly, bundled universal FFmpeg 9.0.2 and dav1d 1.5.3 prepare a compatible file locally, attempting a container change first where appropriate and then transcoding. No separate player, Homebrew, or codec pack is needed, and no network access is used. Compatibility playback waits for the entire file to be prepared, showing progress; changing files or closing the window cancels preparation. Preparing a long video for the first time may take substantial time and extra disk space.

Press `C` or use the More menu to configure looping, wheel behavior, background-click closing, the filmstrip, sorting, and slideshow intervals (2, 3, 5, 8, or 10 seconds). The wheel zooms by default; hold `Ctrl` to browse files temporarily. If the wheel is set to browse, `Ctrl` temporarily zooms instead. Clicking the background outside the image closes the viewer by default. These preferences are stored locally.

## Context menu and copying

Right-click (or Control-click) the main view to choose Open With → Application / Other Application… or Show in Finder. Open With affects this opening only and does not change default associations. Both options remain available for undecodable files.

- Images: choose Copy Image. This preserves view rotation and transparent pixels and copies the entire currently decoded image, without capturing toolbars or only the zoomed screen region.
- Video: choose Copy Current Frame. This copies the frame corresponding to the moment the context menu opened, preserving video orientation and view rotation without changing playback position or state.
- PDF / PDF-compatible AI: right-click a bitmap on a page to Copy This Image, or choose Copy Current Page. Hit detection follows the actual position after zooming, panning, and rotation. Ordinary text and vector regions are not treated as images; complex masks or color spaces use the visible result of the image region, which may include overlaid text. A page scanned as one image is copied as the entire scan.
- `⌘C` copies the current image, video frame, or document page; audio does not provide image copying. The clipboard receives PNG and TIFF. Changing files / pages or closing the viewer prevents stale copy results from overwriting the clipboard.

Copies of document pages and embedded images are bitmaps limited to a longest side of 8192 pixels and approximately 32 megapixels; PDF/SVG vector instructions are not placed on the clipboard. If a large image is displaying a bounded preview, that preview is copied. PDF image scanning has complexity limits: special structures such as images inside pattern fills may not be individually selectable, but the current page can still be copied.

Standard SVG 1.0/1.1 headers are parsed offline without loading external DTDs. Version 1.7 bundles Ghostscript 10.08.0 to convert EPS / PostScript and legacy PostScript AI to PDF while retaining paths, text, and embedded images. The main view redraws vectors at the current zoom; multi-page PS uses the existing page navigation. No additional installation is required. If conversion fails but the EPS has a valid embedded TIFF, it can fall back to that preview, clearly labeled TIFF. Raster images inside the original do not become vectors.

## Audio, documents, and languages

Audio uses embedded artwork in the main view when available. Otherwise, actual samples are analyzed asynchronously to display a waveform for the full track. A placeholder appears during analysis, and playback does not need to wait. Audio and video thumbnails use the same `▶ duration` badge at the lower right, with matching font, background, and position; before duration is available, they show `▶ –:––`. Artwork comes from embedded file metadata, without searching the network or neighboring files.

PDF, PDF-compatible AI, and multi-page TIFF support page browsing. Smaller page thumbnails, a page-progress slider, and current / total page numbers appear above the file filmstrip. Press `↑` to focus pages and `↓` to focus files. The selected thumbnail in the focused row has an orange border; the other row retains its selection with a gray border. No extra Pages / Files labels are shown. `←` / `→`, `J` / `K`, and `Home` / `End` act on the current focus. Clicking a row also focuses it. Page navigation stops at the first and last pages without unexpectedly moving to another file. The lower previous / next file buttons always change files. Page navigation remains available when the file filmstrip is hidden.

PDF, SVG, and PDF-compatible AI draw the visible region from original vector instructions at the current zoom, instead of enlarging a fixed preview. Transparent document regions use plain white paper, without a checkerboard. Changing pages waits for the complete new page before a whole-page fade; background vector-detail drawing does not leave blank tiles appearing one at a time. Embedded photos and other bitmaps remain limited by their original resolution.

Choose **LumaView → Language…**, also available in the More menu. The default follows the system, with support for Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, Portuguese, Russian, Arabic, Hindi, Turkish, Dutch, and Polish. App menus, tooltips, pagination, and settings update immediately, and the selected language is saved locally. Unsupported system languages fall back to English; uncommon decoding errors may also appear in English. Filenames, paths, and text inside files remain unchanged.

## Keyboard and mouse

| Action | Shortcut / gesture |
| --- | --- |
| Previous / next item (current focus) | `←` / `→`, or `J` / `K` |
| Focus pages / files | `↑` / `↓` (multi-page documents) |
| First / last item | `Home` / `End` |
| Open files or a folder | `⌘O` |
| Default application settings | `⌘,` |
| Zoom | Wheel, trackpad pinch, `+` / `−`, `Page Up` / `Page Down` |
| Temporarily switch wheel behavior | Hold `Ctrl` while scrolling |
| 100% / fit to window | Click the image, or `1` |
| Fit to window | `0` |
| Pan a zoomed image or video | Drag the view |
| Rotate view clockwise | `⌘R` / `Ctrl+R`; add `Shift` for counterclockwise |
| Cycle backgrounds | Space |
| Enter / leave fullscreen | `F` / `⌃⌘F` / `F11` (when not reserved by the system) |
| Play / pause audio or video | `P` |
| Stop media and return to the start | `S` |
| Start / stop slideshow and continuous playback | `⌘4` |
| Seek media backward / forward 5 seconds | `Option + ←` / `Option + →` |
| Mute / unmute | `M` |
| File information | `I` / `⌘I` |
| Show / hide filmstrip | `T` / `⌘T` |
| More options | `C` |
| Show the current file in Finder | `⌘Return` |
| Pause playback, close information, exit fullscreen, close the window | `Esc`, handled in order according to current state |
| Minimize / close / quit | `⌘M` / `⌘W` / `⌘Q` |

`P` controls only the current audio/video, not image slideshows. Help → Keyboard and Mouse also provides an in-app guide.

## Coverage and limitations

- Images use system ImageIO decoding. Actual support for JPEG, PNG, GIF, HEIC, TIFF, BMP, WebP, RAW, and other formats depends on the system version and file contents.
- Very large images are no longer rejected solely for exceeding 150 megapixels. To limit memory, previews may be downsampled while preserving original dimensions and orientation metadata. 100% zoom is still calculated from original dimensions, but cannot recover pixel detail omitted from the preview decoding.
- Vector display supports SVG, PDF, PDF-compatible AI, and EPS / PS / legacy AI processed by the bundled interpreter. Multi-page PDF / AI / PS supports navigation; SVG rejects scripts and external resources. Embedded bitmaps retain their original resolution limits, and unavailable nonembedded fonts may be substituted.
- PostScript runs in a separate process with SAFER and a system sandbox, allowing only the staged input and output and denying network access. Rapid file changes can cancel it; thumbnails and the main view share completed cached results. Each interpretation is limited to 90 seconds and 1 GB of output, with a cache cleanup target of 2 GB.
- Photoshop PSD / PSB shows the composite saved in the file, without layer editing. Very large canvases use memory-budgeted previews and retain original dimensions; see FORMATS.md for supported color modes, bit depths, and compression.
- Bundled fallback decoding expands audio/video coverage, but DRM, damaged files, and proprietary encodings without an available decoder may still fail. An extension does not guarantee that the internal encoding can be decoded. Not every format, device, or system version has been individually tested.
- The compatibility cache has a 2 GB cleanup target; active files can temporarily exceed it. A single prepared file is limited to 8 GB, with at least 512 MB of free disk space reserved. Preparation stops and displays a message if space is insufficient.
- TIFF supports multiple pages; other compound image formats without implemented pagination show the first image. Viewing rotation never writes back to originals. Editing, deletion, a library database, sharing, cloud synchronization, and external subtitle management are not provided.
- The app reads only local media opened by the user and its containing folder. Compatibility playback writes to a local cache; it does not upload media or modify originals.

See [FORMATS.md](FORMATS.md) for more format examples and cache / preview boundaries.

## Build from source

Requires Xcode or Command Line Tools with the Swift compiler. The repository and source package include universal Intel / Apple Silicon media tools, so a normal build requires no separate third-party installation or download. After cloning or downloading, build from the repository root containing `build.sh`; the original development workspace layout is not required.

```bash
cd /path/to/LumaView
./build.sh
open ../LumaView.app
```

The default produces a universal app; `./build.sh --host` builds only the current Mac architecture. The app is placed beside the source directory as `LumaView.app` by default; set `LUMAVIEW_APP_PATH` for another destination. Build and test working files default to `.build/` inside the repository and can be relocated with `LUMAVIEW_WORK_ROOT`. These generated files are excluded by `.gitignore`.

Test builds use `LUMAVIEW_TEST_BUILD=1 ./build.sh --host` to create a separate LumaView Tests app without file-opening declarations, preventing test copies from competing with the installed app. UI test scripts use this mode by default. Use `LUMAVIEW_SKIP_TEST_BUILD=1` and `LUMAVIEW_TEST_APP_PATH` to select an already-built app.

FFmpeg is built under LGPL 2.1 or later, and statically linked dav1d uses BSD 2-Clause. Corresponding source archives, checksums, and licenses accompany the source package. Rebuilding the media tools requires Xcode Command Line Tools, Python 3, Meson 1.12.1, and Ninja 1.13.2; install the Python tools in a virtual environment and run `./tools/build-media-tools.sh`. See [ThirdParty/README.md](ThirdParty/README.md) for steps and build configuration. PostScript uses a separate Ghostscript 10.08.0 executable (AGPL-3.0-or-later), with its license, complete corresponding source, and build script included. Normal app builds use the bundled universal component; see the [Ghostscript guide](ThirdParty/README-Ghostscript.md) for rebuilding.

## Source and validation

- `Sources/`: AppKit interface, media canvas, raster and vector loading, audio/video lifecycle, compatibility preparation, and default application settings.
- `Resources/Localizations/`: language strings and the core translation key list.
- `Resources/MediaFormats.json`: format catalog; `Resources/MediaTools/`: bundled FFmpeg / ffprobe.
- `ThirdParty/sources/`, `Resources/ThirdPartyNotices/`: corresponding media-tool sources and licenses.
- `build.sh`: universal app compilation, packaging, and local signing; `tools/build-media-tools.sh`: rebuilding media tools.

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

Audio decoding unit tests need a development FFmpeg with the relevant encoders to generate MP3 / FLAC / Opus samples. Set `LUMAVIEW_TEST_FFMPEG` to its path. The app and audio interface tests use only bundled components.

UI integration checks require a logged-in macOS graphical desktop. They open the app and check interactions using generated media. Build files and saved test reports default to `.build/`; some runtime fixtures use the system temporary directory. Tests do not read personal photos by default. Context-menu copying tests use a separate named clipboard without replacing the user's current clipboard. Open With / Finder / default-application tests use mocks and do not change file associations. See [TEST-RESULTS.txt](TEST-RESULTS.md) for the delivered version's validation record.

Saved reports in `Tests/` are historical records for their respective versions, not evidence that a fresh checkout has automatically passed tests in the current environment. Personal sample names are anonymized, and original media is not included in the repository. Historical `work/` paths record the test sources at that time and are not required directories for current builds. The repository preserves corresponding third-party source archives, checksums, and licenses, so the initial clone is relatively large.
