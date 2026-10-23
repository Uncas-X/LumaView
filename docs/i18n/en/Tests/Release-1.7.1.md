> Personal sample filenames in historical validation records have been anonymized. Test data and results are unchanged.

<!-- doc-navigation:start -->
[Documentation](../INDEX.md) · [简体中文](../../zh-Hans/Tests/Release-1.7.1.md) · [繁體中文](../../zh-Hant/Tests/Release-1.7.1.md) · **English** · [日本語](../../ja/Tests/Release-1.7.1.md) · [한국어](../../ko/Tests/Release-1.7.1.md) · [Français](../../fr/Tests/Release-1.7.1.md) · [Deutsch](../../de/Tests/Release-1.7.1.md) · [Español](../../es/Tests/Release-1.7.1.md) · [Italiano](../../it/Tests/Release-1.7.1.md) · [Português (Brasil)](../../pt-BR/Tests/Release-1.7.1.md) · [Русский](../../ru/Tests/Release-1.7.1.md) · [العربية](../../ar/Tests/Release-1.7.1.md) · [हिन्दी](../../hi/Tests/Release-1.7.1.md) · [Türkçe](../../tr/Tests/Release-1.7.1.md) · [Nederlands](../../nl/Tests/Release-1.7.1.md) · [Polski](../../pl/Tests/Release-1.7.1.md)
<!-- doc-navigation:end -->

# LumaView 1.7.1 validation record

Version 1.7.1, build 13. 2026-10-22, macOS 15.7.9 / Intel. The app and three bundled tools passed arm64 + x86_64 architecture and local-signature checks; this round was not run on Apple Silicon hardware.

## Problems located and fixed

The three user's PSB files were 8-bit RGB, four-channel RLE files with composited transparency, about 108–123 MiB each. Most of each file consists of layer data that can be skipped directly; the main canvases contain about 8.5–9.6 megapixels.

1. The old row-by-row decoder called FileHandle for each PackBits marker and value, producing many tiny reads and leaving main-image and thumbnail queues occupied too long. It now reads chunks of up to 64 KiB, preserving literal/run state and bounds checks across chunks. Long no-op data remains cancellable. ZIP reverses prediction only for sampled rows while still validating the entire compressed stream.
2. All three files have a valid RGB JPEG thumbnail in resource 1036. The filmstrip now prefers it, verifying format, dimensions, aspect ratio, and compressed length; the main image always decodes the real composite. Invalid previews, older BGR resources, or missing previews fall back to the composite.
3. System ImageIO rejects some small PSD composites carrying a valid Generic RGB ICC. The former fallback therefore returned empty thumbnails. It now decodes pixels separately and then attaches the verified original ICC if its color model and component count match, rather than discarding the profile. The original files' ICC matches the system Standard Generic RGB Profile. Regression fixtures were generated from the system profile; user photos were not added to the source.
4. The PSB main view reuses parsed header information and avoids an additional ImageIO layer scan for metadata. Original dimensions, transparency, and main-image quality are retained.

## Tests on the three original files

These are local measurements on this Mac, affected by load and file cache, not performance guarantees for every device. Both old and new decoders used optimized compilation.

| File | Original dimensions | Old main-image decode | New main-image decode | New composite thumbnail decode (without embedded preview) |
| --- | --- | --- | --- | --- |
| Sample A | 2582 × 3318 | Test canceled after more than 15 seconds | 0.68 seconds | 0.039 seconds |
| Sample B | 2610 × 3307 | 14.35 seconds | 0.65 seconds | 0.028 seconds |
| Sample C | 2843 × 3361 | Test canceled after more than 15 seconds | 0.70 seconds | 0.028 seconds |

Requesting three thumbnails concurrently through the real ImageLoader completed in about 0.06 seconds. Full main images took approximately 0.90 / 0.65 / 0.74 seconds through the loader. The old version reported all three composite thumbnails as unsupported; the new version succeeded on all three. The originals' SHA-256 values matched byte-for-byte before and after testing; the app did not write to them.

## Checks passed in this round

| Item | Result |
| --- | --- |
| PSD / PSB encoding and transparent composite | 712 / 712 |
| RLE performance, embedded previews, ICC, chunk boundaries, cancellation | 54 / 54 |
| Real ImageLoader integration for three original PSBs | 21 / 21 |
| 443-file filmstrip, cache, invalidated callbacks | 37 / 37 |
| Independent thumbnail requests and cancellation | 13 / 13 |
| Image library and system decoding | 78 / 78 |
| Installed optimized release app context menu and copying | 28 / 28 |
| Total | 943 / 943 |

New tests cover dense one-byte literals, 64 KiB boundaries, cancellation during long no-op sequences, truncation and out-of-bounds data, distinct correct contents for embedded thumbnails and main images, ICC, transparency, and small noninteger zoom factors. The existing 112 encoding combinations and 128 structurally layered transparent-marker fixtures continue to pass. Filmstrip checks cover rapid switching, offscreen cancellation, and prevention of old callbacks contaminating the current list.

Full file lists and hashes of the installed app and `outputs/LumaView.app` matched, and both passed `codesign --verify --deep --strict`. The old ZIP was backed up before installation; default-opening associations were not modified. The delivered ZIP was separately checked for CRC and version. The historical full 1.7.0 report remains at `Tests/Release-1.7.0.md`; its checks that were not rerun are not included in this round.

Main executable SHA-256: `cab4b6250ab2a15628c4db1e23978dbeef40bb085d9cae18b468b8cfe5e842e8`.

## Logs

- `Photoshop-test-results.txt` ← `work/psb-performance-review/full-photoshop.log`
- `Photoshop-performance-test-results.txt` ← `work/psb-performance-review/results/photoshop-performance-test-results.txt`
- `PSB-loader-test-results.txt` ← `work/psb-loader-integration-results.txt`
- `Thumbnail-test-results.txt` ← `work/thumbnail-1.7.1/result.log`
- `Thumbnail-request-test-results.txt` ← `work/thumbnail-request-1.7.1-run.log`
- `Core-test-results.txt` ← `work/core-1.7.1-run.log`
- `Context-menu-test-results.txt` ← `work/context-menu-release-1.7.1/context-menu-test-results.txt`
