# Formats and preview behavior

<!-- doc-navigation:start -->
[Documentation](INDEX.md) · [简体中文](../zh-Hans/FORMATS.md) · [繁體中文](../zh-Hant/FORMATS.md) · **English** · [日本語](../ja/FORMATS.md) · [한국어](../ko/FORMATS.md) · [Français](../fr/FORMATS.md) · [Deutsch](../de/FORMATS.md) · [Español](../es/FORMATS.md) · [Italiano](../it/FORMATS.md) · [Português (Brasil)](../pt-BR/FORMATS.md) · [Русский](../ru/FORMATS.md) · [العربية](../ar/FORMATS.md) · [हिन्दी](../hi/FORMATS.md) · [Türkçe](../tr/FORMATS.md) · [Nederlands](../nl/FORMATS.md) · [Polski](../pl/FORMATS.md)
<!-- doc-navigation:end -->


The LumaView 1.7.2 format catalog contains 72 groups of image, vector/document, video, and audio choices. It is used for discovering files and choosing default-opening associations, not as an individually tested compatibility list. Files with the same extension can contain different encodings; whether they open depends on file contents, system capabilities, and bundled decoders.

## Images

| Category | Example formats |
| --- | --- |
| Common images | JPEG, PNG / APNG, GIF, TIFF, BMP, HEIC / HEIF, WebP |
| Other images | AVIF, JPEG XL, JPEG 2000, ICO / CUR / ICNS, PSD / PSB, TGA, HDR / OpenEXR, Netpbm |
| Camera RAW | DNG, Canon CR2 / CR3 / CRW, Nikon NEF / NRW, Sony ARW / SR2 / SRF, and ORF, RAF, RW2, PEF, SRW |

macOS ImageIO decodes images. The table lists candidates from the format catalog; support for RAW, newer image encodings, and professional formats in particular varies with system version. The app does not bundle a separate RAW decoder. GIF supports animation; TIFF supports multi-page browsing. Compound image formats without implemented pagination show their first image only.

Transparent regions of raster images such as PNG / APNG, GIF, and PSD / PSB consistently reveal the viewer's current background, without a checkerboard. Shadows follow actual pixel opacity, including separate soft masks and every frame of an animation, without placing a rectangular shadow or border around an empty canvas. This applies only to viewing; copies preserve the original transparency and contain no displayed shadow. Vector documents such as PDF and SVG use the white-paper rule below.

**Photoshop PSD / PSB:** The saved composite is read for the main view, thumbnails, and copying the currently displayed image; Photoshop layers are neither reconstructed nor edited. If the file explicitly lacks a saved compatibility composite, the viewer advises enabling Maximize Compatibility in Photoshop and saving again. PSD / PSB correspond to file versions 1 / 2; according to the [Adobe format specification](https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/), each side is limited to 30,000 / 300,000 pixels respectively.

Decoding has passed 112 basic encoding combinations. Both PSD and PSB cover one-channel and extra-channel grayscale, three-channel and extra-channel RGB at 8 / 16 / 32 bits, and CMYK at 8 / 16 bits. Each combination covers uncompressed, PackBits RLE, ZIP, and ZIP prediction. Another 128 grayscale/RGB fixtures with real layer records verify separation of ordinary user alpha and composite transparency at 8 / 16 / 32 bits, covering positive and negative layer counts, global Lr16/Lr32 records, composite transparency markers, and uncompressed/ZIP encodings. The bounded-preview, main-view, and thumbnail paths were also checked with a 300,000 × 128 pixel PSB. These matrix fixtures were generated from the format specification. Version 1.7.1 additionally tested three real layered PSBs, about 108–123 MiB each, with transparent composites and ICC profiles, for main views and thumbnails. These tests do not imply that arbitrary Photoshop exports have been validated.

The filmstrip prefers a valid RGB JPEG thumbnail saved by Photoshop (resource 1036), checking encoding, dimensions, aspect ratio, and compressed length; if absent, corrupt, or unsupported, it falls back to the composite. The embedded preview is normally small and used only in the filmstrip. The main view always reads the compatibility composite. RLE is read in chunks of up to 64 KiB instead of issuing a file read for every compressed marker; cancellation still works across chunks and long no-op sequences.

ZIP, high-bit-depth RLE, large files, and files with extra channels use a built-in row-by-row fallback reader before ImageIO interprets colors. When an explicit composite-transparency marker exists, the corresponding alpha is read; for RGB/grayscale, the white backing of the composite preview is removed and a separate mask attached. Without a composite-transparency declaration, only base colors are displayed, so a saved selection is not mistaken for transparency. Multiple alpha channels, spot-color channels, CMYK transparency, complex masks, and similar combinations have not been fully verified and may not match Photoshop layer compositing. The fallback retains the first embedded ICC profile no larger than 4 MiB and passes it to the system. If the system rejects a small composite with a valid ICC, pixels are decoded separately and the verified original ICC, with matching color model and component count, is attached again rather than silently discarded. Larger profiles are skipped and may be interpreted using system default color. 32-bit data is used for a display preview without full Photoshop HDR tone controls. Lab, indexed color, duotone, and other special modes are outside the tested matrix; support depends on file structure and system decoding. A small one-bit PackBits image also has a separate native-decoding check.

Large images are not rejected solely for exceeding 150 megapixels. The loader creates a preview within a memory budget, with a longest side of at most 8192 pixels and approximately 32 megapixels total; the actual limits may be lower. The information panel retains original pixel dimensions and orientation and identifies a downsampled preview. Zoom percentage uses original dimensions, but enlarging a preview cannot reveal source details that were not decoded. Damaged files or files that cannot be decoded still produce an error.

## Vectors and documents

| Format | Current behavior |
| --- | --- |
| SVG | Drawn offline using the system vector renderer and updated with zoom. Recognized standard SVG DTD declarations are accepted without loading the DTD; custom/internal DTDs, scripts, event handlers, and external resources are rejected. Some complex or dynamic SVGs may not display. |
| PDF | Multi-page thumbnails, progress slider, page numbers, focus, and keyboard navigation; drawn at the current zoom with crop boxes and page orientation preserved. Document editing is not provided. |
| AI | PDF-compatible data is displayed directly, including multiple pages / artboards. Legacy PostScript AI is converted to vector PDF by bundled Ghostscript. Files containing only proprietary Illustrator data are not guaranteed to open. |
| EPS / PostScript | Bundled Ghostscript 10.08.0 converts complete drawing contents to PDF, retaining paths, text, and embedded images for vector-canvas display; multi-page PS is supported. If conversion fails and DOS EPS contains a valid embedded TIFF, it can fall back to an explicitly identified raster preview. Bitmaps retain their source-resolution limit, and unavailable nonembedded fonts may be substituted. |

The main canvas retains PDF / SVG vector sources and draws the visible area at the current zoom in 512-pixel tiles, supporting up to 3200% zoom. When changing pages, it prepares a complete screen-sized base page in the background before a whole-page transition; the original vector layer then supplies detail at the current zoom, avoiding visible unpainted tiles. The base image's longest side is at most 4096 pixels, which does not limit the zoom clarity of the vector layer. Document paper is plain white without a checkerboard; embedded photos and other bitmaps remain limited by their source resolution. Each TIFF page uses the same bounded raster preview as a large image. Password entry is not offered for encrypted and locked PDFs, so they cannot be viewed directly. Rendering does not rewrite originals.

PDF / PDF-compatible AI allows right-click copying of an embedded bitmap at the click location or copying the whole current page. Common XObjects, inline images, nested Forms, clipping, and page orientation are supported. Complex masks or color spaces use the rendered visible region; special structures such as bitmaps inside Patterns, or pages exceeding the scan budget, may prevent copying an embedded image by itself. Copy output is a PNG/TIFF bitmap, with longest side up to 8192 pixels and approximately 32 megapixels total; the source file is unchanged.

## Video and audio

| Category | Examples in the format catalog |
| --- | --- |
| Common video containers | MP4 / M4V, MOV, MKV, WebM, AVI, FLV, WMV / ASF, MPEG, TS / M2TS, 3GP |
| Other video and bitstreams | OGV, RM / RMVB, VOB, MOD / TOD, Motion JPEG, MXF, DV, NUT, NSV, AMV, Bink / Smacker, and H.264, HEVC, VVC, IVF, Y4M streams |
| Common audio | MP3, AAC, M4A, WAV, AIFF, CAF, FLAC, Ogg / Vorbis, Opus, WMA |
| Other audio | Speex, APE, WavPack, TTA, TAK, Shorten, AC-3 / E-AC-3 / TrueHD, DTS, AMR, AU / SND, RealAudio, DSD, MKA, Musepack, GSM / QCP, IFF Audio |

System AVFoundation playback is tried first. If it cannot play the file directly, bundled FFmpeg 9.0.2 / ffprobe, with statically linked dav1d 1.5.3 for AV1 decoding, is used. Eligible videos are first remuxed while retaining the video encoding; otherwise, they are converted to a system-playable encoding. Audio can also be prepared for compatible playback.

Compatibility preparation is local and disables network functionality; no extra installation is required. It processes the whole file before playback and cannot guarantee immediate start. Progress is displayed; changing files or closing the window cancels preparation. Transcoding may alter picture quality, sound quality, or color. The original remains unchanged. Speed for high resolution, high frame rate, complex codecs, and long files depends on the device.

The cache is automatically cleaned toward a 2 GB target. In-use files are retained, so this is not a strict total-size cap. One prepared file is limited to 8 GB, and at least 512 MB of free disk space must remain; exceeding limits stops preparation and shows an error. Reopening can reuse a valid cache entry.

DRM-protected or damaged files, codecs requiring unavailable external decoders, proprietary encodings, and some unusual containers may fail. The catalog includes uncommon formats but does not guarantee each one or test every encoding combination. External subtitle management, disc menus, and streaming playback are not currently provided.

## Audio artwork and waveform

The main display first uses artwork embedded in the original file, reading native metadata and extracting attached pictures with the bundled tool if necessary. Artwork is decoded with a longest side of 2048 pixels; an undecodable cover falls back to the waveform. Files without embedded artwork do not download covers from the network or read a neighboring `cover.jpg`.

Without artwork, actual decoded samples generate a peak envelope for the full track. At most 4096 sample intervals are retained, and each PCM-buffer batch is bounded so long audio is not fully loaded into memory. Compatible audio uses the prepared local playback file to generate its waveform. The waveform is a full-track overview, not a live spectrum. Playback continues while it is generated. Changing files or closing the window cancels analysis; late results cannot overwrite the current file. Filmstrip durations are read asynchronously and independently without selecting every file. Audio and video badges both read `▶ duration`.

## Default application settings

Use **LumaView → Default Application…** or `⌘,` to select formats by group and apply associations. Actual system defaults are read when the dialog opens, the app reactivates, and changes finish; system associations persist across restarts. A checkmark means all types point to this app; a dash means some types match or point to another LumaView copy. Select All Formats covers all categories regardless of search; a group Select All affects only that category. Unapplied selections are a temporary draft, and Clear does not remove system defaults that were already set. The system may consider several extensions with the same type identifier as one file type, so some extensions can change together.

The dialog reads back system results and reports formats that did not change successfully. Cancel only stops changes not yet performed; completed associations are not automatically undone. To restore a format, select the previous app through Finder → Get Info → Open With → Change All.
