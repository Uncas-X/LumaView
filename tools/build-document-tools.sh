#!/bin/bash
# Rebuild the self-contained, separate-process PostScript-to-PDF interpreter.
set -euo pipefail
SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$SOURCE_ROOT/tools/work-paths.sh"
DOCUMENT_BUILD="${LUMAVIEW_DOCUMENT_BUILD:-$LUMAVIEW_WORK_ROOT/document-tools-build}"
DOCUMENT_ARCH="${1:-universal}"
DOCUMENT_JOBS="${LUMAVIEW_DOCUMENT_JOBS:-4}"
DOCUMENT_VERSION=10.08.0
DOCUMENT_ARCHIVE="$SOURCE_ROOT/ThirdParty/sources/ghostscript-$DOCUMENT_VERSION.tar.xz"
DOCUMENT_HASH=c20492bc8ebb96c87fa2e52a0926e1cda8cde95d66145e018ac713fed5da38cf
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

if [[ "$DOCUMENT_ARCH" == universal ]]; then
  "$0" x86_64
  "$0" arm64
  mkdir -p "$SOURCE_ROOT/Resources/DocumentTools"
  DOCUMENT_STAGED="$SOURCE_ROOT/Resources/DocumentTools/.gs-build-$$"
  trap 'rm -f "$DOCUMENT_STAGED"' EXIT
  xcrun lipo -create "$DOCUMENT_BUILD/ghostscript-x86_64/bin/gs" \
    "$DOCUMENT_BUILD/ghostscript-arm64/bin/gs" \
    -output "$DOCUMENT_STAGED"
  chmod 755 "$DOCUMENT_STAGED"
  xcrun lipo "$DOCUMENT_STAGED" -verify_arch x86_64 arm64
  codesign --force --sign - "$DOCUMENT_STAGED"
  mv -f "$DOCUMENT_STAGED" "$SOURCE_ROOT/Resources/DocumentTools/gs"
  printf '%s\n' "$DOCUMENT_VERSION" > "$SOURCE_ROOT/Resources/DocumentTools/VERSION"
  "$SOURCE_ROOT/Resources/DocumentTools/gs" --version
  otool -L "$SOURCE_ROOT/Resources/DocumentTools/gs"
  exit 0
fi
case "$DOCUMENT_ARCH" in x86_64|arm64) ;; *) echo "Use universal, x86_64 or arm64" >&2; exit 2 ;; esac

[[ "$(shasum -a 256 "$DOCUMENT_ARCHIVE" | cut -d ' ' -f 1)" == "$DOCUMENT_HASH" ]] || {
  echo "Ghostscript source checksum mismatch" >&2; exit 1;
}
mkdir -p "$DOCUMENT_BUILD"
DOCUMENT_BUILD="$(cd "$DOCUMENT_BUILD" && pwd)"
DOCUMENT_SOURCE="$DOCUMENT_BUILD/ghostscript-$DOCUMENT_ARCH"
if [[ ! -f "$DOCUMENT_SOURCE/configure" ]]; then
  mkdir -p "$DOCUMENT_SOURCE"
  tar -xf "$DOCUMENT_ARCHIVE" --strip-components=1 -C "$DOCUMENT_SOURCE"
fi
DOCUMENT_NATIVE_ARCH="$(uname -m)"
DOCUMENT_HOST="$DOCUMENT_ARCH-apple-darwin"
[[ "$DOCUMENT_ARCH" == arm64 ]] && DOCUMENT_HOST=aarch64-apple-darwin
DOCUMENT_BUILD_HOST="$DOCUMENT_NATIVE_ARCH-apple-darwin"
[[ "$DOCUMENT_NATIVE_ARCH" == arm64 ]] && DOCUMENT_BUILD_HOST=aarch64-apple-darwin
cd "$DOCUMENT_SOURCE"

# Every non-system library and resource comes from the verified release archive.
# The supplied macOS architecture header supports both Intel and Apple Silicon.
# Auxiliary generators run on the build Mac, including when cross compiling.
CC='xcrun clang' CXX='xcrun clang++' \
  CFLAGS="-O2 -arch $DOCUMENT_ARCH -mmacosx-version-min=13.0" \
  CXXFLAGS="-O2 -arch $DOCUMENT_ARCH -mmacosx-version-min=13.0" \
  LDFLAGS="-arch $DOCUMENT_ARCH -mmacosx-version-min=13.0" \
  CCAUX='xcrun clang' \
  CFLAGSAUX="-O2 -arch $DOCUMENT_NATIVE_ARCH -mmacosx-version-min=13.0" \
  LDFLAGSAUX="-arch $DOCUMENT_NATIVE_ARCH -mmacosx-version-min=13.0" \
  PKG_CONFIG=/usr/bin/false ./configure \
  --prefix=/lumaview-document-tools \
  --build="$DOCUMENT_BUILD_HOST" --host="$DOCUMENT_HOST" \
  --with-arch_h="$DOCUMENT_SOURCE/arch/osx-x86-x86_64-ppc_arm64-gcc.h" \
  --with-drivers=pdfwrite --disable-contrib --disable-dynamic \
  --without-x --disable-gtk --disable-cups --without-pdftoraster \
  --disable-fontconfig --disable-dbus --without-tesseract --with-extract-dir=no \
  --without-ijs --without-libidn --without-libpaper --without-urf --without-so --without-cal \
  --with-libiconv=no --with-fontpath= --enable-compile-inits --enable-mkromfs-quiet

# Empty external search paths prevent accidental use of a Homebrew/system GS
# installation. All initialization, bundled fonts, CMaps and ICCs are in ROMFS.
make -j"$DOCUMENT_JOBS" GS_LIB_DEFAULT= GS_DEV_DEFAULT=pdfwrite
strip -x bin/gs
codesign --force --sign - bin/gs
xcrun lipo bin/gs -verify_arch "$DOCUMENT_ARCH"
otool -L bin/gs
printf 'Completed Ghostscript %s for %s\n' "$DOCUMENT_VERSION" "$DOCUMENT_ARCH"
