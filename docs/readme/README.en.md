# LumaView 1.7.2 — English

<!-- language-navigation:start -->
[简体中文](../../README.md) · **English** · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [हिन्दी](README.hi.md) · [Türkçe](README.tr.md) · [Nederlands](README.nl.md) · [Polski](README.pl.md)
<!-- language-navigation:end -->

**[Download LumaView for macOS](https://github.com/Uncas-X/LumaView/releases/latest/download/LumaView-macOS.zip)** · **[All releases](https://github.com/Uncas-X/LumaView/releases)** · [中文完整说明](../../README.md)

This is the full English manual for **LumaView 1.7.2, build 14**, a native macOS viewer for images, video, audio, and multi-page documents. Its quick-browsing workflow is inspired by Picasa Photo Viewer: open a file, browse neighboring media, zoom, pan, rotate, and use a filmstrip or slideshow. LumaView has its own name and original icon and is not affiliated with Google. It focuses on viewing rather than editing or managing a photo library, and does not claim to reproduce every historical Picasa feature or interaction.

## Download and install

Requires **macOS 13 or later**. The app is a universal binary for Intel and Apple Silicon Macs.

1. Download the ZIP above and extract it.
2. Drag `LumaView.app` into **Applications**, then open it.
3. Drop an image, video, audio file, or folder onto the app, or press `⌘O` to choose files. You can also use **Open With → LumaView** in Finder.

Opening a single file lists supported media in the same folder. Selecting multiple files browses that selection. Folder scans include only the current level; subfolders are not scanned recursively.

The app uses a local **ad hoc signature** and has **not been notarized by Apple**. If macOS blocks a downloaded copy, verify its source and use the relevant **Privacy & Security** option to allow it to open. There is no need to disable Gatekeeper.

## Default application settings

Choose **LumaView → Default Application…**, press `⌘,`, or open the corresponding item in the More menu. Search or select formats grouped into images, vectors/documents, video, and audio, then apply LumaView as the default application for the selected formats.

The dialog reads the actual system associations when it opens, when the app becomes active again, and after changes are applied. A checkmark means all types in a group point to this copy of LumaView; a mixed state means only some types do, or an association points to another copy. System associations persist across app restarts. Unapplied selections are not shown as successful changes.

**Select All Formats** includes every image, vector/document, video, and audio format, regardless of the current search. Individual groups can also be selected. Clearing the selection only clears the current choices; it does not remove existing system associations.

Progress and the results read back from macOS are shown while applying changes. Cancel stops subsequent changes but leaves completed changes in place. The format list describes available file associations, not a guarantee that every codec or file has been tested. See [format coverage and preview limits](../../FORMATS.md) in Chinese.

## Viewing and playback

Opening the first file expands the window to the screen's available area; press `F` for fullscreen. Click the bottom filmstrip to switch files. Controls hide after the pointer rests over the viewing area and reappear when it moves.

Images and video support zooming, panning, rotation, and fullscreen. Opening, switching, zooming, and rotation use short, interruptible transitions. macOS **Reduce Motion** disables these custom transitions without stopping animated images. The default background is translucent frosted glass; press **Space** to cycle through frosted, dark, and light backgrounds.

Raster transparency is consistent across formats, including PNG, GIF, PSD, and PSB: transparent pixels reveal the current background, and shadows follow the visible content and its alpha rather than the full rectangular canvas. GIF/APNG shadows update with each frame. Copying an image preserves its transparent pixels without adding the viewer background or shadow. Document pages retain a white paper background.

Visible file thumbnails remain retained, requests for offscreen thumbnails are canceled, and results from a previous folder cannot overwrite the new list. Files that cannot be decoded use a stable placeholder and may be retried when that range is revisited. PSD/PSB thumbnails prefer a valid embedded JPEG; the main image uses the saved compatibility composite, not the thumbnail or an editable layer stack.

Media playback, stop, position, and volume controls sit **above the file filmstrip**. Audio and video start automatically, then remain at the end when finished. Press `P` to replay, or `S` to stop and return to the beginning. The slideshow button is separate: `⌘4` starts continuous browsing, advances images at the selected interval, and waits for audio/video to finish before moving on. Playing a single media file does not automatically advance to the next file.

Native macOS playback is used first. When required, bundled universal **FFmpeg 9.0.2** and **dav1d 1.5.3** prepare a compatible local file, trying a container change first where appropriate and transcoding when necessary. No separate player, Homebrew installation, codec pack, or network access is needed. Fallback playback waits for the **entire file** to be prepared and displays progress. Switching files or closing the window cancels preparation. Long videos can take time and require additional disk space on first playback.

Press `C` or use the More menu to configure looping, wheel behavior, closing by clicking the background, the filmstrip, sorting, and slideshow intervals of 2, 3, 5, 8, or 10 seconds. The wheel zooms by default; hold `Ctrl` to browse files instead. If the wheel is configured to browse, `Ctrl` temporarily zooms. Clicking the background outside the image closes the viewer by default. Preferences are saved locally.

## Context menus and copying

Right-click or Control-click the main viewing area to **Open With → application / Other Application…** or **Show in Finder**. Open With affects only this opening and does not change default associations. These commands remain available for files that cannot be decoded.

- **Images:** Copy Image copies the entire currently decoded image, preserving its view rotation and transparent pixels. It does not capture the toolbar or only the visible, zoomed-in screen area.
- **Video:** Copy Current Frame copies the frame corresponding to when the context menu was opened, preserving video orientation and view rotation without changing playback position or state.
- **PDF / PDF-compatible AI:** Right-click a supported embedded bitmap to Copy This Image, or choose Copy Current Page. Hit detection follows the actual click position after zooming, panning, or rotation. Text and vector regions are not treated as embedded images. Complex masks or color spaces may require copying the visible image region, which can include overlaid text. A page consisting of one scanned image is copied as that entire scan.
- **`⌘C`:** Copies the current image, video frame, or document page. Audio does not offer image copying. The clipboard receives PNG and TIFF data. If the file/page changes or the viewer closes, a stale asynchronous copy cannot overwrite the clipboard.

Document pages and embedded images are copied as bitmaps limited to a longest side of 8192 pixels and approximately 32 megapixels, not as PDF/SVG vector instructions. If a large image is displayed using a bounded preview, copying uses that preview. PDF image discovery has complexity limits; special structures such as images inside pattern fills may not be individually selectable, but the current page can still be copied.

## Audio, documents, and vectors

Audio displays **embedded cover art** when available. Otherwise, the app asynchronously analyzes real audio samples and displays a waveform for the full track. A placeholder is shown during analysis; playback need not wait for the waveform. Artwork comes from embedded metadata, not the network or neighboring image files. Audio and video filmstrip thumbnails share the same `▶ duration` badge; an unread duration appears as `▶ –:––`.

PDF, PDF-compatible AI, multi-page PostScript, and multi-page TIFF support page browsing. Smaller page thumbnails, a page-position slider, and the current/total page count appear above the file filmstrip. Press `↑` to focus pages and `↓` to focus files. An orange border marks the selection in the focused row; the other row retains its selection with a gray border. There are no extra Pages/Files labels.

`←` / `→`, `J` / `K`, and `Home` / `End` act on the focused row. Clicking a row focuses it. Page navigation stops at the document's beginning or end rather than jumping to another file. The lower previous/next-file buttons always switch files. Hiding the file filmstrip leaves page navigation available.

PDF, SVG, and PDF-compatible AI draw the visible region from vector instructions at the current zoom. Transparent document areas use white paper. When changing pages, the complete new page is prepared before a whole-page fade; background vector-detail rendering does not leave blank tiles appearing one by one. Embedded photos and other bitmaps remain limited by their source resolution.

Standard SVG 1.0/1.1 headers are parsed offline without loading external DTDs. SVG scripts and external resources are rejected. Bundled **Ghostscript 10.08.0** converts supported EPS, PostScript, and legacy PostScript AI into PDF while preserving paths, text, and embedded images for zoom-dependent vector drawing. No additional installation is required. If conversion fails but an EPS contains a valid embedded TIFF, that preview may be used and is identified as TIFF. Embedded raster content does not become vector content.

## Language settings

Choose **LumaView → Language…**, also available in the More menu. The default follows the system language. The app supports 16 languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, Portuguese, Russian, Arabic, Hindi, Turkish, Dutch, and Polish.

Menus, tooltips, page controls, and settings update immediately, and the choice is saved locally. Unsupported system languages fall back to English; some uncommon decoder errors may also appear in English. File names, paths, and text inside files are unchanged.

## Keyboard and mouse reference

| Action | Shortcut or gesture |
| --- | --- |
| Previous / next item in the focused row | `←` / `→`, or `J` / `K` |
| Focus pages / files in a multi-page document | `↑` / `↓` |
| First / last item in the focused row | `Home` / `End` |
| Open files or a folder | `⌘O` |
| Default application settings | `⌘,` |
| Zoom | Wheel, trackpad pinch, `+` / `−`, `Page Up` / `Page Down` |
| Temporarily switch wheel behavior | Hold `Ctrl` while scrolling |
| Toggle 100% / fit to window | Click the image, or `1` |
| Fit to window | `0` |
| Pan a zoomed image or video | Drag the viewing area |
| Rotate clockwise | `⌘R` / `Ctrl+R`; add `Shift` for counterclockwise |
| Cycle backgrounds | **Space** |
| Enter / leave fullscreen | `F` / `⌃⌘F` / `F11` when not reserved by macOS |
| Play / pause current audio or video | `P` |
| Stop media and return to the start | `S` |
| Start / stop slideshow and continuous playback | `⌘4` |
| Seek media backward / forward by 5 seconds | `Option+←` / `Option+→` |
| Mute / unmute | `M` |
| Copy current image, video frame, or document page | `⌘C` |
| File information | `I` / `⌘I` |
| Show / hide file filmstrip | `T` / `⌘T` |
| More options | `C` |
| Show current file in Finder | `⌘Return` |
| Pause playback, close information, leave fullscreen, or close the window, according to state | `Esc` |
| Minimize / close / quit | `⌘M` / `⌘W` / `⌘Q` |

`P` controls only the current audio/video, not the image slideshow. **Space changes the background; it is not play/pause.** The Help menu also includes an in-app keyboard and mouse guide.

## Format coverage, privacy, and limits

- Images use macOS ImageIO. Actual JPEG, PNG, GIF, HEIC, TIFF, BMP, WebP, RAW, and other support depends on the system version and file contents.
- Very large images are no longer rejected solely for exceeding 150 megapixels. A bounded, downsampled preview may be used to control memory while retaining original dimensions and orientation. The 100% scale is calculated from the original dimensions, but zooming cannot recover details omitted from the decoded preview.
- PSD/PSB displays the composite saved by Photoshop, without layer editing. Very large canvases receive a preview within the memory budget. See [FORMATS.md](../../FORMATS.md) for color-mode, bit-depth, and compression coverage.
- Vector viewing supports SVG, PDF, PDF-compatible AI, and supported EPS/PS/legacy AI through the bundled interpreter. Missing nonembedded fonts may be substituted. Embedded bitmaps remain constrained by their original resolution.
- PostScript runs in a separate process with SAFER and a system sandbox, restricted to the staged input/output and denied network access. It is cancellable on file changes; thumbnails and the main view share completed conversions. Each interpretation is limited to 90 seconds and 1 GB of output, with a cache cleanup target of 2 GB.
- Native and fallback media decoding do not guarantee every codec. DRM-protected, damaged, or proprietary unsupported files may fail. An extension does not guarantee the internal codec is decodable, and not every format, device, or OS version has been tested.
- The compatibility playback cache has a 2 GB cleanup target; active files may temporarily exceed it. A prepared file is limited to 8 GB, with at least 512 MB of free disk space reserved. Preparation stops with a message if space is insufficient.
- TIFF supports multiple pages. Other compound image formats without implemented page navigation show their first image. Viewing rotations never write back to the original.
- LumaView does not provide editing, deletion, layer editing, a photo-library database, sharing, cloud synchronization, or external subtitle management.
- The app reads local media opened by the user and its containing folder. Compatibility preparation writes local cache files. It does not upload media or modify the original files.

Additional format examples and cache/preview boundaries are documented in [FORMATS.md](../../FORMATS.md), in Chinese.

## Build from source

Requires Xcode or Command Line Tools with the Swift compiler. The repository and source package include universal Intel/Apple Silicon media tools, so a normal app build does not require separately installing or downloading third-party dependencies. Use the repository root containing `build.sh`; the original development workspace layout is not needed.

Run these commands **from the repository root**, not `docs/readme`:

```bash
./build.sh
open ../LumaView.app
```

The default build produces a universal app. `./build.sh --host` builds only the current Mac architecture. The app is written beside the repository as `../LumaView.app` by default; set `LUMAVIEW_APP_PATH` to choose another destination. Build and test working files default to `.build/` inside the repository; set `LUMAVIEW_WORK_ROOT` to change that location. Generated files are excluded by `.gitignore`.

Use `LUMAVIEW_TEST_BUILD=1 ./build.sh --host` for a separate **LumaView Tests** app. This app does not declare file-opening associations, preventing a test copy from competing with the installed app. UI test scripts use this mode by default; `LUMAVIEW_SKIP_TEST_BUILD=1` and `LUMAVIEW_TEST_APP_PATH` can select an already-built test app.

FFmpeg is built under LGPL 2.1 or later; statically linked dav1d uses the BSD 2-Clause license. Corresponding source archives, checksums, and licenses are included. Rebuilding the media tools requires Xcode Command Line Tools, Python 3, Meson 1.12.1, and Ninja 1.13.2. Install the Python tools in a virtual environment if needed, then run `./tools/build-media-tools.sh`. See [ThirdParty/README.md](../../ThirdParty/README.md) for instructions and configuration.

PostScript uses the separate **Ghostscript 10.08.0** executable under AGPL-3.0-or-later. Its license, complete corresponding source, and build script are included. Normal app builds use the bundled universal component; see the [Ghostscript documentation](../../ThirdParty/README-Ghostscript.md) to rebuild it.

## Source layout and validation

- [`Sources/`](../../Sources/): AppKit UI, media canvas, raster/vector loading, media lifecycle, compatibility preparation, and default application settings.
- [`Resources/Localizations/`](../../Resources/Localizations/): language strings and the core translation key list.
- [`Resources/MediaFormats.json`](../../Resources/MediaFormats.json): format catalog.
- [`Resources/MediaTools/`](../../Resources/MediaTools/): bundled FFmpeg and ffprobe.
- [`ThirdParty/sources/`](../../ThirdParty/sources/) and [`Resources/ThirdPartyNotices/`](../../Resources/ThirdPartyNotices/): corresponding third-party sources and licenses.
- [`build.sh`](../../build.sh): universal compilation, packaging, and local signing; [`tools/build-media-tools.sh`](../../tools/build-media-tools.sh): media-tool rebuilding.

Run test scripts from the **repository root**:

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

Audio decoding unit tests generate MP3/FLAC/Opus samples and require a development FFmpeg with the corresponding encoders; set `LUMAVIEW_TEST_FFMPEG` to its path. Running the app and its audio UI tests uses only the bundled tools.

UI integration checks require a logged-in macOS graphical desktop. They open the app and exercise interactions using generated media. Build files and saved reports default to `.build/`; some temporary media uses the system temporary directory. Tests do not read personal photos by default. Context-menu copy tests use a separately named clipboard without replacing the user's current clipboard. Open With, Finder, and default-application tests use mocks without changing system associations.

See the release's [validation record](../../TEST-RESULTS.txt). Version 1.7.2 was tested on **macOS 15.7.9 / Intel**. Universal binaries and signatures were checked, but this release's validation did **not include running on Apple Silicon hardware**.

Saved reports in [`Tests/`](../../Tests/) document their respective historical versions; they do not mean tests have automatically passed on a fresh checkout or the current machine. Personal sample names have been anonymized, and original personal media is not included. Historical `work/` paths record where tests ran at the time and are not required build directories. The repository includes corresponding third-party source archives, checksums, and licenses, making the initial clone larger.
