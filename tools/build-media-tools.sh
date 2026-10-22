#!/bin/bash
set -euo pipefail
SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$SOURCE_ROOT/tools/work-paths.sh"
MEDIA_BUILD="${LUMAVIEW_MEDIA_BUILD:-$LUMAVIEW_WORK_ROOT/media-build-source}"
MEDIA_PYTHON="${LUMAVIEW_PYTHON:-python3}"
MEDIA_ARCH="${1:-universal}"
if [[ "$MEDIA_ARCH" == universal ]]; then
  "$0" x86_64
  "$0" arm64
  mkdir -p "$SOURCE_ROOT/Resources/MediaTools"
  for TOOL in ffmpeg ffprobe; do
    xcrun lipo -create "$MEDIA_BUILD/ffmpeg-x86_64/$TOOL" "$MEDIA_BUILD/ffmpeg-arm64/$TOOL" -output "$SOURCE_ROOT/Resources/MediaTools/$TOOL"
  done
  exit 0
fi
case "$MEDIA_ARCH" in x86_64|arm64) ;; *) echo "Use universal, x86_64 or arm64" >&2; exit 2;; esac
mkdir -p "$MEDIA_BUILD/src"
"$MEDIA_PYTHON" -m mesonbuild.mesonmain --version
command -v ninja >/dev/null
(cd "$SOURCE_ROOT/ThirdParty/sources" && shasum -a 256 -c SHA256SUMS)
if [[ ! -d "$MEDIA_BUILD/src/ffmpeg-9.0.2" ]]; then tar -xf "$SOURCE_ROOT/ThirdParty/sources/ffmpeg-9.0.2.tar.xz" -C "$MEDIA_BUILD/src"; fi
if [[ ! -d "$MEDIA_BUILD/src/dav1d-1.5.3" ]]; then tar -xf "$SOURCE_ROOT/ThirdParty/sources/dav1d-1.5.3.tar.xz" -C "$MEDIA_BUILD/src"; fi
MEDIA_CPU="$MEDIA_ARCH"
if [[ "$MEDIA_ARCH" == arm64 ]]; then MEDIA_CPU=aarch64; fi
MEDIA_PREFIX="$MEDIA_BUILD/prefix-$MEDIA_ARCH"
cat > "$MEDIA_BUILD/cross-$MEDIA_ARCH.ini" <<EOF
[binaries]
c = ['/usr/bin/xcrun', 'clang']
ar = '/usr/bin/ar'
strip = '/usr/bin/strip'
[host_machine]
system = 'darwin'
cpu_family = '$MEDIA_CPU'
cpu = '$MEDIA_ARCH'
endian = 'little'
[properties]
needs_exe_wrapper = true
[built-in options]
c_args = ['-arch', '$MEDIA_ARCH', '-mmacosx-version-min=13.0']
c_link_args = ['-arch', '$MEDIA_ARCH', '-mmacosx-version-min=13.0']
EOF
"$MEDIA_PYTHON" -m mesonbuild.mesonmain setup "$MEDIA_BUILD/dav1d-$MEDIA_ARCH" "$MEDIA_BUILD/src/dav1d-1.5.3" \
  --prefix "$MEDIA_PREFIX" --cross-file "$MEDIA_BUILD/cross-$MEDIA_ARCH.ini" --buildtype release \
  --default-library static -Denable_asm=false -Denable_tools=false -Denable_tests=false -Denable_docs=false
"$MEDIA_PYTHON" -m mesonbuild.mesonmain compile -C "$MEDIA_BUILD/dav1d-$MEDIA_ARCH" -j 4
"$MEDIA_PYTHON" -m mesonbuild.mesonmain install -C "$MEDIA_BUILD/dav1d-$MEDIA_ARCH"
mkdir -p "$MEDIA_BUILD/ffmpeg-$MEDIA_ARCH"
cat > "$MEDIA_BUILD/pkg-config-$MEDIA_ARCH" <<EOF
#!/bin/sh
case "\$*" in
  *--version*) echo '1.8.1';;
  *--cflags*) echo '-I$MEDIA_PREFIX/include';;
  *--libs*) echo '-L$MEDIA_PREFIX/lib -ldav1d';;
  *--modversion*) echo '1.5.3';;
  *dav1d*) exit 0;;
  *) exit 1;;
esac
EOF
chmod +x "$MEDIA_BUILD/pkg-config-$MEDIA_ARCH"
cd "$MEDIA_BUILD/ffmpeg-$MEDIA_ARCH"
"$MEDIA_BUILD/src/ffmpeg-9.0.2/configure" \
  --prefix="$MEDIA_PREFIX" --cc='xcrun clang' --arch="$MEDIA_CPU" --target-os=darwin --enable-cross-compile \
  --extra-cflags="-arch $MEDIA_ARCH -mmacosx-version-min=13.0" \
  --extra-ldflags="-arch $MEDIA_ARCH -mmacosx-version-min=13.0" \
  --pkg-config="$MEDIA_BUILD/pkg-config-$MEDIA_ARCH" --pkg-config-flags=--static \
  --disable-autodetect --disable-doc --disable-debug --disable-shared --enable-static --enable-small \
  --disable-ffplay --disable-avdevice --disable-network --disable-protocols --enable-protocol=file,pipe \
  --disable-x86asm --enable-libdav1d --enable-videotoolbox --enable-audiotoolbox \
  --enable-zlib --enable-bzlib --disable-encoders \
  --enable-encoder=h264_videotoolbox,aac,mpeg4,prores_ks,png,mjpeg,pcm_s16le \
  --disable-filters --enable-filter=scale,pad,format,aformat,aresample,anull,null,transpose,hflip,vflip,trim,atrim,setpts,asetpts
make -j4 ffmpeg ffprobe
/usr/bin/strip -x ffmpeg ffprobe
printf '\nCompleted %s\n' "$MEDIA_ARCH"
