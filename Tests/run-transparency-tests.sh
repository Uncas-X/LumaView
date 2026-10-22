#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/tools/work-paths.sh"
TEST_BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lumaview-transparency-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
TEST_OUTPUT="${LUMAVIEW_TEST_OUTPUT:-$LUMAVIEW_WORK_ROOT/transparency-tests}"
mkdir -p "$TEST_OUTPUT"
TEST_OUTPUT="$(cd "$TEST_OUTPUT" && pwd -P)"
TEST_APP="$TEST_BUILD_DIR/TransparencyTests.app"
mkdir -p "$TEST_APP/Contents/MacOS" "$TEST_APP/Contents/Resources/Localizations"
cp "$PROJECT_ROOT/Resources/Localizations/catalog.json" "$TEST_APP/Contents/Resources/Localizations/catalog.json"
cat > "$TEST_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>dev.lumaview.transparency-tests</string>
<key>CFBundleName</key><string>LumaView Transparency Tests</string>
<key>CFBundleExecutable</key><string>TransparencyTests</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
xcrun swiftc -swift-version 5 -O -target "$(uname -m)-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  -framework AppKit -framework AVFoundation -framework ImageIO -framework UniformTypeIdentifiers \
  "$PROJECT_ROOT/Sources/Localization.swift" "$PROJECT_ROOT/Sources/ThumbnailRequest.swift" \
  "$PROJECT_ROOT/Sources/PostScriptDocument.swift" "$PROJECT_ROOT/Sources/VectorRenderer.swift" \
  "$PROJECT_ROOT/Sources/DocumentMedia.swift" "$PROJECT_ROOT/Sources/PhotoshopImage.swift" \
  "$PROJECT_ROOT/Sources/PhotoCanvas.swift" "$PROJECT_ROOT/Tests/TransparencyTests.swift" \
  -o "$TEST_APP/Contents/MacOS/TransparencyTests"
open -n -W "$TEST_APP" --stdout "$TEST_OUTPUT/transparency-test-results.txt" --stderr "$TEST_OUTPUT/transparency-test-errors.txt" --args "$TEST_OUTPUT"
cat "$TEST_OUTPUT/transparency-test-results.txt"
if ! /usr/bin/grep -q '^PASS:' "$TEST_OUTPUT/transparency-test-results.txt"; then
  cat "$TEST_OUTPUT/transparency-test-errors.txt" >&2
  exit 1
fi
