#!/bin/bash
set -euo pipefail

SOURCE_ROOT="$(cd "$(dirname "$0")" && pwd)"
source "$SOURCE_ROOT/tools/work-paths.sh"
OUTPUT_ROOT="$(cd "$SOURCE_ROOT/.." && pwd)"
BUILD_ROOT="$LUMAVIEW_WORK_ROOT/build"
APP_PATH="${LUMAVIEW_APP_PATH:-$OUTPUT_ROOT/LumaView.app}"
MODE="${1:-universal}"
TEST_BUILD="${LUMAVIEW_TEST_BUILD:-0}"
if [[ "$TEST_BUILD" != "0" && "$TEST_BUILD" != "1" ]]; then
  echo "LUMAVIEW_TEST_BUILD must be 0 or 1." >&2; exit 2
fi

SWIFT_OPTIMIZATION="-O"
if [[ "$TEST_BUILD" == "1" ]]; then
  BUILD_ROOT="$LUMAVIEW_WORK_ROOT/build-tests"
  APP_PATH="${LUMAVIEW_APP_PATH:-$LUMAVIEW_WORK_ROOT/LumaView-test.app}"
  SWIFT_OPTIMIZATION="-Onone"
fi

case "$MODE" in
  universal) ARCHITECTURES=(arm64 x86_64) ;;
  --host) ARCHITECTURES=("$(uname -m)") ;;
  -h|--help)
    echo "Usage: ./build.sh [--host]"
    echo "Builds ../LumaView.app for Apple Silicon and Intel (macOS 13+)."
    echo "Use --host to compile only for the current Mac."
    echo "Set LUMAVIEW_TEST_BUILD=1 for an isolated test identity without file associations."
    exit 0
    ;;
  *) echo "Unknown option: $MODE" >&2; exit 2 ;;
esac

mkdir -p "$BUILD_ROOT/swift-module-cache"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
SOURCES=("$SOURCE_ROOT"/Sources/*.swift)
if [[ ! -f "${SOURCES[0]}" ]]; then
  echo "No Swift sources found in $SOURCE_ROOT/Sources" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_ROOT/Resources/AppIcon.icns" ]]; then
  xcrun swiftc -swift-version 5 -O -framework AppKit \
    -module-cache-path "$BUILD_ROOT/swift-module-cache" \
    "$SOURCE_ROOT/tools/GenerateIcon.swift" -o "$BUILD_ROOT/generate-icon"
  "$BUILD_ROOT/generate-icon" "$BUILD_ROOT/LumaView.iconset"
  if ! iconutil -c icns "$BUILD_ROOT/LumaView.iconset" -o "$SOURCE_ROOT/Resources/AppIcon.icns"; then
    echo "iconutil unavailable; writing the standard ICNS container directly."
    "$BUILD_ROOT/generate-icon" "$BUILD_ROOT/LumaView.iconset" "$SOURCE_ROOT/Resources/AppIcon.icns"
  fi
fi

BINARIES=()
for ARCH in "${ARCHITECTURES[@]}"; do
  BINARY_PATH="$BUILD_ROOT/LumaView-$ARCH"
  echo "Building LumaView for ${ARCH}..."
  xcrun swiftc -swift-version 5 "$SWIFT_OPTIMIZATION" -sdk "$SDK_PATH" \
    -target "$ARCH-apple-macosx13.0" \
    -module-cache-path "$BUILD_ROOT/swift-module-cache" \
    -framework AppKit -framework ImageIO -framework UniformTypeIdentifiers -framework AVFoundation \
    "${SOURCES[@]}" -o "$BINARY_PATH"
  BINARIES+=("$BINARY_PATH")
done

mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
if [[ ${#BINARIES[@]} -eq 1 ]]; then
  cp "${BINARIES[0]}" "$APP_PATH/Contents/MacOS/LumaView"
else
  xcrun lipo -create "${BINARIES[@]}" -output "$APP_PATH/Contents/MacOS/LumaView"
fi
xcrun swiftc -swift-version 5 -O -framework UniformTypeIdentifiers \
  -module-cache-path "$BUILD_ROOT/swift-module-cache" \
  "$SOURCE_ROOT/Sources/Localization.swift" "$SOURCE_ROOT/Sources/MediaFormats.swift" "$SOURCE_ROOT/tools/GenerateMediaDeclarations.swift" \
  -o "$BUILD_ROOT/generate-media-declarations"
"$BUILD_ROOT/generate-media-declarations" "$SOURCE_ROOT/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
if [[ "$TEST_BUILD" == "1" ]]; then
  # Launching a test .app registers it with Launch Services. Keep its identity
  # and document handlers separate from the installed user's application.
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier io.local.lumaview.tests" "$APP_PATH/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleName LumaView Tests" "$APP_PATH/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName LumaView Tests" "$APP_PATH/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Delete :CFBundleDocumentTypes" "$APP_PATH/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Delete :UTImportedTypeDeclarations" "$APP_PATH/Contents/Info.plist"
  # LumaViewFormatAssociations remains available to runtime and mock tests.
fi
for TOOL in ffmpeg ffprobe; do
  if [[ ! -x "$SOURCE_ROOT/Resources/MediaTools/$TOOL" ]]; then
    echo "Missing bundled $TOOL. See ThirdParty/README.md to build media tools." >&2; exit 1
  fi
done
if [[ ! -x "$SOURCE_ROOT/Resources/DocumentTools/gs" ]]; then
  echo "Missing bundled Ghostscript. See ThirdParty/README-Ghostscript.md." >&2; exit 1
fi
ditto "$SOURCE_ROOT/Resources/DocumentTools" "$APP_PATH/Contents/Resources/DocumentTools"
codesign --force --sign - "$APP_PATH/Contents/Resources/DocumentTools/gs"
ditto "$SOURCE_ROOT/Resources/MediaTools" "$APP_PATH/Contents/Resources/MediaTools"
ditto "$SOURCE_ROOT/Resources/Localizations" "$APP_PATH/Contents/Resources/Localizations"
ditto "$SOURCE_ROOT/Resources/ThirdPartyNotices" "$APP_PATH/Contents/Resources/ThirdPartyNotices"
for TOOL in ffmpeg ffprobe; do
  codesign --force --sign - "$APP_PATH/Contents/Resources/MediaTools/$TOOL"
done
cp "$SOURCE_ROOT/Resources/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$APP_PATH/Contents/PkgInfo"
chmod +x "$APP_PATH/Contents/MacOS/LumaView"
codesign --force --sign - "$APP_PATH"
codesign --verify --strict "$APP_PATH"
echo "Built: $APP_PATH"
echo "Open with: open \"$APP_PATH\""
