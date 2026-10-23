> Personal sample filenames in historical validation records have been anonymized. Test data and results are unchanged.

<!-- doc-navigation:start -->
[Documentation](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.0.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.0.md) · **English** · [日本語](../../ja/Tests/Release-1.7.0.md) · [한국어](../../ko/Tests/Release-1.7.0.md) · [Français](../../fr/Tests/Release-1.7.0.md) · [Deutsch](../../de/Tests/Release-1.7.0.md) · [Español](../../es/Tests/Release-1.7.0.md) · [Italiano](../../it/Tests/Release-1.7.0.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.0.md) · [Русский](../../ru/Tests/Release-1.7.0.md) · [العربية](../../ar/Tests/Release-1.7.0.md) · [हिन्दी](../../hi/Tests/Release-1.7.0.md) · [Türkçe](../../tr/Tests/Release-1.7.0.md) · [Nederlands](../../nl/Tests/Release-1.7.0.md) · [Polski](../../pl/Tests/Release-1.7.0.md)
<!-- doc-navigation:end -->

# LumaView 1.7.0 validation record

Date: 2026-10-22 (Asia/Shanghai). Test environment: macOS 15.7.9, x86_64. The app targets macOS 13+, and all four executables are universal Intel / Apple Silicon binaries.

## Changes and results tested in this round

- Bundled Ghostscript 10.08.0 converts the full contents of directly opened EPS, PostScript, and legacy PostScript AI into PDFs retaining vector paths, text, and embedded images in the background, then passes the PDF to the existing canvas. Users need neither a separate interpreter nor manual conversion; zooming, panning, rotation, and multi-page navigation follow the current interactions. Embedded TIFF fallback is still used if vector conversion fails and the file provides a preview; raster fallback is not labeled vector.
- The sample attachment `sample-vector.eps` was tested using its complete PostScript contents. Scanning the generated PDF found **147,521 path/gradient-related operations, 59 text operations, and 160 XObject calls**. XObjects here are counted as PDF `Do` operations and may include images or Forms; the number is not a count of distinct images. Testing confirmed that real vector contents were preserved. SHA-256 comparisons of the EPS and `sample-vector.svg` before and after testing showed unchanged originals.
- PostScript uses a separate cancellable process, Ghostscript SAFER, and a system process sandbox. The input is copied into a private temporary directory; the interpreter cannot read other user files, write to arbitrary external files, or use external pipes. Timeout, cancellation, reuse by multiple consumers, corrupt input, and cache invalidation checks passed. Completed results are published atomically, so partial PDFs do not fill thumbnails. Real-viewer tests covered EPS at 3200% vector zoom, up/down focus and left/right page navigation in multi-page PS, and switching to PNG during conversion without a late result replacing the current view.
- `.psb` was added to the Photoshop group alongside `.psd` for discovery, main view, thumbnails, and default application settings. A saved compatibility composite is read and original canvas dimensions retained; large files get bounded previews according to display need. Validation covered **112 encoding combinations, 128 structurally layered transparency-marker fixtures, one large PSB, and 13 corrupt fixtures**. Composite transparency detection uses layer count and Lr16/Lr32, Mtrn/Mt16/Mt32 markers; ordinary extra Alpha channels are not mistaken for composite transparency. Tests covered transparent pixel values, removal of white backing, encoding consistency, cancellation in long rows, and main/thumbnail integration regressions.
- The default-opening dialog reads actual system associations when it opens, when the app reactivates, and after batch settings complete. The associations themselves persist across restarts; unapplied drafts are not displayed as success. A checked format has every type assigned to this app; a dash indicates partial matches or another copy with the same bundle ID, explained in the tooltip. Clear only changes the draft; it does not revoke system defaults.
- Select All Formats at the top selects images, vectors/documents, video, and audio at once, including formats outside search results. The Set button must still be clicked to write associations. Detection, partial success, error read-back, rebuilding the controller, differences between draft and actual state, and total selection were tested with an in-memory mock backend. Tests did not change the user's system default applications.
- New settings, PostScript, and Photoshop strings from this round cover all 16 languages. Core text and format placeholders passed validation.

## Validation in this round

Only checks listed below with complete successful summaries in this round's logs are counted; historical modules that were not rerun are excluded.

| Check | Passed |
| --- | --- |
| PostScript vector conversion, cancellation, isolation, and actual EPS | 24 / 24 |
| SVG / EPS compatibility and original-attachment verification | 64 / 64 |
| PSD / PSB composite, transparent channels, large images, and damaged data | 712 / 712 |
| Actual-system read-back and batch default settings (mock) | 101 / 101 |
| Default-format dialog, reopen state, and all-format selection (mock) | 34 / 34 |
| 16 languages and placeholders | 174 / 174 |
| Release app format declarations | 15 / 15 |
| Image library and system decoding | 78 / 78 |
| Canvas geometry, animations, and mouse | 66 / 66 |
| Document parsing and complete-page drawing | 56 / 56 |
| Document focus, EPS / PS zoom and pagination, cancellation on file change | 75 / 75 |
| Real window clicking and lifecycle | 65 / 65 |
| 443-file thumbnails, cache, and stale callbacks | 37 / 37 |
| Thumbnail request cancellation and consumer isolation | 13 / 13 |
| Installed release app context menu and private clipboard | 28 / 28 |
| **Total** | **1542 / 1542** |

The installed optimized release app underwent 28 additional context-menu checks through real menus and target/action dispatch, using a separately named clipboard. They verified copying images, current video frames, PDF images and whole pages, rotation, and stale results on switching/closing, without touching the user's system clipboard. Existing regression checks for mouse clicks, window lifecycle, page focus, complete-page presentation, thumbnail cache, and cancellation all passed.

## Release directory and installed-app verification

Version **1.7.0, build 12**. Before writing this report, the bundle IDs, versions, builds, complete file lists, and SHA-256 hashes of `outputs/LumaView.app` and `/Applications/LumaView.app` were compared and found identical. All four executables passed dual-architecture inspection, both apps passed `codesign --verify --deep --strict`, bundled Ghostscript reported version 10.08.0, localization/version resources matched the source tree, and the Ghostscript source archive's SHA-256 matched the included checksum list. The interpreter is re-signed during a build; its signed binary is not required to match the unsigned source-directory copy byte-for-byte.

| Executable | SHA-256 |
| --- | --- |
| `Contents/MacOS/LumaView` | `e4f3e1828ae0cfb93046c382edfefd1868d0a910e7cd490f8abdb372507cc4e6` |
| `Contents/Resources/MediaTools/ffmpeg` | `0199de6f07763ec8f4a04814c7bfc41fa434cf97b4d3bec195352ac72447c42d` |
| `Contents/Resources/MediaTools/ffprobe` | `ff705079cf07288fe4877120f88f1e3d55768c0eeb6687861451374df3887c2b` |
| `Contents/Resources/DocumentTools/gs` | `7c8e893089eee1390c179be1c73ea2047e4d074a7d70c80b9073dee05ff64167` |

This report does not replace subsequent ZIP integrity checks or claim Apple notarization. The signature is local and ad hoc. Apple Silicon compilation and architecture checks were completed, but this round did not run on Apple Silicon hardware. The Ghostscript source archive, license, and rebuilding instructions accompany the source distribution.

## Scope and limits

Bitmaps already embedded in EPS / PS retain their source-resolution limits; external fonts or file resources and unusual or damaged PostScript may not convert completely. PSD / PSB previews depend on saved compatibility composites and do not edit Photoshop layers or reconstruct missing composites; when absent, the app advises enabling Maximize Compatibility and saving again. Original canvas dimensions may exceed the displayed preview size; a bounded preview is not presented as if every source pixel were decoded. See [FORMATS.md](../FORMATS.md) for other format limits.

## Log sources for this round

The following files were copied to `Tests/`. Historical reports not rerun remain but are excluded from this round's total:

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
