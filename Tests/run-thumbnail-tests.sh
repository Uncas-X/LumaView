#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/tools/work-paths.sh"
TEST_BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lumaview-thumbnail-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
ARCH="$(uname -m)"
TEST_APP="$TEST_BUILD_DIR/ThumbnailTests.app"
RUN_OUTPUT="$TEST_BUILD_DIR/output"
OUTPUT_DIR="${LUMAVIEW_TEST_OUTPUT:-$LUMAVIEW_WORK_ROOT/thumbnail-tests}"
mkdir -p "$RUN_OUTPUT" "$OUTPUT_DIR" "$TEST_APP/Contents/MacOS" "$TEST_APP/Contents/Resources/Localizations"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd -P)"
cp "$PROJECT_ROOT/Resources/Localizations/catalog.json" "$TEST_APP/Contents/Resources/Localizations/catalog.json"
cat > "$TEST_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>dev.lumaview.thumbnail-tests</string>
<key>CFBundleName</key><string>LumaView Thumbnail Tests</string>
<key>CFBundleExecutable</key><string>ThumbnailTests</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
# Compile the real view with one observational draw counter. Instrument the
# loader entry in a temporary source copy; all cache/navigation logic is real.
python3 - "$PROJECT_ROOT" "$TEST_BUILD_DIR" <<'PY'
import os, pathlib, sys
root, build = map(pathlib.Path, sys.argv[1:])
viewer = pathlib.Path(os.environ.get('LUMAVIEW_FILMSTRIP_SOURCE', root / 'Sources/ViewerController.swift')).read_text()
start, end = viewer.index('final class Filmstrip:'), viewer.index('\nenum ViewerNavigationFocus')
filmstrip = viewer[start:end]
draw = '    override func draw(_ dirtyRect: NSRect) {'
assert filmstrip.count(draw) == 1
filmstrip = filmstrip.replace(draw, draw + '\n        ThumbnailTestMetrics.draws += 1', 1)
(build / 'Filmstrip.swift').write_text('import AppKit\nimport QuartzCore\n' + filmstrip + '\n')
source = pathlib.Path(os.environ.get('LUMAVIEW_IMAGE_LIBRARY_SOURCE', root / 'Sources/ImageLibrary.swift')).read_text()
needle = '    func thumbnail(_ url: URL, completion: @escaping (NSImage?) -> Void) {'
new_needle = needle[:-1] + '-> ThumbnailRequest {'
if new_needle in source:
    assert source.count(new_needle) == 1
    source = source.replace(new_needle, new_needle + '\n        ThumbnailTestMetrics.record(url)\n        if let controlled = ThumbnailTestMetrics.controlled {\n            let request = ThumbnailRequest()\n            ThumbnailTestMetrics.tickets.append(request)\n            controlled(url, completion)\n            return request\n        }', 1)
    (build / 'cancellable').touch()
else:
    assert source.count(needle) == 1
    source = source.replace(needle, needle + '\n        ThumbnailTestMetrics.record(url)\n        if let controlled = ThumbnailTestMetrics.controlled { controlled(url, completion); return }', 1)
(build / 'ImageLibrary.swift').write_text(source)
PY
EXTRA_SOURCES=()
EXTRA_FLAGS=()
if [[ -f "$PROJECT_ROOT/Sources/ThumbnailRequest.swift" ]]; then
  EXTRA_SOURCES+=("$PROJECT_ROOT/Sources/ThumbnailRequest.swift")
fi
if [[ -f "$TEST_BUILD_DIR/cancellable" ]]; then EXTRA_FLAGS+=(-D CANCELLABLE_THUMBNAILS); fi
xcrun swiftc -swift-version 5 -target "${ARCH}-apple-macosx13.0" \
  ${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"} \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  -framework AppKit -framework QuartzCore -framework ImageIO -framework UniformTypeIdentifiers -framework AVFoundation \
  "$PROJECT_ROOT/Sources/Localization.swift" "$PROJECT_ROOT/Sources/AudioWaveform.swift" \
  "$PROJECT_ROOT/Sources/AudioArtwork.swift" "$PROJECT_ROOT/Sources/MediaFormats.swift" \
  "$PROJECT_ROOT/Sources/PostScriptDocument.swift" "$PROJECT_ROOT/Sources/VectorRenderer.swift" "$PROJECT_ROOT/Sources/CompatibilityMedia.swift" \
  ${EXTRA_SOURCES[@]+"${EXTRA_SOURCES[@]}"} "$PROJECT_ROOT/Sources/PhotoshopImage.swift" "$TEST_BUILD_DIR/ImageLibrary.swift" "$TEST_BUILD_DIR/Filmstrip.swift" \
  "$PROJECT_ROOT/Tests/ThumbnailTests.swift" -o "$TEST_APP/Contents/MacOS/ThumbnailTests"
open -n -W "$TEST_APP" --stdout "$RUN_OUTPUT/result.log" --stderr "$RUN_OUTPUT/error.log" --args "$RUN_OUTPUT"
cp -R "$RUN_OUTPUT/." "$OUTPUT_DIR/"
cat "$OUTPUT_DIR/result.log"
if ! /usr/bin/grep -q '^PASS:' "$OUTPUT_DIR/result.log"; then
  cat "$OUTPUT_DIR/error.log" >&2
  exit 1
fi
