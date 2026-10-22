#!/bin/bash
set -euo pipefail
TEST_SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$TEST_SOURCE_ROOT/tools/work-paths.sh"
TEST_OUTPUT="${LUMAVIEW_TEST_OUTPUT:-$LUMAVIEW_WORK_ROOT/large-document-tests}"
mkdir -p "$TEST_OUTPUT"
TEST_BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lumaview-large-document-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
TEST_APP="$TEST_BUILD_DIR/LargeDocumentTests.app"
mkdir -p "$TEST_APP/Contents/MacOS" "$TEST_APP/Contents/Resources/Localizations"
cp "$TEST_SOURCE_ROOT/Resources/Localizations/catalog.json" "$TEST_APP/Contents/Resources/Localizations/catalog.json"
TEST_RUN_OUTPUT="$TEST_BUILD_DIR/results"
mkdir -p "$TEST_RUN_OUTPUT"
# Instrument only a temporary source copy. Counting CATiledLayer's actual draw
# callbacks catches accidental source-resolution tiling when a huge page fits.
python3 - "$TEST_SOURCE_ROOT/Sources/DocumentMedia.swift" "$TEST_BUILD_DIR/DocumentMedia.swift" <<'PY'
import pathlib, sys
source = pathlib.Path(sys.argv[1]).read_text()
class_marker = 'final class DocumentTileLayer: CATiledLayer {\n    var documentPage: DocumentPage?'
draw_marker = '    override func draw(in context: CGContext) {\n        documentPage?.draw(in: context, rect: bounds)'
assert class_marker in source and draw_marker in source, 'Document tile implementation changed; update test instrumentation.'
source = source.replace(class_marker, '''final class DocumentTileLayer: CATiledLayer {
    static let metricsLock = NSLock()
    static var drawCount = 0
    static var drawScales: [CGFloat] = []
    static var maxTileBytes = 0
    var documentPage: DocumentPage?''')
source = source.replace(draw_marker, '''    override func draw(in context: CGContext) {
        Self.metricsLock.lock()
        Self.drawCount += 1
        Self.drawScales.append(abs(context.ctm.a))
        Self.maxTileBytes = max(Self.maxTileBytes, context.bytesPerRow * context.height)
        Self.metricsLock.unlock()
        documentPage?.draw(in: context, rect: bounds)''')
pathlib.Path(sys.argv[2]).write_text(source)
PY
cat > "$TEST_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>dev.lumaview.large-document-tests</string>
<key>CFBundleName</key><string>LumaView Large Document Tests</string>
<key>CFBundleExecutable</key><string>LargeDocumentTests</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
ARCH="$(uname -m)"
xcrun swiftc -swift-version 5 -target "${ARCH}-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  -framework AppKit -framework ImageIO -framework QuartzCore -framework AVFoundation \
  "$TEST_SOURCE_ROOT/Sources/Localization.swift" "$TEST_SOURCE_ROOT/Sources/ThumbnailRequest.swift" "$TEST_SOURCE_ROOT/Sources/PostScriptDocument.swift" "$TEST_SOURCE_ROOT/Sources/VectorRenderer.swift" \
  "$TEST_BUILD_DIR/DocumentMedia.swift" "$TEST_SOURCE_ROOT/Sources/PhotoCanvas.swift" \
  "$TEST_SOURCE_ROOT/Tests/LargeDocumentTests.swift" -o "$TEST_APP/Contents/MacOS/LargeDocumentTests"
# Keep the helper's file access inside its temporary test directory; copy final
# reports from the parent shell, avoiding Documents-folder permission prompts.
open -n -W "$TEST_APP" --stdout "$TEST_RUN_OUTPUT/large-document-test-results.txt" --stderr "$TEST_RUN_OUTPUT/large-document-errors.txt" --args "$TEST_RUN_OUTPUT"
cp -R "$TEST_RUN_OUTPUT/." "$TEST_OUTPUT/"
cat "$TEST_OUTPUT/large-document-test-results.txt"
if ! awk '/^PASS / {passed++} /^FAIL / {failed=1} END {exit failed || passed != 2}' "$TEST_OUTPUT/large-document-test-results.txt"; then
  cat "$TEST_OUTPUT/large-document-errors.txt" >&2
  exit 1
fi
