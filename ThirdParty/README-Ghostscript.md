# Ghostscript document conversion tool

<!-- full-translation:start -->
[简体中文](../docs/i18n/zh-Hans/ThirdParty/README-Ghostscript.md) · [繁體中文](../docs/i18n/zh-Hant/ThirdParty/README-Ghostscript.md) · [English](../docs/i18n/en/ThirdParty/README-Ghostscript.md) · [日本語](../docs/i18n/ja/ThirdParty/README-Ghostscript.md) · [한국어](../docs/i18n/ko/ThirdParty/README-Ghostscript.md) · [Français](../docs/i18n/fr/ThirdParty/README-Ghostscript.md) · [Deutsch](../docs/i18n/de/ThirdParty/README-Ghostscript.md) · [Español](../docs/i18n/es/ThirdParty/README-Ghostscript.md) · [Italiano](../docs/i18n/it/ThirdParty/README-Ghostscript.md) · [Português (Brasil)](../docs/i18n/pt-BR/ThirdParty/README-Ghostscript.md) · [Русский](../docs/i18n/ru/ThirdParty/README-Ghostscript.md) · [العربية](../docs/i18n/ar/ThirdParty/README-Ghostscript.md) · [हिन्दी](../docs/i18n/hi/ThirdParty/README-Ghostscript.md) · [Türkçe](../docs/i18n/tr/ThirdParty/README-Ghostscript.md) · [Nederlands](../docs/i18n/nl/ThirdParty/README-Ghostscript.md) · [Polski](../docs/i18n/pl/ThirdParty/README-Ghostscript.md)
<!-- full-translation:end -->


LumaView invokes Ghostscript **10.08.0**, released by Artifex on 2026-09-08, as a separate local executable to convert EPS and PostScript into a temporary PDF. The PDF output retains supported vector paths, text and gradients. Images already embedded as raster pixels remain raster images. Ghostscript is not linked into the Swift application, and no Homebrew installation is required to run this bundled executable.

## License and corresponding source

Ghostscript is distributed under the **GNU Affero General Public License version 3 or later**, as specified by the original `LICENSE` file in this release. The complete license, Ghostscript copyright notice, font embedding exception, Adobe CMap notices and included dependency notices are copied without changes to `Resources/ThirdPartyNotices/Ghostscript/`. A separate commercial license is also available from Artifex; this package does not include a commercial license. See the [official licensing page](https://www.ghostscript.com/licensing/index.html).

The exact, unmodified corresponding source release, including bundled dependency and font sources, is included at `ThirdParty/sources/ghostscript-10.08.0.tar.xz`. Its SHA-256 is recorded in `ThirdParty/sources/SHA256SUMS-Ghostscript`:

```text
c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
```

Source provenance: [official release page](https://www.ghostscript.com/releases/index.html) and [Artifex's 10.08.0 release assets](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). The checksum matches the checksum published for the `.tar.xz` asset. The source package and this build script accompany the LumaView source distribution. LumaView imposes no additional restriction on modification or replacement of this separate tool, or on reverse engineering needed to debug such modifications. These notices describe the bundled third-party component; they do not purport to relicense the application's source.

## Rebuild

Requirements: macOS, Xcode Command Line Tools, the included source archive, and standard macOS build tools. No Homebrew libraries are used. From the LumaView source directory:

```sh
./tools/build-document-tools.sh
./build.sh
```

The script verifies the source archive, builds Intel and Apple Silicon slices from separate source directories, strips local symbols and combines the slices into `Resources/DocumentTools/gs`. Both slices target macOS 13.0 or later. It does not run `make install` or write to a system package manager. `LUMAVIEW_DOCUMENT_BUILD` selects the intermediate build directory; `LUMAVIEW_DOCUMENT_JOBS` controls make parallelism (default 4). The optional argument `x86_64` or `arm64` builds only one architecture. The application build signs the copied executable together with the app.

The executable includes initialization code, bundled fonts, Adobe CMaps and ICC profiles in its internal `%rom%` filesystem. External default search paths are empty. Only the `pdfwrite` output device is enabled. Printing/CUPS, X11, GTK, fontconfig, D-Bus, Tesseract/OCR, dynamic drivers, external IJS and document extraction tools are disabled. All included decoder/color/font libraries are compiled from the corresponding source archive; dynamic linkage is limited to Apple system libraries. See the [official build documentation](https://ghostscript.readthedocs.io/en/gs10.08.0/Make.html) for the ROM filesystem and cross-compilation mechanisms.

LumaView runs the interpreter with `-dSAFER`, a specific input and output file, a private temporary working directory, cancellation and a timeout. The process environment must not inherit user-specified Ghostscript options or library paths. Example for generated trusted test fixtures:

```sh
./Resources/DocumentTools/gs -dSAFER -dBATCH -dNOPAUSE -dEPSCrop \
  -sDEVICE=pdfwrite -sOutputFile=/absolute/private-test/output.pdf \
  --permit-file-read=/absolute/private-test/input.eps \
  --permit-file-write=/absolute/private-test/output.pdf \
  -f /absolute/private-test/input.eps
```

The complete build options are in `tools/build-document-tools.sh`; the source archive is not patched. Native execution can be tested only for architectures supported by the build host. The release checks inspect both Mach-O slices and run a generated EPS containing paths and text through the host-compatible slice, confirming the output PDF still contains vector drawing and text operators.
