#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/tools/work-paths.sh"
TEST_BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lumaview-canvas-tests.XXXXXX")"
trap 'rm -rf "$TEST_BUILD_DIR"' EXIT
ARCH="$(uname -m)"
TEST_APP="$TEST_BUILD_DIR/CanvasTests.app"
mkdir -p "$TEST_APP/Contents/MacOS" "$TEST_APP/Contents/Resources/Localizations"
cp "$PROJECT_ROOT/Resources/Localizations/catalog.json" "$TEST_APP/Contents/Resources/Localizations/catalog.json"
cat > "$TEST_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>dev.lumaview.canvas-tests</string>
<key>CFBundleName</key><string>LumaView Canvas Tests</string>
<key>CFBundleExecutable</key><string>CanvasTests</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
xcrun swiftc -swift-version 5 -target "${ARCH}-apple-macosx13.0" \
  -module-cache-path "$TEST_BUILD_DIR/module-cache" \
  -framework AppKit -framework AVFoundation \
  "$PROJECT_ROOT/Sources/Localization.swift" \
  "$PROJECT_ROOT/Sources/ThumbnailRequest.swift" "$PROJECT_ROOT/Sources/PostScriptDocument.swift" "$PROJECT_ROOT/Sources/VectorRenderer.swift" "$PROJECT_ROOT/Sources/DocumentMedia.swift" "$PROJECT_ROOT/Sources/PhotoCanvas.swift" "$PROJECT_ROOT/Tests/CanvasTests.swift" \
  -o "$TEST_APP/Contents/MacOS/CanvasTests"
# A normal app launch is needed for real WindowServer presentation/completion checks.
open -n -W "$TEST_APP" --stdout "$TEST_BUILD_DIR/result.log" --stderr "$TEST_BUILD_DIR/error.log"
cat "$TEST_BUILD_DIR/result.log"
if ! /usr/bin/grep -q '^PASS:' "$TEST_BUILD_DIR/result.log"; then
  cat "$TEST_BUILD_DIR/error.log" >&2
  exit 1
fi
